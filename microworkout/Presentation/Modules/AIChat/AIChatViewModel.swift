import Foundation
import SwiftUI

struct AIChatMessage: Identifiable, Equatable {
    enum Role: String {
        case user
        case assistant
        case system
    }

    let id: UUID
    let role: Role
    /// Mutable porque la respuesta del modelo se va rellenando por streaming.
    var text: String
    let timestamp: Date

    init(id: UUID = UUID(), role: Role, text: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.timestamp = timestamp
    }

    /// Los mensajes de sistema son avisos de la app, no parte de la conversación
    /// con el modelo, así que no viajan al backend.
    var asTurn: AIChatTurn? {
        switch role {
        case .user: return AIChatTurn(role: .user, content: text)
        case .assistant: return AIChatTurn(role: .assistant, content: text)
        case .system: return nil
        }
    }
}

struct AIChatUiState {
    var messages: [AIChatMessage] = []
    var input: String = ""
    var isPreparing: Bool = false
    /// Hay una respuesta llegando ahora mismo.
    var isStreaming: Bool = false
    var contextJSON: String = ""
    var contextSummary: String = ""
    var isContextSheetVisible: Bool = false
    var isContextReady: Bool = false
    var error: String?
    /// Respuestas ya valoradas: sus pulgares se apagan para no contar doble.
    var ratedMessageIds: Set<UUID> = []

    var canSend: Bool {
        !isStreaming && !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

/// No se marca `@MainActor` a propósito: los builders construyen los ViewModels
/// desde contextos sincronos no aislados, igual que el resto de la app. Los saltos
/// al main actor se hacen explícitos en cada mutación de `uiState`.
///
/// Como la clase no está aislada, el estado mutable que se toca desde MÁS DE UN
/// dominio se aísla pieza a pieza (ver `contextTask`). Lo que se añada aquí y se
/// lea tanto desde la vista como desde el stream necesita el mismo tratamiento.
final class AIChatViewModel: ObservableObject {
    @Published var uiState: AIChatUiState = .init()

    private let contextUseCase: AIContextUseCaseProtocol
    private let chatUseCase: AICoachChatUseCaseProtocol
    /// `nil` en previews y tests: los pulgares simplemente no reportan.
    private let feedbackUseCase: CoachFeedbackUseCaseProtocol?
    private let topic: AICoachTopic
    private var streamTask: Task<Void, Never>?

    /// La construcción del contexto en curso (o la ya terminada), aislada al main
    /// actor.
    ///
    /// Antes era un `AIContext?` sin aislar, leído y escrito desde dos sitios que
    /// viven en dominios distintos: `prepareContext()` (main) y `consume()` (fuera
    /// del main). Abrir la hoja de datos y mandar un mensaje a la vez construía el
    /// contexto DOS veces —que es leer HealthKit y todo el histórico dos veces— y
    /// las dos escrituras se pisaban.
    ///
    /// Guardar la `Task` en vez del valor resuelve las dos cosas: quien llegue
    /// segundo espera la misma construcción en lugar de lanzar otra.
    @MainActor private var contextTask: Task<AIContext, Never>?

    init(
        contextUseCase: AIContextUseCaseProtocol,
        chatUseCase: AICoachChatUseCaseProtocol,
        feedbackUseCase: CoachFeedbackUseCaseProtocol? = nil,
        topic: AICoachTopic = .free,
        initialPrompt: String? = nil
    ) {
        self.contextUseCase = contextUseCase
        self.chatUseCase = chatUseCase
        self.feedbackUseCase = feedbackUseCase
        self.topic = topic
        if let initialPrompt {
            self.uiState.input = initialPrompt
        }
    }

    deinit {
        streamTask?.cancel()
    }

    // MARK: - Valoración

    /// Pulgar sobre una respuesta del coach. El envío va en segundo plano y sin
    /// error hacia la UI: el feedback nunca puede romper el chat.
    func rate(message: AIChatMessage, helpful: Bool, reason: String?) {
        guard message.role == .assistant, !message.text.isEmpty else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.uiState.ratedMessageIds.insert(message.id)
            await self.feedbackUseCase?.chatRated(
                topic: self.topic, answer: message.text, helpful: helpful, reason: reason
            )
        }
    }

    // MARK: - Contexto

    func prepareContext() {
        guard !uiState.isPreparing, !uiState.isContextReady else { return }
        uiState.isPreparing = true
        Task { @MainActor in
            let context = await self.resolveContext()
            self.uiState.contextJSON = self.contextUseCase.toJSON(context, pretty: true)
            self.uiState.contextSummary = Self.summarize(context)
            self.uiState.isContextReady = true
            self.uiState.isPreparing = false
        }
    }

    func openContextSheet() {
        prepareContext()
        uiState.isContextSheetVisible = true
    }

    func closeContextSheet() {
        uiState.isContextSheetVisible = false
    }

    // MARK: - Conversación

    func send() {
        let question = uiState.input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !uiState.isStreaming else { return }

        uiState.error = nil
        uiState.input = ""
        // El historial que ve el modelo es el de *antes* de este turno: la pregunta
        // actual va aparte, así que hay que capturarlo antes de añadir el mensaje.
        let conversation = uiState.messages.compactMap(\.asTurn)
        uiState.messages.append(AIChatMessage(role: .user, text: question))

        let placeholder = AIChatMessage(role: .assistant, text: "")
        uiState.messages.append(placeholder)
        uiState.isStreaming = true

        streamTask = Task { [weak self] in
            await self?.consume(question: question, conversation: conversation, into: placeholder.id)
        }
    }

    /// Corta la respuesta en curso. Lo ya recibido se queda en pantalla.
    func stopStreaming() {
        streamTask?.cancel()
        streamTask = nil
        uiState.isStreaming = false
        dropPlaceholderIfEmpty()
    }

    func retryLast() {
        guard !uiState.isStreaming else { return }
        uiState.error = nil

        // Se descarta la respuesta fallida completa (aunque llegara a medias: al
        // reintentar se pide de nuevo entera) y se recupera la pregunta.
        if uiState.messages.last?.role == .assistant {
            uiState.messages.removeLast()
        }
        guard let question = uiState.messages.last, question.role == .user else { return }
        uiState.messages.removeLast()
        uiState.input = question.text
        send()
    }

    private func consume(question: String, conversation: [AIChatTurn], into messageId: UUID) async {
        let context = await resolveContext()

        do {
            for try await chunk in chatUseCase.stream(
                context: context,
                question: question,
                topic: topic,
                conversation: conversation
            ) {
                guard !Task.isCancelled else { break }
                await MainActor.run { self.append(chunk, to: messageId) }
            }
            await MainActor.run {
                self.uiState.isStreaming = false
                self.dropPlaceholderIfEmpty()
            }
        } catch {
            await MainActor.run {
                self.uiState.isStreaming = false
                self.uiState.error = Self.message(for: error)
                self.dropPlaceholderIfEmpty()
            }
        }
    }

    /// El contexto se construye una vez por pantalla y se reutiliza en los turnos
    /// siguientes: leer HealthKit y todo el histórico en cada mensaje sería caro y
    /// entre turno y turno no cambia.
    ///
    /// `@MainActor` para que la comprobación "¿ya se está construyendo?" y el guardar
    /// la tarea sean un solo paso indivisible. El trabajo pesado no se queda en el
    /// main actor: `buildContext` es `async` y no está aislado, así que salta fuera.
    @MainActor
    private func resolveContext() async -> AIContext {
        if let contextTask { return await contextTask.value }
        let task = Task { await self.contextUseCase.buildContext(mealDaysBack: 30, healthWeeksBack: 4) }
        contextTask = task
        return await task.value
    }

    private func append(_ chunk: String, to messageId: UUID) {
        guard let index = uiState.messages.firstIndex(where: { $0.id == messageId }) else { return }
        uiState.messages[index].text += chunk
    }

    /// Si el modelo no llegó a decir nada (error o cancelación inmediata), la
    /// burbuja vacía sobra.
    private func dropPlaceholderIfEmpty() {
        if let last = uiState.messages.last, last.role == .assistant, last.text.isEmpty {
            uiState.messages.removeLast()
        }
    }

    private static func message(for error: Error) -> String {
        if case DomainError.notAuthorized = error {
            return "Inicia sesión para usar el coach IA: el modelo se ejecuta en el servidor."
        }
        return (error as? LocalizedError)?.errorDescription
            ?? "No se pudo contactar con el coach. Inténtalo de nuevo."
    }

    // MARK: - Resumen del contexto (hoja de datos)

    private static func summarize(_ context: AIContext) -> String {
        var lines: [String] = []
        if let profile = context.profile {
            lines.append(
                "• Perfil: \(profile.name), \(profile.age) años, \(Int(profile.weightKg)) kg, "
                + "objetivo \(profile.fitnessGoal ?? "—"), \(Int(profile.dailyCalorieTarget)) kcal/día"
            )
        }
        lines.append("• Plantillas de sesión: \(context.workoutSessions.count)")
        lines.append("• Logs de entrenamiento: \(context.workoutLogs.count)")
        lines.append("• Entries manuales: \(context.manualEntries.count)")
        lines.append("• Comidas: \(context.meals.count)")
        lines.append("• Días con datos de salud: \(context.healthDays.count)")
        lines.append("• Workouts del Apple Watch: \(context.healthWorkouts.count)")
        return lines.joined(separator: "\n")
    }
}

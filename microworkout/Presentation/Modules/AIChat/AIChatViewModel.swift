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
    let text: String
    let timestamp: Date

    init(id: UUID = UUID(), role: Role, text: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.timestamp = timestamp
    }
}

struct AIChatUiState {
    var messages: [AIChatMessage] = []
    var input: String = ""
    var isPreparing: Bool = false
    var contextJSON: String = ""
    var contextSummary: String = ""
    var isContextSheetVisible: Bool = false
    var isContextReady: Bool = false
}

final class AIChatViewModel: ObservableObject {
    @Published var uiState: AIChatUiState = .init()

    private let useCase: AIContextUseCaseProtocol
    private var cachedContext: AIContext?
    private let initialPrompt: String?

    init(useCase: AIContextUseCaseProtocol, initialPrompt: String? = nil) {
        self.useCase = useCase
        self.initialPrompt = initialPrompt
        self.uiState.messages = [
            AIChatMessage(
                role: .assistant,
                text: "Hola. Aún no estoy conectado a ningún modelo, pero ya recopilo todos tus datos. Pulsa la lupa para revisarlos antes de conectar la IA."
            )
        ]
        if let prompt = initialPrompt {
            self.uiState.input = prompt
        }
    }

    func prepareContext() {
        guard !uiState.isPreparing else { return }
        uiState.isPreparing = true
        Task { @MainActor in
            let context = await useCase.buildContext(mealDaysBack: 30, healthWeeksBack: 4)
            self.cachedContext = context
            self.uiState.contextJSON = useCase.toJSON(context, pretty: true)
            self.uiState.contextSummary = summarize(context)
            self.uiState.isContextReady = true
            self.uiState.isPreparing = false
        }
    }

    func openContextSheet() {
        if !uiState.isContextReady { prepareContext() }
        uiState.isContextSheetVisible = true
    }

    func closeContextSheet() {
        uiState.isContextSheetVisible = false
    }

    func send() {
        let trimmed = uiState.input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let userMessage = AIChatMessage(role: .user, text: trimmed)
        uiState.messages.append(userMessage)
        uiState.input = ""

        // Mock response: la conexión real al modelo se añadirá más tarde.
        // Por ahora confirmamos que el contexto está preparado y damos pistas.
        Task { @MainActor in
            if !uiState.isContextReady { prepareContext() }
            try? await Task.sleep(nanoseconds: 350_000_000)
            let summary = uiState.contextSummary.isEmpty
                ? "(contexto cargándose…)"
                : uiState.contextSummary
            let mock = AIChatMessage(
                role: .assistant,
                text:
                    "Recibido. Aún no estoy conectado a ningún modelo de IA, " +
                    "así que esto es una respuesta simulada. Cuando conectemos " +
                    "una API, le pasaré el siguiente contexto:\n\n\(summary)"
            )
            uiState.messages.append(mock)
        }
    }

    private func summarize(_ ctx: AIContext) -> String {
        let p = ctx.profile
        var lines: [String] = []
        if let p = p {
            lines.append("• Perfil: \(p.name), \(p.age) años, \(Int(p.weightKg)) kg, objetivo \(p.fitnessGoal ?? "—"), \(Int(p.dailyCalorieTarget)) kcal/día")
        }
        lines.append("• Plantillas de sesión: \(ctx.workoutSessions.count)")
        lines.append("• Logs de entrenamiento: \(ctx.workoutLogs.count)")
        lines.append("• Entries manuales: \(ctx.manualEntries.count)")
        lines.append("• Comidas: \(ctx.meals.count)")
        lines.append("• Días con datos de salud: \(ctx.healthDays.count)")
        lines.append("• Workouts del Apple Watch: \(ctx.healthWorkouts.count)")
        return lines.joined(separator: "\n")
    }
}

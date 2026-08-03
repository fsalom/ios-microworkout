import Foundation

/// Consejo del coach para las tarjetas de las pestañas.
///
/// Tres capas, en este orden:
/// 1. **Caché local.** Cada tarjeta se pide al aparecer la pestaña, así que sin
///    caché una sesión normal de la app dispararía docenas de llamadas al modelo.
/// 2. **Modelo** (`/v1/ai/insight`) cuando la caché no vale.
/// 3. **Heurísticas locales** si no hay cuenta o la llamada falla — la tarjeta
///    nunca se queda en blanco por un problema de red.
///
/// La caché se invalida por dos vías: por TTL y por huella de los datos. Solo con
/// TTL, registrar una serie o una comida dejaría la tarjeta contando algo viejo;
/// solo con huella, el consejo no se renovaría nunca en un día sin actividad.
final class CoachUseCase: CoachUseCaseProtocol {
    private let contextUseCase: AIContextUseCaseProtocol
    private let repository: AICoachRepositoryProtocol
    private let storage: UserDefaultsManagerProtocol
    private let heuristics = HeuristicCoach()
    private let ttl: TimeInterval

    init(
        contextUseCase: AIContextUseCaseProtocol,
        repository: AICoachRepositoryProtocol,
        storage: UserDefaultsManagerProtocol,
        ttl: TimeInterval = 6 * 60 * 60
    ) {
        self.contextUseCase = contextUseCase
        self.repository = repository
        self.storage = storage
        self.ttl = ttl
    }

    // MARK: - API

    func insight(for topic: AICoachTopic) async -> CoachInsight {
        await resolve(topic: topic, ignoringCache: false)
    }

    func refreshInsight(for topic: AICoachTopic) async -> CoachInsight {
        await resolve(topic: topic, ignoringCache: true)
    }

    private func resolve(topic: AICoachTopic, ignoringCache: Bool) async -> CoachInsight {
        let depth = ContextDepth.for(topic)
        let context = await contextUseCase.buildContext(
            mealDaysBack: depth.mealDaysBack,
            healthWeeksBack: depth.healthWeeksBack
        )
        let fingerprint = Self.fingerprint(of: context)
        let key = await cacheKey(for: topic)

        if !ignoringCache,
           let cached: CachedInsight = storage.get(forKey: key),
           cached.fingerprint == fingerprint,
           Date().timeIntervalSince(cached.createdAt) < ttl {
            return cached.toDomain(topic: topic)
        }

        do {
            let insight = try await repository.insight(context: context, topic: topic)
            storage.save(
                CachedInsight(insight: insight, fingerprint: fingerprint),
                forKey: key
            )
            return insight
        } catch {
            // Invitado o fallo de red: no es un error que merezca UI propia, la
            // tarjeta simplemente muestra el consejo local.
            return heuristics.insight(for: topic, context: context)
        }
    }

    // MARK: - Profundidad de contexto por tema

    private struct ContextDepth {
        let mealDaysBack: Int
        let healthWeeksBack: Int

        /// Cada tema mira datos distintos; construir el contexto completo para
        /// una tarjeta de progresión es leer un mes de comidas para nada.
        static func `for`(_ topic: AICoachTopic) -> ContextDepth {
            switch topic {
            case .workout, .plan: return ContextDepth(mealDaysBack: 1, healthWeeksBack: 1)
            case .nutrition: return ContextDepth(mealDaysBack: 14, healthWeeksBack: 1)
            case .daily: return ContextDepth(mealDaysBack: 7, healthWeeksBack: 1)
            case .free: return ContextDepth(mealDaysBack: 30, healthWeeksBack: 4)
            }
        }
    }

    // MARK: - Caché

    private func cacheKey(for topic: AICoachTopic) async -> String {
        // Se mete el usuario en la clave para que al cambiar de cuenta no se vea
        // el consejo de la anterior.
        let user = await MainActor.run { AuthSession.shared.state.user?.id }
        let scope = user.map(String.init) ?? "guest"
        return "ai.coach.insight.\(scope).\(topic.rawValue)"
    }

    /// Resumen barato de "qué datos hay". Cambia en cuanto el usuario registra
    /// algo relevante, que es exactamente cuando el consejo se queda viejo.
    private static func fingerprint(of context: AIContext) -> String {
        let calendar = Calendar.current
        let lastLog = context.workoutLogs.map(\.startedAt).max() ?? .distantPast
        let todayKcal = context.meals
            .filter { calendar.isDateInToday($0.timestamp) }
            .reduce(0.0) { $0 + $1.totalNutrition.calories }
        let todaySteps = context.healthDays.first { calendar.isDateInToday($0.date) }?.steps ?? 0

        // Se construye a trozos y no como un literal de array: con 10 expresiones
        // mezclando Int/Double/Date el type-checker se atraganta.
        var parts: [String] = []
        parts.append(String(Int(calendar.startOfDay(for: Date()).timeIntervalSince1970)))
        parts.append(String(context.workoutLogs.count))
        parts.append(String(context.workoutSessions.count))
        parts.append(String(context.manualEntries.count))
        parts.append(String(context.meals.count))
        parts.append(String(Int(lastLog.timeIntervalSince1970)))
        parts.append(String(Int(todayKcal.rounded())))
        parts.append(String(todaySteps))

        let weight: Double = context.profile?.weightKg ?? 0
        let target: Double = context.profile?.todayCalorieTarget ?? 0
        parts.append(String(Int(weight * 10)))
        parts.append(String(Int(target)))

        return parts.joined(separator: "|")
    }

    private struct CachedInsight: Codable {
        let title: String
        let body: String
        let bullets: [String]
        let prompt: String
        let fingerprint: String
        let createdAt: Date

        init(insight: CoachInsight, fingerprint: String, createdAt: Date = Date()) {
            self.title = insight.title
            self.body = insight.body
            self.bullets = insight.bullets
            self.prompt = insight.prompt
            self.fingerprint = fingerprint
            self.createdAt = createdAt
        }

        func toDomain(topic: AICoachTopic) -> CoachInsight {
            CoachInsight(
                topic: topic,
                title: title,
                body: body,
                bullets: bullets,
                prompt: prompt,
                isFromModel: true
            )
        }
    }
}

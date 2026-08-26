protocol CoachUseCaseProtocol {
    /// Consejo para un área. Sirve de la caché si sigue siendo válida; si no,
    /// pregunta al modelo; y si eso falla (invitado, sin red), cae a heurísticas.
    func insight(for topic: AICoachTopic) async -> CoachInsight
    /// Ignora la caché y vuelve a preguntar al modelo.
    func refreshInsight(for topic: AICoachTopic) async -> CoachInsight
    /// Pulgar arriba/abajo del usuario sobre una tarjeta. No lanza ni bloquea:
    /// el feedback nunca puede romper la UX.
    func rate(_ insight: CoachInsight, helpful: Bool, reason: String?) async

    func workoutInsight() async -> CoachInsight
    func planInsight() async -> CoachInsight
    func nutritionInsight() async -> CoachInsight
    func homeInsight() async -> CoachInsight
}

extension CoachUseCaseProtocol {
    func workoutInsight() async -> CoachInsight { await insight(for: .workout) }
    func planInsight() async -> CoachInsight { await insight(for: .plan) }
    func nutritionInsight() async -> CoachInsight { await insight(for: .nutrition) }
    func homeInsight() async -> CoachInsight { await insight(for: .daily) }
}

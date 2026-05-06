protocol CoachUseCaseProtocol {
    func workoutInsight() async -> CoachInsight
    func nutritionInsight() async -> CoachInsight
    func homeInsight() async -> CoachInsight
}

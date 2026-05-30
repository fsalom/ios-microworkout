import Foundation

protocol UserProfileUseCaseProtocol {
    func saveProfile(_ profile: UserProfile) async throws
    func getProfile() async throws -> UserProfile?
    func setOnboardingCompleted(_ completed: Bool)
    func hasCompletedOnboarding() -> Bool
}

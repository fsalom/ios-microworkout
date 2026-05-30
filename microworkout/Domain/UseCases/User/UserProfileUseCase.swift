import Foundation

class UserProfileUseCase: UserProfileUseCaseProtocol {
    private let repository: UserProfileRepositoryProtocol

    init(repository: UserProfileRepositoryProtocol) {
        self.repository = repository
    }

    func saveProfile(_ profile: UserProfile) async throws {
        try await repository.saveProfile(profile)
    }

    func getProfile() async throws -> UserProfile? {
        try await repository.getProfile()
    }

    func setOnboardingCompleted(_ completed: Bool) {
        repository.setOnboardingCompleted(completed)
    }

    func hasCompletedOnboarding() -> Bool {
        repository.isOnboardingCompleted()
    }
}

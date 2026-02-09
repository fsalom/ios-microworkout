//
//  UserLocalDataSource.swift
//  microworkout
//

import Foundation

/// Persistencia del perfil de usuario usando UserDefaults.
class UserLocalDataSource {
    private let storage: UserDefaultsManagerProtocol

    private enum Keys: String {
        case userProfile = "user_profile"
        case onboardingCompleted = "onboarding_completed"
    }

    init(storage: UserDefaultsManagerProtocol = UserDefaultsManager()) {
        self.storage = storage
    }

    func save(profile: UserProfile) {
        storage.save(profile, forKey: Keys.userProfile.rawValue)
    }

    func getProfile() -> UserProfile? {
        storage.get(forKey: Keys.userProfile.rawValue)
    }

    func setOnboardingCompleted(_ completed: Bool) {
        storage.save(completed, forKey: Keys.onboardingCompleted.rawValue)
    }

    func isOnboardingCompleted() -> Bool {
        let completed: Bool? = storage.get(forKey: Keys.onboardingCompleted.rawValue)
        return completed ?? false
    }
}

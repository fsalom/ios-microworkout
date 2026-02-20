import Foundation

protocol WorkoutLinkDataSourceProtocol {
    func getAll() -> [String: UUID]
    func saveLink(workoutID: String, trainingID: UUID)
    func removeLink(workoutID: String)
}

class WorkoutLinkLocalDataSource: WorkoutLinkDataSourceProtocol {
    private let userDefaults: UserDefaultsManagerProtocol
    private let key = "workoutLinks"

    init(userDefaults: UserDefaultsManagerProtocol = UserDefaultsManager()) {
        self.userDefaults = userDefaults
    }

    func getAll() -> [String: UUID] {
        userDefaults.get(forKey: key) ?? [:]
    }

    func saveLink(workoutID: String, trainingID: UUID) {
        var links = getAll()
        links[workoutID] = trainingID
        userDefaults.save(links, forKey: key)
    }

    func removeLink(workoutID: String) {
        var links = getAll()
        links.removeValue(forKey: workoutID)
        userDefaults.save(links, forKey: key)
    }
}

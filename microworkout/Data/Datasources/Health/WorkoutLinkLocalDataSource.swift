import Foundation

protocol WorkoutLinkDataSourceProtocol {
    // Training links (workoutID -> Training UUID)
    func getAll() -> [String: UUID]
    func saveLink(workoutID: String, trainingID: UUID)
    func removeLink(workoutID: String)

    // Entry links (workoutID -> WorkoutEntryByDay date string)
    func getAllEntryLinks() -> [String: String]
    func saveEntryLink(workoutID: String, entryDate: String)
    func removeEntryLink(workoutID: String)
}

class WorkoutLinkLocalDataSource: WorkoutLinkDataSourceProtocol {
    private let userDefaults: UserDefaultsManagerProtocol
    private let trainingKey = "workoutLinks"
    private let entryKey = "workoutEntryLinks"

    init(userDefaults: UserDefaultsManagerProtocol) {
        self.userDefaults = userDefaults
    }

    // MARK: Training links

    func getAll() -> [String: UUID] {
        userDefaults.get(forKey: trainingKey) ?? [:]
    }

    func saveLink(workoutID: String, trainingID: UUID) {
        var links = getAll()
        links[workoutID] = trainingID
        userDefaults.save(links, forKey: trainingKey)
    }

    func removeLink(workoutID: String) {
        var links = getAll()
        links.removeValue(forKey: workoutID)
        userDefaults.save(links, forKey: trainingKey)
    }

    // MARK: Entry links

    func getAllEntryLinks() -> [String: String] {
        userDefaults.get(forKey: entryKey) ?? [:]
    }

    func saveEntryLink(workoutID: String, entryDate: String) {
        var links = getAllEntryLinks()
        links[workoutID] = entryDate
        userDefaults.save(links, forKey: entryKey)
    }

    func removeEntryLink(workoutID: String) {
        var links = getAllEntryLinks()
        links.removeValue(forKey: workoutID)
        userDefaults.save(links, forKey: entryKey)
    }
}

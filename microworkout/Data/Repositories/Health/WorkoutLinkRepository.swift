import Foundation

class WorkoutLinkRepository: WorkoutLinkRepositoryProtocol {
    private let dataSource: WorkoutLinkDataSourceProtocol

    init(dataSource: WorkoutLinkDataSourceProtocol) {
        self.dataSource = dataSource
    }

    func getAllTrainingLinks() -> [String: UUID] {
        dataSource.getAll()
    }

    func saveTrainingLink(workoutID: String, trainingID: UUID) {
        dataSource.saveLink(workoutID: workoutID, trainingID: trainingID)
    }

    func removeTrainingLink(workoutID: String) {
        dataSource.removeLink(workoutID: workoutID)
    }

    func getAllEntryLinks() -> [String: String] {
        dataSource.getAllEntryLinks()
    }

    func saveEntryLink(workoutID: String, entryDate: String) {
        dataSource.saveEntryLink(workoutID: workoutID, entryDate: entryDate)
    }

    func removeEntryLink(workoutID: String) {
        dataSource.removeEntryLink(workoutID: workoutID)
    }
}

import Foundation

protocol WorkoutLinkRepositoryProtocol {
    func getAllTrainingLinks() -> [String: UUID]
    func saveTrainingLink(workoutID: String, trainingID: UUID)
    func removeTrainingLink(workoutID: String)

    func getAllEntryLinks() -> [String: String]
    func saveEntryLink(workoutID: String, entryDate: String)
    func removeEntryLink(workoutID: String)
}

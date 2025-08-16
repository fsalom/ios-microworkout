import Foundation

/// DTO para persistir un WorkoutEntry.
struct WorkoutEntryDTO: Codable, Equatable {
    let id: UUID
    let exerciseID: UUID
    let date: Date
    let reps: Int?
    let weight: Double?
    let distanceMeters: Double?
    let calories: Double?
    let isCompleted: Bool
}
import Foundation

/// Shape returned by the Python backend at `/v1/trainings`.
struct TrainingApiDTO: Codable {
    let id: UUID
    let name: String
    let image: String
    let type: String
    let numberOfSets: Int
    let numberOfReps: Int
    let numberOfMinutesPerSet: Int
    let startedAt: Date?
    let completedAt: Date?
    let sets: [Date]
    let numberOfSetsCompleted: Int
    let numberOfSeconds: Double

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case image
        case type
        case numberOfSets = "number_of_sets"
        case numberOfReps = "number_of_reps"
        case numberOfMinutesPerSet = "number_of_minutes_per_set"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case sets
        case numberOfSetsCompleted = "number_of_sets_completed"
        case numberOfSeconds = "number_of_seconds"
    }
}

extension TrainingApiDTO {
    func toDomain() -> Training {
        Training(
            id: id,
            name: name,
            image: image,
            type: TrainingType(rawValue: type) ?? .strength,
            startedAt: startedAt,
            completedAt: completedAt,
            sets: sets,
            numberOfSetsForSlider: Double(numberOfSets),
            numberOfRepsForSlider: Double(numberOfReps),
            numberOfMinutesPerSetForSlider: Double(numberOfMinutesPerSet)
        )
    }
}

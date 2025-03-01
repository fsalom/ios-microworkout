import Foundation

enum TrainingType: String, Codable {
    case cardio
    case strength
}

struct Training: Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var image: String
    var type: TrainingType
    var startedAt: Date?
    var completedAt: Date?
    var sets: [Date] = []
    var numberOfSetsCompleted: Int = 0 {
        didSet {
            sets.append(Date())
        }
    }

    var numberOfSets: Int
    var numberOfReps: Int
    var numberOfMinutesPerSet: Int

    static func mock() -> Training {
        return Training(
            name: "Mock Training",
            image: "mock",
            type: .cardio,
            numberOfSets: 1,
            numberOfReps: 1,
            numberOfMinutesPerSet: 1
        )
    }
}

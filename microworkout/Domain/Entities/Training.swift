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

    var numberOfSets: Int {
        return Int(numberOfSetsForSlider)
    }
    var numberOfReps: Int {
        return Int(numberOfRepsForSlider)
    }
    var numberOfMinutesPerSet: Int {
        return Int(numberOfMinutesPerSetForSlider)
    }

    var numberOfSetsForSlider: Double
    var numberOfRepsForSlider: Double
    var numberOfMinutesPerSetForSlider: Double

    static func mock() -> Training {
        return Training(
            name: "Mock Training",
            image: "mock",
            type: .cardio,
            numberOfSetsForSlider: 1.0,
            numberOfRepsForSlider: 1.0,
            numberOfMinutesPerSetForSlider: 1.0
        )
    }
}

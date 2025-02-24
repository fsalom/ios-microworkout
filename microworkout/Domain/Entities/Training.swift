import Foundation

enum TrainingType {
    case cardio
    case strength
}

struct Training: Identifiable {
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
    var numberOfSetsForSlider: Double {
        get { Double(numberOfSets) }
        set { numberOfSets = Int(newValue) }
    }
    var numberOfReps: Int
    var numberOfRepsForSlider: Double {
        get { Double(numberOfReps) }
        set { numberOfReps = Int(newValue) }
    }
    var numberOfMinutesPerSet: Int
    var numberOfMinutesPerSetForSlider: Double {
        get { Double(numberOfMinutesPerSet) }
        set { numberOfMinutesPerSet = Int(newValue) }
    }

    func mock() -> Training {
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

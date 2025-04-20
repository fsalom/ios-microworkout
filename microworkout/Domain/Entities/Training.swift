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
    var numberOfSeconds: Double = 0.0
    var numberOfMinutes: Int {
        return Int(numberOfSeconds/60)
    }

    mutating func calculateNumberOfSeconds() {
        var dates = self.sets
        if let startDate = self.startedAt, dates.count < 1 {
            dates.append(startDate)
            dates.append(Date())
        }

        let sortedDates = dates.sorted()

        for i in 1..<sortedDates.count {
            let previous = sortedDates[i - 1]
            let current = sortedDates[i]
            let interval = current.timeIntervalSince(previous)
            self.numberOfSeconds += interval
        }
    }

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

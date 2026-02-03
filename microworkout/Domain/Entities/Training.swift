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
            calculateNumberOfSeconds()
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
    var timeSpent: String {
        return String(format: "%02d:%02d", numberOfMinutes, Int(numberOfSeconds)%60)
    }

    mutating func calculateNumberOfSeconds() {
        var dates = self.sets
        if let startDate = self.startedAt, dates.isEmpty {
            dates.append(startDate)
            dates.append(Date())
        }

        let sortedDates = dates.sorted()

        var totalSeconds: Double = 0.0
        for i in 1..<sortedDates.count {
            let previous = sortedDates[i - 1]
            let current = sortedDates[i]
            totalSeconds += current.timeIntervalSince(previous)
        }

        self.numberOfSeconds = totalSeconds
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

// MARK: - Mapping to Exercise & WorkoutEntry
extension Training {
    /// Crea un Exercise a partir de este Training.
    func toExercise() -> Exercise {
        Exercise(id: self.id, name: self.name, type: .none)
    }


    /// espaciadas por `numberOfMinutesPerSetForSlider` minutos, empezando en `start`.
    func toWorkoutEntries(startingAt start: Date = Date()) -> [WorkoutEntry] {
        let exercise = toExercise()
        return (0..<Int(numberOfSetsForSlider)).map { index in
            let entryDate = Calendar(identifier: .gregorian)
                .date(byAdding: .minute,
                        value: Int(numberOfMinutesPerSetForSlider) * index,
                        to: start) ?? start
            return WorkoutEntry(
                exercise: exercise,
                date: entryDate,
                reps: Int(numberOfRepsForSlider),
                weight: nil,
                distanceMeters: nil,
                calories: nil,
                isCompleted: false
            )
        }
    }
}

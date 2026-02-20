import Foundation

enum WorkoutItem: Identifiable {
    case manual(WorkoutEntryByDay)
    case appleWatch(HealthWorkout)

    var id: String {
        switch self {
        case .manual(let entry): return "manual-\(entry.id)"
        case .appleWatch(let workout): return "aw-\(workout.id)"
        }
    }

    var sortDate: Date {
        switch self {
        case .manual(let entry): return entry.parsedDate ?? Date.distantPast
        case .appleWatch(let workout): return workout.startDate
        }
    }
}

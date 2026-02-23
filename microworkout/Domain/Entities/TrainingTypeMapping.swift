import HealthKit

extension TrainingType {
    var hkActivityType: HKWorkoutActivityType {
        switch self {
        case .strength:
            return .traditionalStrengthTraining
        case .cardio:
            return .running
        }
    }
}

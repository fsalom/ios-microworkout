import Foundation

struct LiveWorkoutData: Codable {
    var heartRate: Double
    var activeCalories: Double
    var distance: Double
    var elapsedSeconds: Double
    var timestamp: Date

    static var empty: LiveWorkoutData {
        LiveWorkoutData(
            heartRate: 0,
            activeCalories: 0,
            distance: 0,
            elapsedSeconds: 0,
            timestamp: Date()
        )
    }
}

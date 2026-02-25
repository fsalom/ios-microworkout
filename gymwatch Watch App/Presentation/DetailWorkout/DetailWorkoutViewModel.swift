import Foundation
import Combine

@MainActor
class DetailWorkoutViewModel: ObservableObject {
    @Published var training: Training
    @Published var heartRate: Double = 0
    @Published var activeCalories: Double = 0
    @Published var distance: Double = 0
    @Published var elapsedSeconds: Double = 0
    @Published var isActive: Bool = false
    @Published var isPaused: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init(training: Training) {
        self.training = training
        let manager = WorkoutSessionManager.shared
        manager.$heartRate.assign(to: &$heartRate)
        manager.$activeCalories.assign(to: &$activeCalories)
        manager.$distance.assign(to: &$distance)
        manager.$elapsedSeconds.assign(to: &$elapsedSeconds)
        manager.$isActive.assign(to: &$isActive)
        manager.$isPaused.assign(to: &$isPaused)
    }

    var formattedTime: String {
        let total = Int(elapsedSeconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    var formattedDistance: String {
        if distance >= 1000 {
            return String(format: "%.2f km", distance / 1000)
        }
        return String(format: "%.0f m", distance)
    }

    func startWorkout() {
        WorkoutSessionManager.shared.startWorkout(training: training)
    }

    func pauseWorkout() {
        WorkoutSessionManager.shared.pause()
    }

    func resumeWorkout() {
        WorkoutSessionManager.shared.resume()
    }

    func stopWorkout() {
        WorkoutSessionManager.shared.stop()
    }
}

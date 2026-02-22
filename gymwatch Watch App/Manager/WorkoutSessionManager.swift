import Foundation
import HealthKit
import Combine

@MainActor
class WorkoutSessionManager: NSObject, ObservableObject {
    static let shared = WorkoutSessionManager()

    @Published var heartRate: Double = 0
    @Published var activeCalories: Double = 0
    @Published var distance: Double = 0
    @Published var elapsedSeconds: Double = 0
    @Published var isActive: Bool = false
    @Published var isPaused: Bool = false

    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private let healthStore = HKHealthStore()
    private var startDate: Date?
    private var timer: Timer?

    private override init() {
        super.init()
    }

    func startWorkout(training: Training) {
        let config = HKWorkoutConfiguration()
        config.activityType = training.type.hkActivityType
        config.locationType = .indoor

        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            print("[WorkoutSession] Error creating session: \(error)")
            return
        }

        guard let session = session, let builder = builder else { return }

        session.delegate = self
        builder.delegate = self
        builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)

        let start = Date()
        startDate = start

        Task {
            do {
                session.startActivity(with: start)
                try await builder.beginCollection(at: start)
                try await session.startMirroringToCompanionDevice()
                isActive = true
                startTimer()
            } catch {
                print("[WorkoutSession] Error starting: \(error)")
            }
        }
    }

    func pause() {
        session?.pause()
    }

    func resume() {
        session?.resume()
    }

    func stop() {
        session?.end()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let start = self.startDate else { return }
                self.elapsedSeconds = Date().timeIntervalSince(start)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func sendLiveDataToPhone() {
        let liveData = LiveWorkoutData(
            heartRate: heartRate,
            activeCalories: activeCalories,
            distance: distance,
            elapsedSeconds: elapsedSeconds,
            timestamp: Date()
        )
        guard let data = try? JSONEncoder().encode(liveData) else { return }
        session?.sendToRemoteWorkoutSession(data: data) { success, error in
            if let error = error {
                print("[WorkoutSession] Error sending data to phone: \(error)")
            }
        }
    }

    private func resetState() {
        heartRate = 0
        activeCalories = 0
        distance = 0
        elapsedSeconds = 0
        isActive = false
        isPaused = false
        startDate = nil
        stopTimer()
        session = nil
        builder = nil
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutSessionManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                     didChangeTo toState: HKWorkoutSessionState,
                                     from fromState: HKWorkoutSessionState,
                                     date: Date) {
        Task { @MainActor in
            switch toState {
            case .running:
                isPaused = false
                isActive = true
            case .paused:
                isPaused = true
            case .ended:
                guard let builder = self.builder else { return }
                do {
                    try await builder.endCollection(at: date)
                    try await builder.finishWorkout()
                } catch {
                    print("[WorkoutSession] Error finishing workout: \(error)")
                }
                resetState()
            default:
                break
            }
        }
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                     didFailWithError error: Error) {
        print("[WorkoutSession] Failed: \(error)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutSessionManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                                     didCollectDataOf collectedTypes: Set<HKSampleType>) {
        Task { @MainActor in
            for type in collectedTypes {
                guard let quantityType = type as? HKQuantityType else { continue }

                if let stats = workoutBuilder.statistics(for: quantityType) {
                    switch quantityType {
                    case HKQuantityType.quantityType(forIdentifier: .heartRate):
                        let unit = HKUnit(from: "count/min")
                        heartRate = stats.mostRecentQuantity()?.doubleValue(for: unit) ?? 0
                    case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                        let unit = HKUnit.kilocalorie()
                        activeCalories = stats.sumQuantity()?.doubleValue(for: unit) ?? 0
                    case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
                        let unit = HKUnit.meter()
                        distance = stats.sumQuantity()?.doubleValue(for: unit) ?? 0
                    default:
                        break
                    }
                }
            }
            sendLiveDataToPhone()
        }
    }
}

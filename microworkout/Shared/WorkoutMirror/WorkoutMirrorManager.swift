import Foundation
import HealthKit
import Combine

@MainActor
class WorkoutMirrorManager: NSObject, ObservableObject {
    static let shared = WorkoutMirrorManager()

    @Published var isMirroringActive: Bool = false
    @Published var liveData: LiveWorkoutData = .empty

    private var mirroredSession: HKWorkoutSession?
    private let healthStore = HKHealthStore()

    private override init() {
        super.init()
        healthStore.workoutSessionMirroringStartHandler = { [weak self] mirroredSession in
            Task { @MainActor in
                self?.handleMirroredSession(mirroredSession)
            }
        }
    }

    private func handleMirroredSession(_ session: HKWorkoutSession) {
        mirroredSession = session
        session.delegate = self
        isMirroringActive = true
    }

    func stopMirroredSession() {
        mirroredSession?.end()
    }

    private func resetState() {
        mirroredSession = nil
        isMirroringActive = false
        liveData = .empty
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutMirrorManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                     didChangeTo toState: HKWorkoutSessionState,
                                     from fromState: HKWorkoutSessionState,
                                     date: Date) {
        Task { @MainActor in
            switch toState {
            case .running:
                isMirroringActive = true
            case .ended:
                resetState()
            default:
                break
            }
        }
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                     didFailWithError error: Error) {
        print("[WorkoutMirror] Session failed: \(error)")
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                     didReceiveDataFromRemoteWorkoutSession data: [Data]) {
        Task { @MainActor in
            for payload in data {
                if let decoded = try? JSONDecoder().decode(LiveWorkoutData.self, from: payload) {
                    liveData = decoded
                }
            }
        }
    }
}

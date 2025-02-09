import Combine
import ActivityKit
import SwiftUI

final class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()

    @MainActor @Published private(set) var activityID: String?

    private init() {}

    // MARK: Public Methods

    func startNewActivity(with startDate: Date) {
        Task {
            await cancelAllRunningActivities()
            await startActivity(with: startDate)
        }
    }

    var timer: Timer?

    func startUpdatingLiveActivity() {
        guard let _ = Activity<rudowidgetAttributes>.activities.first else { return }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateCurrentActivity()
        }
    }

    func stopUpdatingLiveActivity() {
        timer?.invalidate()
        timer = nil
    }

    func updateCurrentActivity() {
        Task {
            guard let activityID = await activityID,
                  let runningActivity = Activity<rudowidgetAttributes>.activities.first(where: { $0.id == activityID }) else {
                return
            }

            let update = rudowidgetAttributes.ContentState()

            let staleDate = Date(timeIntervalSinceNow: 60 * 2)
            await runningActivity.update(ActivityContent(state: update, staleDate: staleDate))
        }
    }

    func endActivity() {
        Task {
            guard let activityID = await activityID,
                  let runningActivity = Activity<rudowidgetAttributes>.activities.first(where: { $0.id == activityID }) else {
                return
            }

            let endContent = rudowidgetAttributes.ContentState()
            await runningActivity.end(
                ActivityContent(state: endContent, staleDate: Date.distantFuture),
                dismissalPolicy: .immediate
            )

            await MainActor.run { self.activityID = nil }
        }
    }

    // MARK: Private Methods

    func cancelAllRunningActivities() async {
        for activity in Activity<rudowidgetAttributes>.activities {
            let endState = rudowidgetAttributes.ContentState()
            await activity.end(
                ActivityContent(state: endState, staleDate: Date()),
                dismissalPolicy: .immediate
            )
        }

        await MainActor.run {
            activityID = nil
        }
    }

    private func startActivity(with startDate: Date) async {
        let content = rudowidgetAttributes.ContentState()
        let staleDate = Date(timeIntervalSinceNow: 1)

        do {
            let activity = try Activity.request(
                attributes: rudowidgetAttributes(startDate: startDate),
                content: ActivityContent(
                    state: content,
                    staleDate: staleDate,
                    relevanceScore: 100
                )
            )
            await MainActor.run { activityID = activity.id }
        } catch {
            print("Failed to start activity: \(error.localizedDescription)")
        }
    }
}

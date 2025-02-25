import SwiftUI
import Combine

struct CountdownView: View {
    @State private var remainingTime: Int = 0
    @Binding var hasToResetTimer: Bool
    let startDate: Date
    let totalMinutes: Int

    private var endDate: Date {
        startDate.addingTimeInterval(TimeInterval(totalMinutes * 60))
    }

    @State private var timerSubscription: Cancellable?

    init(startDate: Date, totalMinutes: Int, hasToResetTimer: Binding<Bool>) {
        self.startDate = startDate
        self.totalMinutes = totalMinutes
        self._hasToResetTimer = hasToResetTimer
    }

    var body: some View {
        VStack {
            Text(timeFormatted(remainingTime))
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .background(Circle().fill(Color.white).frame(width: 200, height: 200))
        }
        .background(
            Circle().fill(Color.white.opacity(0.3)).frame(width: 220, height: 220)
        )
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: hasToResetTimer) { _, newValue in
            if newValue {
                resetTimer()
                hasToResetTimer = false
            }
        }
    }

    private func startTimer() {
        updateRemainingTime()
        if timerSubscription == nil {
            timerSubscription = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    updateRemainingTime()
                }
        }
    }

    private func stopTimer() {
        timerSubscription?.cancel()
        timerSubscription = nil
    }

    private func resetTimer() {
        stopTimer()
        startTimer()
    }

    private func updateRemainingTime() {
        let now = Date()
        let timeLeft = Int(endDate.timeIntervalSince(now))
        remainingTime = max(timeLeft, 0)

        if remainingTime == 0 {
            stopTimer()
        }
    }

    private func timeFormatted(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

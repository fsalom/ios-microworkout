import SwiftUI
import Combine

struct CountdownButtonView: View {
    @Binding var hasToResetTimer: Bool
    @Binding var sets: [Date]

    let startDate: Date
    let totalMinutes: Int
    let limitOfSets: Int
    
    let action: () -> Void
    let end: () -> Void

    @State private var remainingTime: Int = 0
    @State private var timerSubscription: Cancellable?
    @State private var isPressed: Bool = false

    private var endDate: Date {
        startDate.addingTimeInterval(TimeInterval(totalMinutes*60))
    }

    var body: some View {
        Button {
            if limitOfSets == sets.count {
                end()
            } else {
                action()
            }
            animatePress()
        } label: {
            ZStack{
                Circle()
                    .fill(isPressed
                          ? Color.white.opacity(0.8) : Color.white.opacity(0.3)
                    )
                    .frame(width: 200, height: 200)
                if (limitOfSets == sets.count) ||
                    (sets.count == (limitOfSets - 1) && remainingTime == 0) {
                    Text("FIN")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                } else {
                    VStack{
                        if remainingTime > 0 {
                            Text(timeFormatted(remainingTime))
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            if limitOfSets - 1 == sets.count {
                                Text("ÚLTIMA RONDA")
                                    .font(.footnote)
                                    .fontWeight(.black)
                            }
                        } else {
                            Text("AGOTADO")
                                .font(.title)
                                .fontWeight(.black)
                            Text("Pulsa para siguiente ronda")
                                .font(.footnote)
                        }
                    }
                    .foregroundColor(
                        (limitOfSets - 1 == sets.count)
                        ? .blue : .white
                    )
                    .frame(width: 180, height: 180)
                    .background(Circle().fill(
                        (limitOfSets - 1 == sets.count) ?
                            .white : .blue.opacity(0.3))
                    )
                }
            }
        }
        .buttonStyle(.plain)
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

    private func animatePress() {
        withAnimation(.easeInOut(duration: 0.1)) {
            isPressed = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = false
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

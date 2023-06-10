//
//  CountDownView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 9/6/23.
//

import SwiftUI

let timer = Timer
    .publish(every: 1, on: .main, in: .common)
    .autoconnect()

struct CountDownView: View {
    @State var progressValue: Float
    @State var seconds: Int
    @Binding var hasFinish: Bool
    var progression: Float = 0.0

    init(seconds: Int, hasFinish: Binding<Bool>) {
        self.progression = Float(1/Float(seconds))
        self.progressValue = 1.0
        self.seconds = seconds
        self._hasFinish = hasFinish
    }

    var body: some View {
        ZStack {
            VStack {
                ProgressBar(progress: self.$progressValue,
                            seconds: self.$seconds)
                    .frame(width: 150.0, height: 150.0)
                    .padding(40.0)
                    .onReceive(timer) { input in
                        progressValue -= progression
                        seconds -= 1
                        if seconds == 0 {
                            hasFinish = true
                            timer.upstream.connect().cancel()
                        }
                    }
            }
        }
    }
}

struct ProgressBar: View {
    @Binding var progress: Float
    @Binding var seconds: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 20.0)
                .opacity(0.3)
                .foregroundColor(Color.red)

            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 20.0, lineCap: .round, lineJoin: .round))
                .foregroundColor(Color.red)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear)

            TimerTitleView(seconds: self.$seconds)
        }
    }
}

struct TimerTitleView: View {
    @Binding var seconds: Int

    var body: some View {
        if seconds == 0 {
            Text("FIN")
                .font(.largeTitle)
                .bold()
        } else {
            Text(String(setTime(with: self.seconds)))
                .font(.largeTitle)
                .bold()
        }
    }

    func setTime(with seconds: Int) -> String {
        let (m, s) = ((seconds % 3600) / 60, (seconds % 3600) % 60)
        return String(format: "%02d:%02d", arguments: [m,s])
    }
}

struct CountDownView_Previews: PreviewProvider {
    static var previews: some View {
        @State var hasTimerFinished = false
        CountDownView(seconds: 10, hasFinish: $hasTimerFinished)
    }
}

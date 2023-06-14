//
//  CountDownView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 9/6/23.
//

import SwiftUI

let chronoTimer = Timer
    .publish(every: 1, on: .main, in: .common)
    .autoconnect()

struct ChronoTimerView: View {
    @State var seconds: Int
    @State var isAnimating: Bool = false
    @Binding var hasFinish: Bool

    init(seconds: Int, hasFinish: Binding<Bool>) {
        self.seconds = 0
        self._hasFinish = hasFinish
    }

    var body: some View {
        ZStack {
            VStack {
                ChronoProgressBar(seconds: self.$seconds,
                                  isAnimating: self.$isAnimating)
                .frame(width: 150.0, height: 150.0)
                .padding(40.0)
                .onReceive(chronoTimer) { input in
                    if isAnimating {
                        seconds += 1
                        timer.upstream.connect().cancel()
                    }
                }
            }
        }.onTapGesture {
            isAnimating.toggle()
        }.simultaneousGesture(
            TapGesture(count: 2)
                .onEnded { _ in
                    seconds = 0
                }
        )
    }
}

struct ChronoProgressBar: View {
    @Binding var seconds: Int
    @Binding var isAnimating: Bool

    let animation = Animation
        .easeOut(duration: 1)
        .repeatForever(autoreverses: false)

    var body: some View {
        ZStack {
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 20))
                .foregroundStyle(.tertiary)
                .overlay {
                    Circle()
                        .trim(from: 0,
                              to: isAnimating ? 1 : 0)
                        .stroke(.red,
                                style: StrokeStyle(lineWidth: 20,
                                                   lineCap: .round))
                }
                .rotationEffect(.degrees(-90))

            ChronoTitleView(seconds: self.$seconds)
        }
    }
}

struct ChronoTitleView: View {
    @Binding var seconds: Int

    var body: some View {
        Text(String(setTime(with: self.seconds)))
            .font(.largeTitle)
            .bold()
    }

    func setTime(with seconds: Int) -> String {
        let (m, s) = ((seconds % 3600) / 60, (seconds % 3600) % 60)
        return String(format: "%02d:%02d", arguments: [m,s])
    }
}

struct ChronoTimerView_Previews: PreviewProvider {
    static var previews: some View {
        @State var hasTimerFinished = false
        ChronoTimerView(seconds: 10, hasFinish: $hasTimerFinished)
    }
}

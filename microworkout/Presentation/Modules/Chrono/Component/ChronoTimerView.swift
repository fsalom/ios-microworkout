//
//  CountDownView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 9/6/23.
//

import SwiftUI

let chronoTimer = Timer
    .publish(every: 0.001, on: .main, in: .common)
    .autoconnect()

struct ChronoTimerView: View {
    @State var seconds: Double
    @State var isAnimating: Bool = false
    @Binding var hasFinish: Bool

    init(seconds: Double, hasFinish: Binding<Bool>) {
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
                        seconds += 0.001
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
    @Binding var seconds: Double
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
    @Binding var seconds: Double

    var body: some View {
        let (m, s, ms) = setTime(with: self.seconds)
        HStack {
            Text(String(format: "%02d", m))
                .font(.system(size: 25))
                .bold()
                .frame(width: 30)
            Text(":")
            Text(String(format: "%02d", s))
                .font(.system(size: 25))
                .bold()
                .frame(width: 30)
            Text(":")
            Text(String(format: "%02d", ms))
                .font(.system(size: 25))
                .bold()
                .frame(width: 30)
        }
    }

    func setTime(with miliseconds: Double) -> (Int, Int, Int) {
        let minutes = Int((miliseconds/60).truncatingRemainder(dividingBy: 60))
        let seconds = Int(miliseconds.truncatingRemainder(dividingBy: 60))
        let milliseconds = Int((Double(miliseconds) * 100).truncatingRemainder(dividingBy: 100))
        return (minutes, seconds, milliseconds)
    }
}

struct ChronoTimerView_Previews: PreviewProvider {
    static var previews: some View {
        @State var hasTimerFinished = false
        ChronoTimerView(seconds: 10, hasFinish: $hasTimerFinished)
    }
}

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
        }
    }
}

struct ChronoProgressBar: View {
    @Binding var seconds: Int
    @Binding var isAnimating: Bool
    @State var degrees: Int = 360

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 20.0)
                .opacity(0.3)
                .foregroundColor(Color.red)


            Circle()
                .trim(from: 0, to: 0.05)
                .stroke(style: StrokeStyle(lineWidth: 20.0,
                                           lineCap: .round,
                                           lineJoin: .round))
                .foregroundColor(.red)
                .rotationEffect(Angle(degrees: Double(degrees)))
                .onChange(of: seconds, perform: { newValue in
                    let animation = Animation.easeInOut(duration: 1).repeatForever()
                    withAnimation(animation) {
                        if isAnimating {
                            degrees = degrees == 0 ? 360 : 0
                        }
                    }
                })
                .animation(Animation.linear(duration: 1),
                           value: UUID())

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

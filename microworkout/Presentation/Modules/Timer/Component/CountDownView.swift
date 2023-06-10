//
//  CountDownView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 9/6/23.
//

import SwiftUI

import SwiftUI

let timer = Timer
    .publish(every: 1, on: .main, in: .common)
    .autoconnect()

struct CountDownView: View {
    @State var progressValue: Float
    @State var seconds: Int
    var progression: Float = 0.0

    init(seconds: Int) {
        self.seconds = seconds
        self.progression = Float(Float(seconds) / 100)
        self.progressValue = 1.0
    }

    var body: some View {
        ZStack {
            Color.yellow
                .opacity(0.1)
                .edgesIgnoringSafeArea(.all)

            VStack {
                ProgressBar(progress: self.$progressValue, seconds: self.seconds)
                    .frame(width: 150.0, height: 150.0)
                    .padding(40.0)
                    .onReceive(timer) { input in
                        progressValue -= progression
                        if progressValue < 0 {
                            timer.upstream.connect().cancel()
                        }
                    }
            }
        }
    }
}

struct ProgressBar: View {
    @Binding var progress: Float
    var seconds: Int

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

            Text(String(setTime(with: Int(round(Float(self.seconds) * self.progress)) )))
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
        CountDownView(seconds: 10)
    }
}

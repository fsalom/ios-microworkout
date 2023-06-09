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

    var body: some View {
        ZStack {
            Color.yellow
                .opacity(0.1)
                .edgesIgnoringSafeArea(.all)

            VStack {
                ProgressBar(progress: self.$progressValue)
                    .frame(width: 150.0, height: 150.0)
                    .padding(40.0)
                    .onReceive(timer) { input in
                        progressValue -= 0.01
                        if progressValue == 0 {
                            timer.upstream.connect().cancel()
                        }
                    }
            }
        }
    }
}

struct ProgressBar: View {
    @Binding var progress: Float

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

            Text(String(format: "%.0f %%", min(self.progress, 1.0)*100.0))
                .font(.largeTitle)
                .bold()
        }
    }
}

struct CountDownView_Previews: PreviewProvider {
    static var previews: some View {
        CountDownView(progressValue: 0.02)
    }
}

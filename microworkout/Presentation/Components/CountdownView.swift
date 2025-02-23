//
//  CountdownView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 23/2/25.
//


import SwiftUI

struct CountdownView: View {
    @State private var remainingTime: Int
    @State private var timerRunning = true
    let totalTime: Int
    
    init(minutes: Int) {
        self.totalTime = minutes * 60
        self._remainingTime = State(initialValue: minutes * 60)
    }

    var body: some View {
        VStack {
            Text(timeFormatted(remainingTime))
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .padding()
                .background(Circle().fill(Color.white).frame(width: 200, height: 200))
                .padding(.bottom, 100)

            HStack {
                Button(action: { timerRunning.toggle() }) {
                    Text(timerRunning ? "Pausar" : "Reanudar")
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                }
                
                Button(action: resetTimer) {
                    Text("Reiniciar")
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.red)
                        .cornerRadius(10)
                }
            }
        }
        .onAppear {
            startTimer()
        }
    }

    func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timerRunning {
                if remainingTime > 0 {
                    remainingTime -= 1
                } else {
                    timer.invalidate()
                    timerRunning = false
                }
            }
        }
    }

    func resetTimer() {
        remainingTime = totalTime
        timerRunning = true
    }

    func timeFormatted(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

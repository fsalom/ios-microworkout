//
//  CronoView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 29/6/25.
//

import SwiftUI


struct CronoView: View {
    @State private var startDate = Date() // Puedes cambiarlo a una fecha específica
    @State private var elapsedTime: TimeInterval = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(formattedTime(from: elapsedTime))
            .font(.largeTitle)
            .onReceive(timer) { _ in
                elapsedTime = Date().timeIntervalSince(startDate)
            }
    }

    private func formattedTime(from interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

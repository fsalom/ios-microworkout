//
//  HealthKitView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 5/8/23.
//

import SwiftUI
import Charts

struct HealthKitView: View {
    @ObservedObject var viewModel: HealthKitViewModel

    var body: some View {
        VStack {

            Chart(viewModel.beats) { beat in
                BarMark(
                    x: .value("Category", beat.start),
                    y: .value("Value", beat.value)
                )
            }
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        }.task {
            await viewModel.load()
        }

    }
}

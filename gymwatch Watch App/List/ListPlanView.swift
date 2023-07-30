//
//  ListView.swift
//  gymwatch Watch App
//
//  Created by Fernando Salom Carratala on 30/7/23.
//

import SwiftUI

struct ListView: View {
    @ObservedObject var viewModel: ListPlanViewModel

    var body: some View {
        VStack {
            ForEach($viewModel.workouts, id: \.id) { $workout in
                Text(workout.name)
            }
        }.task {
            await viewModel.load()
        }
    }
}

#Preview {
    ListView(viewModel: ListPlanViewModel(useCase: WorkoutUseCase()))
}

//
//  ListView.swift
//  gymwatch Watch App
//
//  Created by Fernando Salom Carratala on 30/7/23.
//

import SwiftUI

struct ListPlanView: View {
    @ObservedObject var viewModel: ListPlanViewModel

    var body: some View {
        List {
            ForEach(viewModel.workouts) { workout in
                NavigationLink {
                    DetailWorkoutBuilder().build(with: workout)
                } label: {
                    VStack {
                        Text(workout.name)
                        Text("otro")
                    }
                }
            }
        }.task {
            await viewModel.load()
        }
    }
}
/*
 #Preview {
 ListView(viewModel: ListPlanViewModel(useCase: WorkoutUseCase()))
 }
 */

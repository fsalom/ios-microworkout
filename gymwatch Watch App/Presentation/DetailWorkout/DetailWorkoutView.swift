//
//  DetailWorkoutView.swift
//  gymwatch Watch App
//
//  Created by Fernando Salom Carratala on 31/7/23.
//

import SwiftUI

struct DetailWorkoutView: View {
    @ObservedObject var viewModel: DetailWorkoutViewModel

    var body: some View {
        Text(viewModel.workout.name)
    }
}

/*
 #Preview {
 DetailWorkoutView(viewModel: DetailWorkoutViewModel(useCase: WorkoutUseCase(),
 workout: WorkoutPlan(id: "example", name: "exercise")))
 }
 */

//
//  DetailWorkoutView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 6/7/23.
//

import SwiftUI

struct DetailWorkoutView: View {
    @ObservedObject var viewModel: DetailWorkoutViewModel
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct DetailWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        DetailWorkoutView(viewModel: DetailWorkoutViewModel(useCase: WorkoutUseCase(),
                                                            workout: WorkoutPlan(id: "-", name: "test", workouts: [])))
    }
}


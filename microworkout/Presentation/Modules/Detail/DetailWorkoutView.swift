//
//  DetailWorkoutView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 6/7/23.
//

import SwiftUI

struct DetailWorkoutView: View {
    @State var isEditing: Bool = false
    @ObservedObject var viewModel: DetailWorkoutViewModel
    var body: some View {
        ScrollView {
            ForEach($viewModel.plan.workouts) { $workout in
                ExerciseRow(workout: $workout,
                            isEditing: $isEditing)
            }
        }.toolbar(content: {
            Button(action: {
                withAnimation {
                    isEditing.toggle()
                }
            }, label: {
                Text(isEditing ? "Ok" : "Editar")
            })
        })
    }
}

struct DetailWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        DetailWorkoutView(viewModel: DetailWorkoutViewModel(useCase: WorkoutUseCase(),
                                                            plan: WorkoutPlan(id: "-", name: "test", workouts: [])))
    }
}


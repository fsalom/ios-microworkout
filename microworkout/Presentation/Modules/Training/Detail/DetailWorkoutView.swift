//
//  DetailWorkoutView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 6/7/23.
//

import SwiftUI

struct DetailWorkoutView: View {
    @State var isEditing: Bool = false
    @Binding var plan: WorkoutPlan
    @ObservedObject var viewModel: DetailWorkoutViewModel
    var body: some View {
        Text(plan.name).font(.title).fontWeight(.bold)
        ScrollView {
            ForEach($plan.workouts) { $workout in
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
        @State var workout = WorkoutPlan(id: "-", name: "test", workouts: [])
        DetailWorkoutView(plan: $workout, viewModel: DetailWorkoutViewModel(useCase: WorkoutUseCase()))
    }
}


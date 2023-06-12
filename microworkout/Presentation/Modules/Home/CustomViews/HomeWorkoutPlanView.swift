//
//  HomeWorkoutPlanView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 8/6/23.
//

import SwiftUI

struct HomeWorkoutPlanView: View {

    var workout: WorkoutPlan

    var body: some View {
        HStack {
            HStack {
                ZStack {
                    Circle()
                        .frame(width: 50, height: 50, alignment: .top)
                        .foregroundColor(.gray)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .foregroundColor(.white)
                        .imageScale(.small)
                        .frame(width: 44, height: 40)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text(workout.name)
                    HStack {
                        Text("Nº de ejercicios").fontWeight(.bold)
                        Text("\(workout.workout.count)")
                        Text("Nº de series").fontWeight(.bold)
                        Text("\(workout.workout.count)")
                    }.font(.footnote)

                }
            }
        }
    }
}

struct HomeWorkoutPlanView_Previews: PreviewProvider {
    static var previews: some View {
        HomeWorkoutPlanView(workout: WorkoutPlan(id: "", name: "Ejemplo", workout: []))
    }
}

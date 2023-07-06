//
//  HomeWorkoutPlanView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 8/6/23.
//

import SwiftUI

struct HomeWorkoutPlanView: View {

    var plan: WorkoutPlan

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
                    Text(plan.name)
                    HStack {
                        Text("Nº de ejercicios").fontWeight(.bold)
                        Text("\(plan.workouts.count)")
                        Text("Nº de series").fontWeight(.bold)
                        Text("\(plan.totalNumberOfSeries)")
                    }.font(.footnote)

                }
            }
        }
    }
}

struct HomeWorkoutPlanView_Previews: PreviewProvider {
    static var previews: some View {
        HomeWorkoutPlanView(plan: WorkoutPlan(id: "", name: "Ejemplo", workouts: []))
    }
}

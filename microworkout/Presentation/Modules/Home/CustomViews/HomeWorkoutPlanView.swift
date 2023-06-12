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
            VStack {
                Text(workout.name)
                Text("\(workout.workout.count)")
            }.padding(10)
        }.frame(maxWidth: .infinity)
        .padding(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }
}

struct HomeWorkoutPlanView_Previews: PreviewProvider {
    static var previews: some View {
        HomeWorkoutPlanView(workout: WorkoutPlan(id: "", name: "Ejemplo", workout: []))
    }
}

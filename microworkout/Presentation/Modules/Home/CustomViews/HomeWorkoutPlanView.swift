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
        VStack {
            Text(workout.name)
            Text("\(workout.workout.count)")
        }.padding(10)
    }
}

struct HomeWorkoutPlanView_Previews: PreviewProvider {
    static var previews: some View {
        HomeWorkoutPlanView(workout: WorkoutPlan(id: "", name: "Ejemplo", workout: []))
    }
}

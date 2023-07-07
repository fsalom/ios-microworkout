//
//  ExerciseRow.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 6/7/23.
//

import SwiftUI

struct ExerciseRow: View {
    var workout: Workout
    var body: some View {
        Text(workout.exercise.name)
        if workout.exercise.type == .reps {
            Text("Número de repeticiones: \(workout.serie.reps)")
            Text("Peso: \(workout.serie.weight)")
        }
    }
}

struct ExerciseRow_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseRow(workout: Workout(exercise: .init(name: "sentadilla", type: .reps),
                                     numberOfSeries: 4,
                                     results: [],
                                     serie: Serie(reps: 10, weight: 8.0, rpe: 8.0, rir: 9.0)))
    }
}

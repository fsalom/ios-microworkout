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
        VStack(alignment: .leading) {
            Text(workout.exercise.name)
            HStack {
                Text("\(workout.numberOfSeries) x")
                switch workout.exercise.type {
                case .weight:
                    Text("\(workout.serie.reps) x ")
                    Text("\(workout.serie.weight.formatted) Kg ")
                case .distance:
                    Text("\(workout.serie.distance.formatted) m")
                case .kcal:
                    Text("\(workout.serie.kcal) kcal")
                case .reps:
                    Text("\(workout.serie.reps) repeticiones")
                }

                Text("\(workout.exercise.name)")
                Spacer()
            }
            Text("Series:")
            ForEach(workout.results){ result in
                HStack {
                    switch workout.exercise.type {
                    case .weight:
                        Text("\(result.reps) x ")
                        Text("\(result.weight.formatted) Kg")
                        Text("\(result.rpe.formatted)")
                    case .distance:
                        Text("\(workout.serie.distance.formatted) m")
                    case .kcal:
                        Text("\(workout.serie.kcal) kcal")
                    case .reps:
                        Text("\(workout.serie.reps) repeticiones")
                    }
                    Spacer()
                }
            }

        }.padding(16)
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

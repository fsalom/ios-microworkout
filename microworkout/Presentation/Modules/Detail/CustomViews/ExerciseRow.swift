//
//  ExerciseRow.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 6/7/23.
//

import SwiftUI

struct ExerciseRow: View {
    @State var hasPressedAdd: Bool = false
    @State var workout: Workout
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(workout.numberOfSeries)")
                    .fontWeight(.heavy)
                    .padding(10)
                    .foregroundColor(.white)
                    .background(.gray)
                    .clipShape(Circle())
                VStack(alignment: .leading){
                    Text(workout.exercise.name)
                        .font(.system(size: 20))
                        .fontWeight(.bold)
                    HStack {
                        switch workout.exercise.type {
                        case .weight:
                            Text("\(workout.serie.reps) x")
                            Text("\(workout.serie.weight.formatted)Kg ").bold()
                        case .distance:
                            Text("\(workout.serie.distance.formatted)m").bold()
                        case .kcal:
                            Text("\(workout.serie.kcal)kcal").bold()
                        case .reps:
                            Text("\(workout.serie.reps) repeticiones").bold()
                        }
                        Spacer()
                    }
                }
                Spacer()
                Button(action: {
                    hasPressedAdd.toggle()
                }, label: {
                    if !hasPressedAdd {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(.green)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(.red)
                            .clipShape(Circle())
                    }
                })
            }.onTapGesture(perform: {
                withAnimation {
                    workout.isCollapsed.toggle()
                }
            })
        }.padding(16)
        if hasPressedAdd {
            AddWorkoutView(weight: 100.0, rep: 10, RIR: 7)
        }
        if !workout.isCollapsed {
            Divider()

            VStack(alignment: .leading) {
                Text("Series:").bold()
                ForEach(workout.results) { result in
                    HStack {
                        switch workout.exercise.type {
                        case .weight:
                            Text("\(result.reps) x ")
                            Text("\(result.weight.formatted) Kg")
                                .bold()
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
            Divider()
        }
    }
}

/*
 struct ExerciseRow_Previews: PreviewProvider {
 static var previews: some View {
 ExerciseRow(workout: Workout(exercise: .init(name: "sentadilla", type: .reps),
 numberOfSeries: 4,
 results: [],
 serie: Serie(reps: 10, weight: 8.0, rpe: 8.0, rir: 9.0)))
 }
 }
 */

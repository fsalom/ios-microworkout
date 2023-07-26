//
//  ExerciseRow.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 6/7/23.
//

import SwiftUI

struct ExerciseRow: View {
    @State var hasPressedAdd: Bool = false
    @Binding var workout: Workout
    @Binding var isEditing: Bool

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                NumberOfSeriesView(workout: $workout)
                VStack(alignment: .leading){
                    Text(workout.exercise.name)
                        .font(.system(size: 20))
                        .fontWeight(.bold)
                    HStack {                       
                        switch workout.exercise.type {
                        case .weight:
                            Text("\(workout.set.reps) x")
                            Text("\(workout.set.weight.formatted)Kg ").bold()
                        case .distance:
                            if workout.set.distance == 0 {
                                Text("No definido").bold()
                            } else {
                                Text("\(workout.set.distance.formatted)m").bold()
                            }
                        case .kcal:
                            Text("\(workout.set.kcal)kcal").bold()
                        case .reps:
                            Text("\(workout.set.reps) repeticiones").bold()
                        case .none:
                            Text("no definido")
                        }
                        Spacer()
                    }
                }
                Spacer()
                Button(action: {
                    withAnimation {
                        hasPressedAdd.toggle()
                    }
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
            AddWorkoutView(workout: $workout,
                           hasPressedAdd: $hasPressedAdd,
                           set: Set())
        }
        if !workout.isCollapsed {
            Divider()

            VStack(alignment: .leading) {
                ForEach(workout.results) { result in
                    HStack {
                        switch workout.exercise.type {
                        case .weight:
                            Text("\(result.reps) x ")
                            Text("\(result.weight.formatted) Kg")
                                .bold()
                            Spacer()
                            RpeView(rpe: result.rpe)
                        case .distance:
                            Text("\(result.reps) x ")
                            Text("\(result.distance.formatted) m")
                            Spacer()
                        case .kcal:
                            Text("\(result.kcal) kcal")
                        case .reps:
                            Text("\(result.reps) repeticiones")
                        case .none:
                            Text("no definido")
                        }
                        if isEditing {
                            Button(action: {
                                withAnimation {
                                    workout.results.removeAll(where: {$0.id == result.id})
                                }
                            }, label: {
                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(.red)
                                    .clipShape(Circle())
                            })
                        }
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

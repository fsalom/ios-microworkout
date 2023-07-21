//
//  AddWorkoutView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 11/7/23.
//

import SwiftUI

struct AddWorkoutView: View {
    @Binding var workout: Workout {
        didSet {
            serie = Serie(reps: workout.serie.reps,
                          weight: workout.serie.weight,
                          rpe: workout.serie.rpe,
                          rir: workout.serie.rir)
            isNew = workout.exercise.type == .none ? true : false
        }
    }
    @State var isNew: Bool = false
    @Binding var hasPressedAdd: Bool
    @State var serie: Serie = Serie(reps: 5, weight: 40, rpe: 5, rir: 5)

    @State var weightsValue: String = ""{
        didSet {
            serie.weight = transformToFloat(this: weightsValue)
        }
    }

    @State var repsValue: String = "" {
        didSet {
            serie.reps = transformToInt(this: repsValue)
        }
    }

    @State var distancesValue: String = "" {
        didSet {
            serie.distance = transformToFloat(this: distancesValue)
        }
    }

    @State var kcalsValue: String = "" {
        didSet {
            serie.kcal = transformToInt(this: kcalsValue)
        }
    }

    @State var rirsValue: String = "" {
        didSet {
            serie.rir = transformToFloat(this: rirsValue)
        }
    }

    var weights: [Float] {
        var min: Float = self.workout.serie.weight * 0.5
        let max: Float = self.workout.serie.weight * 1.5
        var weights = [Float]()
        while min <= max {
            weights.append(min)
            min += 1.25
        }
        return weights
    }

    var reps: [Int] {
        var min: Int = Int(Double(self.workout.serie.reps) * 0.5)
        let max: Int = Int(Double(self.workout.serie.reps) * 1.5)
        var reps = [Int]()
        while min <= max {
            reps.append(min)
            min += 1
        }
        return reps
    }

    var distances: [Int] {
        var min: Int = Int(Double(self.workout.serie.distance) * 0.5)
        let max: Int = Int(Double(self.workout.serie.distance) * 1.5)
        var distances = [Int]()
        while min <= max {
            distances.append(min)
            min += 500
        }
        return distances
    }

    var kcals: [Int] {
        var min: Int = Int(Double(self.workout.serie.distance) * 0.5)
        let max: Int = Int(Double(self.workout.serie.distance) * 1.5)
        var kcals = [Int]()
        while min <= max {
            kcals.append(min)
            min += 5
        }
        return kcals
    }

    var RIRs: [Float] {
        var min: Float = 1
        let max: Float = 10
        var rirs = [Float]()
        while min <= max {
            rirs.append(min)
            min += 0.5
        }
        return rirs
    }

    var body: some View {
        HStack(spacing: 10) {
            switch serie.exercise {
            case .distance:
                if isNew {
                    Picker("REP", selection: $serie.reps) {
                        ForEach(reps, id: \.self) {
                            Text($0 == 0 ? "Fallo" : "\($0)")
                        }
                    }.pickerStyle(.menu)
                    Picker("m", selection: $serie.distance) {
                        ForEach(distances, id: \.self) {
                            Text("\($0.formatted) m")
                        }
                    }.pickerStyle(.menu)
                    Spacer()
                } else {
                    TextField("series", text: $repsValue)
                    TextField("metros", text: $distancesValue)
                }
                Button {
                    withAnimation {
                        workout.results.append(Serie(reps: serie.reps,
                                                     weight: serie.weight,
                                                     rpe: serie.rpe,
                                                     rir: 0))
                        hasPressedAdd = false
                    }
                } label: {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(.blue)
                        .clipShape(Circle())
                }.buttonStyle(.plain)
            case .weight:
                if isNew {
                    Picker("REP", selection: $serie.reps) {
                        ForEach(reps, id: \.self) {
                            Text($0 == 0 ? "Fallo" : "\($0)")
                        }
                    }.pickerStyle(.menu)
                    Picker("KG", selection: $serie.weight) {
                        ForEach(weights, id: \.self) {
                            Text("\($0.formatted) Kg")
                        }
                    }.pickerStyle(.menu)
                    Picker("RPE", selection: $serie.rpe) {
                        ForEach(RIRs, id: \.self) {
                            Text("\($0.formatted)")
                        }
                    }.pickerStyle(.menu)
                    Spacer()
                } else {
                    TextField("repeticiones", text: $repsValue)
                    TextField("Kg", text: $weightsValue)
                }
                Button {
                    withAnimation {
                        workout.results.append(Serie(reps: serie.reps,
                                                     weight: serie.weight,
                                                     rpe: serie.rpe,
                                                     rir: 0))
                        hasPressedAdd = false
                    }
                } label: {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(.blue)
                        .clipShape(Circle())
                }.buttonStyle(.plain)
            case .kcal:
                Picker("KCAL", selection: $serie.kcal) {
                    ForEach(kcals, id: \.self) {
                        Text($0 == 0 ? "Fallo" : "\($0)")
                    }
                }.pickerStyle(.menu)
                Spacer()
                Button {
                    withAnimation {
                        workout.results.append(Serie(kcal: serie.kcal))
                        hasPressedAdd = false
                    }
                } label: {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(.blue)
                        .clipShape(Circle())
                }.buttonStyle(.plain)
            case .reps:
                Picker("REPS", selection: $serie.reps) {
                    ForEach(reps, id: \.self) {
                        Text($0 == 0 ? "Fallo" : "\($0)")
                    }
                }.pickerStyle(.menu)
                Spacer()
                Button {
                    withAnimation {
                        workout.results.append(Serie(reps: serie.reps))
                        hasPressedAdd = false
                    }
                } label: {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(.blue)
                        .clipShape(Circle())
                }.buttonStyle(.plain)
            case .none:
                Picker("REPS", selection: $serie.exercise) {
                    ForEach(ExerciseType.allCases, id:  \.id) {
                        Text(String(describing: $0))
                    }
                }.pickerStyle(.menu)
            }
        }.padding(16)
            .onAppear {
                serie = workout.serie
            }
    }

    func transformToInt(this value: String) -> Int {
        if NumberFormatter().number(from: value) != nil {
            do {
                return try Int(value, format: .number)
            } catch {
                return 0
            }
        } else {
            return 0
        }
    }

    func transformToFloat(this value: String) -> Float {
        if NumberFormatter().number(from: value) != nil {
            do {
                return try Float(value, format: .number)
            } catch {
                return 0
            }
        } else {
            return 0
        }
    }
}

/*
 #Preview {
 AddWorkoutView(weight: 60, rep: 6, RIR: 5)
 }
 */

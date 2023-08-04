//
//  AddWorkoutView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 11/7/23.
//

import SwiftUI

struct AddWorkoutView: View {
    @Binding var workout: Workout
    @Binding var hasPressedAdd: Bool
    @State var hasAset: Bool = false
    @State var set: Set
    @State var hours: Int = 0
    @State var minutes: Int = 0
    @State var seconds: Int = 0

    @State var weightsValue: String = ""{
        didSet {
            set.weight = transformToFloat(this: weightsValue)
        }
    }

    @State var repsValue: String = "" {
        didSet {
            set.reps = transformToInt(this: repsValue)
        }
    }

    @State var distancesValue: String = ""

    @State var kcalsValue: String = "" {
        didSet {
            set.kcal = transformToInt(this: kcalsValue)
        }
    }

    @State var rpeValue: String = "" {
        didSet {
            set.rpe = transformToFloat(this: rpeValue)
        }
    }

    @State var rirsValue: String = "" {
        didSet {
            set.rir = transformToFloat(this: rirsValue)
        }
    }

    var time24: [Int] {
        var time24 = [Int]()
        var time = 0
        while time <= 60 {
            time24.append(time)
            time += 1
        }
        return time24
    }

    var time60: [Int] {
        var time60 = [Int]()
        var time = 0
        while time <= 60 {
            time60.append(time)
            time += 1
        }
        return time60
    }

    var weights: [Float] {
        var min: Float = self.workout.set.weight * 0.5
        let max: Float = self.workout.set.weight * 1.5
        var weights = [Float]()
        while min <= max {
            weights.append(min)
            min += 1.25
        }
        return weights
    }

    var reps: [Int] {
        var min: Int = Int(Double(self.workout.set.reps) * 0.5)
        let max: Int = Int(Double(self.workout.set.reps) * 1.5)
        var reps = [Int]()
        while min <= max {
            reps.append(min)
            min += 1
        }
        return reps
    }

    var distances: [Int] {
        var min: Int = Int(Double(self.workout.set.distance) * 0.5)
        let max: Int = Int(Double(self.workout.set.distance) * 1.5)
        var distances = [Int]()
        while min <= max {
            distances.append(min)
            min += 500
        }
        return distances
    }

    var kcals: [Int] {
        var min: Int = Int(Double(self.workout.set.distance) * 0.5)
        let max: Int = Int(Double(self.workout.set.distance) * 1.5)
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
            switch set.exercise {
            case .distance:
                if hasAset {
                    Picker("REP", selection: $set.reps) {
                        ForEach(reps, id: \.self) {
                            Text($0 == 0 ? "Fallo" : "\($0)")
                        }
                    }.pickerStyle(.menu)
                    Picker("m", selection: $set.distance) {
                        ForEach(distances, id: \.self) {
                            Text("\($0.formatted) m")
                        }
                    }.pickerStyle(.menu)
                    Spacer()
                } else {
                    VStack {
                        HStack {
                            TextField("sets", text: $repsValue)
                                .padding(10)
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray))
                                .keyboardType(.numberPad)
                            TextField("metros", text: $distancesValue)
                                .padding(10)
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray))
                                .keyboardType(.numberPad)
                        }
                        HStack {
                            Picker("horas", selection: $hours) {
                                ForEach(time24, id: \.self) {
                                    Text("\($0.formatted) h")
                                }
                            }.pickerStyle(.wheel)
                            Picker("minutos", selection: $minutes) {
                                ForEach(time60, id: \.self) {
                                    Text("\($0.formatted) m")
                                }
                            }.pickerStyle(.wheel)
                            Picker("segundos", selection: $seconds) {
                                ForEach(time60, id: \.self) {
                                    Text("\($0.formatted) s")
                                }
                            }.pickerStyle(.wheel)
                        }
                    }
                    // TODO: add time but we have to decide how
                }
                Button {
                    withAnimation {
                        workout.exercise.type = set.exercise
                        self.workout.set.exercise = set.exercise
                        workout.results.append(set)
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
                if hasAset {
                    Picker("REP", selection: $set.reps) {
                        ForEach(reps, id: \.self) {
                            Text($0 == 0 ? "Fallo" : "\($0)")
                        }
                    }.pickerStyle(.menu)
                    Picker("KG", selection: $set.weight) {
                        ForEach(weights, id: \.self) {
                            Text("\($0.formatted) Kg")
                        }
                    }.pickerStyle(.menu)
                    Picker("RPE", selection: $set.rpe) {
                        ForEach(RIRs, id: \.self) {
                            Text("\($0.formatted)")
                        }
                    }.pickerStyle(.menu)
                    Spacer()
                } else {
                    TextField("repeticiones", text: $repsValue)
                        .padding(10)
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray))
                        .keyboardType(.numberPad)
                    TextField("Kg", text: $weightsValue)
                        .padding(10)
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray))
                        .keyboardType(.numberPad)
                    TextField("RPE", text: $rpeValue)
                        .padding(10)
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray))
                        .keyboardType(.numberPad)
                }
                Button {
                    withAnimation {
                        workout.results.append(Set(reps: set.reps,
                                                   weight: set.weight,
                                                   rpe: set.rpe,
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
                if hasAset {
                    Picker("KCAL", selection: $set.kcal) {
                        ForEach(kcals, id: \.self) {
                            Text($0 == 0 ? "Fallo" : "\($0)")
                        }
                    }.pickerStyle(.menu)
                    Spacer()
                } else {
                    TextField("KCAL", text: $kcalsValue)
                        .padding(10)
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray))
                        .keyboardType(.numberPad)
                }
                Button {
                    withAnimation {
                        workout.results.append(Set(kcal: set.kcal))
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
                if hasAset {
                Picker("REPS", selection: $set.reps) {
                    ForEach(reps, id: \.self) {
                        Text($0 == 0 ? "Fallo" : "\($0)")
                    }
                }.pickerStyle(.menu)
                Spacer()
                } else {
                    TextField("REPS", text: $repsValue)
                        .padding(10)
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray))
                        .keyboardType(.numberPad)
                }
                Button {
                    withAnimation {
                        workout.results.append(Set(reps: set.reps))
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
                Picker("REPS", selection: $set.exercise) {
                    ForEach(ExerciseType.allCases, id:  \.id) {
                        Text(String(describing: $0))
                    }
                }.pickerStyle(.menu)
            }
        }.padding(16)
            .onAppear {
                hasAset = workout.set.isEmpty ? false : true
                if workout.set.exercise != .none {
                    set = workout.set
                }
            }.onChange(of: distancesValue) {
                set.distance = transformToInt(this: distancesValue)
            }
            .onChange(of: repsValue) {
                set.reps = transformToInt(this: repsValue)
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

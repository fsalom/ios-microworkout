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
            serie = Serie(reps: workout.serie.reps, weight: workout.serie.weight, rpe: workout.serie.rpe, rir: workout.serie.rir)
        }
    }
    @Binding var hasPressedAdd: Bool
    @State var serie: Serie = Serie(reps: 5, weight: 40, rpe: 5, rir: 5)

    var weights: [Float] {
        var minWeight: Float = self.workout.serie.weight * 0.5
        let maxWeight: Float = self.workout.serie.weight * 1.5
        var weights = [Float]()
        while minWeight <= maxWeight {
            weights.append(minWeight)
            minWeight += 1.25
        }
        return weights
    }

    var reps: [Int] {
        var minRep: Int = Int(Double(self.workout.serie.reps) * 0.5)
        let maxRep: Int = Int(Double(self.workout.serie.reps) * 1.5)
        var reps = [Int]()
        while minRep <= maxRep {
            reps.append(minRep)
            minRep += 1
        }
        return reps
    }

    var RIRs: [Float] {
        var minRIR: Float = 1
        let maxRIR: Float = 10
        var rirs = [Float]()
        while minRIR <= maxRIR {
            rirs.append(minRIR)
            minRIR += 0.5
        }
        return rirs
    }

    var body: some View {
        HStack(spacing: 10) {
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

        }.padding(16)
            .onAppear {
                serie = workout.serie
            }
    }
}

/*
#Preview {
    AddWorkoutView(weight: 60, rep: 6, RIR: 5)
}
*/

//
//  AddWorkoutView.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 11/7/23.
//

import SwiftUI

struct AddWorkoutView: View {
    var weight: Float
    var weights: [Float] {
        var weight: Float = self.weight
        var weights = [Float]()
        while weight <= 120.0 {
            weights.append(weight)
            weight += 1.25
        }
        return weights
    }

    var rep: Int
    var reps: [Int] {
        var rep: Int = 0
        var reps = [Int]()
        while rep <= 10 {
            reps.append(rep)
            rep += 1
        }
        return reps
    }

    var RIR: Int
    var RIRs: [Int] {
        var rir: Int = 5
        var rirs = [Int]()
        while rir <= 10 {
            rirs.append(rir)
            rir += 1
        }
        return rirs
    }
    @State private var selectedWeight: Float = 80.0
    @State private var selectedRep: Int = 1
    @State private var selectedRIR: Int = 5
    var body: some View {
        HStack(spacing: 10) {
            Picker("REP", selection: $selectedRep) {
                ForEach(reps, id: \.self) {
                    Text($0 == 0 ? "Fallo" : "\($0)")
                }
            }.pickerStyle(.menu)
            Picker("KG", selection: $selectedWeight) {
                ForEach(weights, id: \.self) {
                    Text("\($0.formatted) Kg")
                }
            }.pickerStyle(.menu)
            Picker("RIR", selection: $selectedRIR) {
                ForEach(RIRs, id: \.self) {
                    Text("\($0)")
                }
            }.pickerStyle(.menu)
            Spacer()
            
            Button {

            } label: {
                Image(systemName: "checkmark")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(.blue)
                    .clipShape(Circle())
            }.buttonStyle(.plain)

        }.padding(16)
    }
}

#Preview {
    AddWorkoutView(weight: 60, rep: 6, RIR: 5)
}

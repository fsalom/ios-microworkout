//
//  ExerciseInput.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 19/7/25.
//

import SwiftUI

struct ExerciseInput: View {
    let exercise: Exercise
    var existing: LoggedExercise? = nil
    var onSave: (LoggedExercise) -> Void

    @State private var repsValue: Double? = nil
    @State private var weight: Double? = nil
    @State private var errorMessage: String?

    var isFormValid: Bool {
        repsValue != nil && weight != nil
    }

    @FocusState private var focusedField: Field?
    enum Field { case reps, weight }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(existing == nil ? "Nueva serie" : "Editar serie")
                .font(.headline)
            Text(exercise.name)
                .font(.title2)
                .bold()

            StepperInputView(label: "Peso", value: $weight)

            StepperInputView(label: "Repeticiones", value: $repsValue)

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }

            Button(action: {
                save()
            }) {
                Text("Guardar")
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.black : Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(!isFormValid)

        }
        .onAppear {
            repsValue = existing.map { Double($0.reps) }
            weight = existing?.weight
            focusedField = .reps
        }
    }

    private func save() {
        guard let r = repsValue.flatMap(Int.init), let w = weight else {
            errorMessage = "Valores no válidos"
            return
        }

        onSave(LoggedExercise(
            id: existing?.id ?? UUID().uuidString,
            exercise: exercise,
            reps: r,
            weight: w
        ))
    }
}

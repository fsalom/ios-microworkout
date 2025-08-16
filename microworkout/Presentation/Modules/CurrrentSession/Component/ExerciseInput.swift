import SwiftUI

struct ExerciseInput: View {
    let exercise: Exercise
    var existing: WorkoutEntry? = nil
    var onSave: (WorkoutEntry) -> Void

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
            repsValue = existing.map { Double($0.reps ?? 0) }
            weight = existing?.weight
            focusedField = .reps
        }
    }

    private func save() {
        guard let r = repsValue.flatMap(Int.init), let w = weight else {
            errorMessage = "Valores no válidos"
            return
        }

        onSave(WorkoutEntry(
            id: existing?.id ?? UUID(),
            exercise: exercise,
            date: existing?.date ?? Date(),
            reps: r,
            weight: w,
            distanceMeters: nil,
            calories: nil,
            isCompleted: existing?.isCompleted ?? false
        ))
    }
}

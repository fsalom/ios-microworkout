import SwiftUI

struct LoggedSetInput: View {
    let exercise: Exercise
    let isEditing: Bool
    let initialWeight: Double?
    let initialReps: Int?
    let initialRir: Float?
    var mediaSetId: UUID? = nil
    var mediaUseCase: SetMediaUseCase? = nil

    var onSave: (Double?, Int?, Float?) -> Void
    var onDelete: (() -> Void)? = nil

    @State private var weight: Double? = nil
    @State private var reps: Double? = nil
    @State private var rir: Double? = nil
    @State private var showDeleteConfirm: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                Text(isEditing ? "Editar serie" : "Nueva serie")
                    .font(.headline)
                Text(exercise.name)
                    .font(.title2)
                    .bold()

                StepperInputView(label: "Peso (kg)", value: $weight)
                StepperInputView(label: "Repeticiones", value: Binding(
                    get: { reps },
                    set: { reps = $0 }
                ))
                StepperInputView(label: "RIR", value: $rir)

                if let setId = mediaSetId, let useCase = mediaUseCase {
                    Divider()
                        .padding(.vertical, 8)
                    SetMediaGalleryView(setId: setId, useCase: useCase)
                }

                Button(action: save) {
                    Text("Guardar")
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.top, 6)

                if isEditing, onDelete != nil {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Eliminar serie", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                }
            }
        }
        .onAppear {
            weight = initialWeight
            reps = initialReps.map { Double($0) }
            rir = initialRir.map { Double($0) }
        }
        .confirmationDialog(
            "¿Eliminar esta serie?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive) {
                onDelete?()
                dismiss()
            }
            Button("Cancelar", role: .cancel) {}
        }
    }

    private func save() {
        let intReps = reps.flatMap { Int($0) }
        let floatRir = rir.map { Float($0) }
        onSave(weight, intReps, floatRir)
        dismiss()
    }
}

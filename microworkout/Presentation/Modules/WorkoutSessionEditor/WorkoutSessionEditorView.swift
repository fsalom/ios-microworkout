import SwiftUI

struct WorkoutSessionEditorView: View {
    @StateObject var viewModel: WorkoutSessionEditorViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            content
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
        }
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .top, spacing: 0) {
            HeaderBar(
                title: viewModel.uiState.isNew ? "Nueva sesión" : "Editar sesión",
                canSave: viewModel.uiState.canSave,
                onBack: { dismiss() },
                onSave: { viewModel.save() }
            )
        }
        .onChange(of: viewModel.uiState.didSave) { _, didSave in
            if didSave { dismiss() }
        }
        .sheet(isPresented: pickerBinding) {
            ExercisePickerSheet(
                search: Binding(
                    get: { viewModel.uiState.search },
                    set: { viewModel.search($0) }
                ),
                results: viewModel.uiState.searchResults,
                onPick: { viewModel.addExercise($0) },
                onCreate: { viewModel.createAndAdd(named: $0) }
            )
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 14) {
            NameField(
                name: Binding(
                    get: { viewModel.uiState.session.name },
                    set: { viewModel.updateName($0) }
                )
            )

            HStack {
                Text("Ejercicios")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.uiState.session.exercises.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }
            .padding(.top, 4)

            if viewModel.uiState.session.exercises.isEmpty {
                EmptyExercisesState()
            } else {
                exercisesList
            }

            Button(action: { viewModel.openPicker() }) {
                Label("Añadir ejercicio", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    @ViewBuilder
    private var exercisesList: some View {
        VStack(spacing: 8) {
            let exercises = viewModel.uiState.session.exercises
            ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                EditorExerciseRow(
                    exercise: exercise,
                    canMoveUp: index > 0,
                    canMoveDown: index < exercises.count - 1,
                    onMoveUp: { viewModel.moveUp(id: exercise.id) },
                    onMoveDown: { viewModel.moveDown(id: exercise.id) },
                    onRemove: { viewModel.removeExercise(id: exercise.id) }
                )
            }
        }
    }

    private var pickerBinding: Binding<Bool> {
        Binding(
            get: { viewModel.uiState.isPickingExercise },
            set: { if !$0 { viewModel.closePicker() } }
        )
    }
}

private struct HeaderBar: View {
    let title: String
    let canSave: Bool
    let onBack: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                Spacer()
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button(action: onSave) {
                    Text("Guardar")
                        .fontWeight(.semibold)
                        .foregroundColor(canSave ? .blue : .secondary)
                }
                .disabled(!canSave)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            Divider()
        }
        .background(Color(.systemBackground))
    }
}

private struct NameField: View {
    @Binding var name: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Nombre")
                .font(.caption)
                .foregroundColor(.secondary)
                .tracking(0.5)
            TextField("Ej. Push, Pull, Pierna…", text: $name)
                .font(.title3)
                .fontWeight(.semibold)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
        }
    }
}

private struct EditorExerciseRow: View {
    let exercise: Exercise
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.blue)
                .frame(width: 36, height: 36)
                .background(Color.blue.opacity(0.15))
                .clipShape(Circle())

            Text(exercise.name)
                .font(.subheadline)
                .fontWeight(.semibold)

            Spacer()

            Menu {
                Button(action: onMoveUp) {
                    Label("Subir", systemImage: "arrow.up")
                }
                .disabled(!canMoveUp)
                Button(action: onMoveDown) {
                    Label("Bajar", systemImage: "arrow.down")
                }
                .disabled(!canMoveDown)
                Button(role: .destructive, action: onRemove) {
                    Label("Quitar", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 8)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

private struct EmptyExercisesState: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("Aún no hay ejercicios")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Añade los que quieras incluir en esta sesión")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

private struct ExercisePickerSheet: View {
    @Binding var search: String
    let results: [Exercise]
    let onPick: (Exercise) -> Void
    let onCreate: (String) -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchField

                if results.isEmpty && !search.isEmpty {
                    Button(action: { onCreate(search) }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            Text("Crear \"\(search)\" como nuevo ejercicio")
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding()
                    }
                    .buttonStyle(.plain)
                }

                List(results) { exercise in
                    Button(action: { onPick(exercise) }) {
                        HStack {
                            Text(exercise.name)
                            if exercise.source == .local {
                                Text("Local")
                                    .font(.caption2).fontWeight(.semibold)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.15))
                                    .foregroundColor(.secondary)
                                    .clipShape(Capsule())
                            }
                            Spacer()
                            Image(systemName: "plus")
                                .foregroundColor(.blue)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Añadir ejercicio")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Buscar ejercicio", text: $search)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
        .padding()
    }
}

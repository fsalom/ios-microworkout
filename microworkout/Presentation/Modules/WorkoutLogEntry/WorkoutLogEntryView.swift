import SwiftUI

struct WorkoutLogEntryView: View {
    @StateObject var viewModel: WorkoutLogEntryViewModel
    let mediaUseCase: SetMediaUseCase
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            exercisesList
                .padding(16)
                .padding(.bottom, 80)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.uiState.log.sessionName)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { finishBar }
        .onChange(of: viewModel.uiState.isFinished) { _, finished in
            if finished {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { dismiss() }
            }
        }
        .sheet(item: formBinding) { form in
            setFormSheet(for: form)
        }
        .sheet(isPresented: pickerBinding) {
            ExercisePickerSheet(
                search: Binding(
                    get: { viewModel.uiState.search },
                    set: { viewModel.searchExercises($0) }
                ),
                results: viewModel.uiState.searchResults,
                onPick: { viewModel.addExerciseToLog($0) },
                onCreate: { viewModel.createAndAddExercise(named: $0) }
            )
        }
    }

    private var pickerBinding: Binding<Bool> {
        Binding(
            get: { viewModel.uiState.isPickingExercise },
            set: { if !$0 { viewModel.closeExercisePicker() } }
        )
    }

    @ViewBuilder
    private var exercisesList: some View {
        VStack(spacing: 14) {
            ForEach(viewModel.uiState.log.exercises) { exerciseLog in
                LoggedExerciseCard(
                    exerciseLog: exerciseLog,
                    previousReference: viewModel.uiState.previousByExerciseId[exerciseLog.exercise.id],
                    mediaUseCase: mediaUseCase,
                    isNotesExpanded: viewModel.uiState.expandedNotes.contains(exerciseLog.id),
                    onToggleNotes: { viewModel.toggleNotes(for: exerciseLog.id) },
                    onUpdateNotes: { viewModel.updateNotes(exerciseLogId: exerciseLog.id, notes: $0) },
                    onAddSet: { viewModel.openNewSet(for: exerciseLog.id) },
                    onTapSet: { setId in viewModel.openEditSet(exerciseLogId: exerciseLog.id, setId: setId) },
                    onDeleteSet: { setId in viewModel.deleteSet(exerciseLogId: exerciseLog.id, setId: setId) },
                    onCopyPrevious: { viewModel.copyPreviousSets(for: exerciseLog.id) }
                )
            }

            Button(action: { viewModel.openExercisePicker() }) {
                Label("Añadir ejercicio para hoy", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.green.opacity(0.15))
                    .foregroundColor(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    private var finishBar: some View {
        FinishBar(
            isFinished: viewModel.uiState.isFinished,
            onFinish: { viewModel.finish() }
        )
    }

    private var formBinding: Binding<LoggedSetForm?> {
        Binding(
            get: { viewModel.uiState.activeForm },
            set: { if $0 == nil { viewModel.closeForm() } }
        )
    }

    @ViewBuilder
    private func setFormSheet(for form: LoggedSetForm) -> some View {
        if let exercise = viewModel.exerciseForActiveForm() {
            switch form {
            case .new:
                let last = viewModel.lastSet(for: form.exerciseLogId)
                LoggedSetInput(
                    exercise: exercise,
                    isEditing: false,
                    initialWeight: last?.weight,
                    initialReps: last?.reps,
                    initialRir: last?.rir,
                    initialTags: [],
                    onSave: { w, r, rir, tags in viewModel.saveSet(weight: w, reps: r, rir: rir, tags: tags) }
                )
                .padding()
                .presentationDetents([.height(420)])
                .presentationDragIndicator(.visible)
            case .edit(let exerciseLogId, let setId):
                let set = viewModel.setBeingEdited()
                LoggedSetInput(
                    exercise: exercise,
                    isEditing: true,
                    initialWeight: set?.weight,
                    initialReps: set?.reps,
                    initialRir: set?.rir,
                    initialTags: set?.tags ?? [],
                    mediaSetId: setId,
                    mediaUseCase: mediaUseCase,
                    onSave: { w, r, rir, tags in viewModel.saveSet(weight: w, reps: r, rir: rir, tags: tags) },
                    onDelete: { viewModel.deleteSet(exerciseLogId: exerciseLogId, setId: setId) }
                )
                .padding()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

private struct LoggedExerciseCard: View {
    let exerciseLog: LoggedExercise
    let previousReference: PreviousExerciseReference?
    let mediaUseCase: SetMediaUseCase
    let isNotesExpanded: Bool
    let onToggleNotes: () -> Void
    let onUpdateNotes: (String) -> Void
    let onAddSet: () -> Void
    let onTapSet: (UUID) -> Void
    let onDeleteSet: (UUID) -> Void
    let onCopyPrevious: () -> Void

    @State private var isPreviousExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(exerciseLog.exercise.name)
                    .font(.headline)
                Spacer()
                Button(action: onAddSet) {
                    Image(systemName: "plus.circle.fill")
                        .imageScale(.large)
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }

            if let previousReference {
                PreviousTopSetCard(
                    current: exerciseLog,
                    previous: previousReference.exercise,
                    previousDate: previousReference.date
                )

                PreviousSetsList(
                    sets: previousReference.exercise.sets,
                    isExpanded: isPreviousExpanded,
                    onToggle: { isPreviousExpanded.toggle() }
                )

                if exerciseLog.sets.isEmpty && !previousReference.exercise.sets.isEmpty {
                    Button(action: onCopyPrevious) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.doc.fill")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Copiar series anteriores")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue.opacity(0.12))
                        )
                        .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }

            if exerciseLog.sets.isEmpty {
                Text("Pulsa + para añadir tu primera serie")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 6) {
                    ForEach(Array(exerciseLog.sets.enumerated()), id: \.element.id) { index, set in
                        Button(action: { onTapSet(set.id) }) {
                            SetRow(index: index + 1, set: set, mediaUseCase: mediaUseCase)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                onDeleteSet(set.id)
                            } label: {
                                Label("Eliminar serie", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            if isNotesExpanded {
                NotesField(text: exerciseLog.notes ?? "", onChange: onUpdateNotes)
                    .transition(.opacity)
            }

            NotesToggleButton(
                hasNotes: exerciseLog.notes?.isEmpty == false,
                isExpanded: isNotesExpanded,
                action: onToggleNotes
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .animation(.easeInOut(duration: 0.2), value: isNotesExpanded)
    }
}

private struct NotesToggleButton: View {
    let hasNotes: Bool
    let isExpanded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.caption)
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(hasNotes ? .green : .secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(hasNotes ? Color.green.opacity(0.15) : Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        if hasNotes { return "note.text" }
        return isExpanded ? "chevron.up" : "plus"
    }

    private var label: String {
        if hasNotes {
            return isExpanded ? "Ocultar nota" : "Ver nota"
        }
        return isExpanded ? "Cerrar" : "Añadir descripción"
    }
}

private struct SetRow: View {
    let index: Int
    let set: LoggedSet
    let mediaUseCase: SetMediaUseCase

    @State private var mediaCount: Int = 0

    var body: some View {
        HStack(spacing: 8) {
            Text("\(index)")
                .font(.subheadline)
                .fontWeight(.bold)
                .frame(width: 28, alignment: .leading)
                .foregroundColor(.secondary)

            Text(summary)
                .font(.subheadline)
                .fontWeight(.semibold)

            Spacer()

            if mediaCount > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.caption2)
                    Text("\(mediaCount)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.blue.opacity(0.12)))
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
        .task(id: set.id) {
            await loadMediaCount()
        }
    }

    private func loadMediaCount() async {
        do {
            let media = try await mediaUseCase.getMedia(forSetId: set.id)
            mediaCount = media.count
        } catch {
            mediaCount = 0
        }
    }

    private var summary: String {
        var parts: [String] = []
        if let w = set.weight { parts.append("\(format(w)) kg") }
        if let r = set.reps { parts.append("\(r) reps") }
        if let rir = set.rir { parts.append("RIR \(format(Double(rir)))") }
        return parts.isEmpty ? "—" : parts.joined(separator: " · ")
    }

    private func format(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.1f", v)
    }
}

private struct NotesField: View {
    let text: String
    let onChange: (String) -> Void

    @State private var local: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Sensaciones")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("Comentarios del día…", text: $local, axis: .vertical)
                .lineLimit(2...5)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6))
                )
                .onChange(of: local) { _, newValue in onChange(newValue) }
        }
        .onAppear { local = text }
    }
}

private struct PreviousSetsList: View {
    let sets: [LoggedSet]
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: onToggle) {
                HStack(spacing: 6) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                    Text(isExpanded ? "Ocultar series anteriores" : "Ver series anteriores (\(sets.count))")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 4) {
                    ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                        HStack(spacing: 8) {
                            Text("\(index + 1)")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                                .frame(width: 20, alignment: .leading)
                                .monospacedDigit()
                            Text(summary(for: set))
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.primary)
                            Spacer()
                            if !set.tags.isEmpty {
                                HStack(spacing: 3) {
                                    ForEach(set.tags, id: \.self) { tag in
                                        Image(systemName: tag.symbol)
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(tag.color)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.tertiarySystemGroupedBackground))
                        )
                    }
                }
            }
        }
    }

    private func summary(for set: LoggedSet) -> String {
        var parts: [String] = []
        if let w = set.weight { parts.append("\(format(w)) kg") }
        if let r = set.reps { parts.append("\(r) reps") }
        if let rir = set.rir { parts.append("RIR \(format(Double(rir)))") }
        return parts.isEmpty ? "—" : parts.joined(separator: " · ")
    }

    private func format(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.1f", v)
    }
}

private struct FinishBar: View {
    let isFinished: Bool
    let onFinish: () -> Void

    var body: some View {
        VStack {
            if isFinished {
                Label("Entrenamiento guardado", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .padding()
            } else {
                Button(action: onFinish) {
                    Label("Finalizar entrenamiento", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea(edges: .bottom))
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
                                .foregroundColor(.green)
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
                            Spacer()
                            Image(systemName: "plus")
                                .foregroundColor(.green)
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

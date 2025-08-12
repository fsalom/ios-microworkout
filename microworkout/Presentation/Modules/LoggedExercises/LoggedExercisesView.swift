import SwiftUI

struct LoggedExercisesView: View {
    @ObservedObject var viewModel: LoggedExercisesViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        // Pre-calcula datos para no invocar funciones dentro del ForEach
        let grouped = viewModel.groupedByExercise()
        let ordered = viewModel.orderedExercises()

        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack {
                StatsStrip(ui: viewModel.uiState.entryDay)
                    .padding(.horizontal)

                List {
                    ForEach(ordered, id: \.self) { exercise in
                        ExerciseSectionView(
                            title: exercise.name,
                            entries: grouped[exercise] ?? []
                        )
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        viewModel.delete()
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                } label: {
                    Label("Más", systemImage: "ellipsis.circle")
                }
            }
        }
    }
}

// MARK: - Subvistas

private struct StatsStrip: View {
    let ui: WorkoutEntryByDay  // ajusta el tipo si difiere

    var body: some View {
        HStack(spacing: 20) {
            StatView(title: "Ejercicios",
                     value: ui.exercisesFormatted,
                     systemImage: "figure.strengthtraining.traditional")

            StatView(title: "Series",
                     value: ui.totalSeriesFormatted,
                     systemImage: "repeat")

            StatView(title: "Peso total",
                     value: ui.totalWeightFormatted,
                     systemImage: "scalemass")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

private struct ExerciseSectionView: View {
    let title: String
    let entries: [WorkoutEntry]

    var body: some View {
        Section {
            ForEach(entries) { entry in
                ExerciseEntryRow(entry: entry)
            }
        } header: {
            // Header simple y claro
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.vertical, 4)
        }
    }
}

private struct ExerciseEntryRow: View {
    let entry: WorkoutEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.reps ?? 0) repeticiones · \(entry.weight ?? 0.0, specifier: "%.2f") kg")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    LoggedExercisesBuilder().build(for: WorkoutEntryByDay(date: "", entries: [], durationInSeconds: 0))
}

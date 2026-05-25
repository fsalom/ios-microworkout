import SwiftUI

struct LoggedExercisesView: View {
    @StateObject var viewModel: LoggedExercisesViewModel
    let linkedWatch: HealthWorkout?
    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: LoggedExercisesViewModel, linkedWatch: HealthWorkout? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.linkedWatch = linkedWatch
    }

    var body: some View {
        // Pre-calcula datos para no invocar funciones dentro del ForEach
        let grouped = viewModel.groupedByExercise()
        let ordered = viewModel.orderedExercises()

        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 12) {
                if let watch = linkedWatch {
                    LinkedWatchHeader(watch: watch)
                        .padding(.horizontal)
                }

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

private struct LinkedWatchHeader: View {
    let watch: HealthWorkout

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "applewatch")
                    .foregroundColor(.green)
                Text(watch.activityTypeName)
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: "link")
                        .font(.system(size: 9, weight: .bold))
                    Text("Vinculado")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(.green)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.15))
                .clipShape(Capsule())
            }

            Text("\(watch.timeRangeFormatted) · \(watch.durationFormatted)")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                if let cal = watch.caloriesFormatted {
                    HeaderChip(text: cal, icon: "flame.fill", color: .orange)
                }
                if let dist = watch.distanceFormatted {
                    HeaderChip(text: dist, icon: "figure.run", color: .blue)
                }
                if let hr = watch.heartRateFormatted {
                    HeaderChip(text: hr, icon: "heart.fill", color: .red)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.green.opacity(0.45), lineWidth: 1.5)
                )
        )
    }
}

private struct HeaderChip: View {
    let text: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

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
    LoggedExercisesBuilder(component: DefaultAppComponent.preview).build(for: WorkoutEntryByDay(date: "", entries: [], durationInSeconds: 0))
}

import SwiftUI

struct HealthWorkoutDetailView: View {
    @StateObject var viewModel: HealthWorkoutDetailViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                dateSection
                statsGrid
                linkSection
            }
            .padding()
        }
        .navigationTitle("Detalle")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "applewatch")
                .font(.largeTitle)
                .foregroundColor(.green)
            VStack(alignment: .leading) {
                Text(viewModel.uiState.workout.activityTypeName)
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Apple Watch")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let parts = viewModel.uiState.workout.dateParts {
                Text("\(parts.day) de \(parts.monthName) de \(parts.year)")
                    .font(.headline)
            }
            Text(viewModel.uiState.workout.timeRangeFormatted)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCard(title: "Duracion", value: viewModel.uiState.workout.durationFormatted, icon: "clock", color: .blue)

            if let cal = viewModel.uiState.workout.caloriesFormatted {
                StatCard(title: "Calorias", value: cal, icon: "flame.fill", color: .orange)
            }

            if let dist = viewModel.uiState.workout.distanceFormatted {
                StatCard(title: "Distancia", value: dist, icon: "figure.run", color: .blue)
            }

            if let hr = viewModel.uiState.workout.heartRateFormatted {
                StatCard(title: "FC media", value: hr, icon: "heart.fill", color: .red)
            }
        }
    }

    private var linkSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vincular entrenamiento")
                .font(.headline)

            if let linked = viewModel.uiState.linkedTraining {
                LinkedTrainingRow(training: linked, onUnlink: { viewModel.unlinkTraining() })
            } else if let entry = viewModel.uiState.linkedEntry {
                LinkedEntryRow(
                    entry: entry,
                    onTap: { viewModel.openLinkedEntry() },
                    onUnlink: { viewModel.unlinkEntry() }
                )
            } else if let log = viewModel.uiState.linkedLog {
                LinkedLogRow(
                    log: log,
                    onTap: { viewModel.openLinkedLog() },
                    onUnlink: { viewModel.unlinkLog() }
                )
            } else if hasNoOptions {
                Text("No hay entrenamientos disponibles para este día")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.uiState.availableLogs) { log in
                    AvailableLogRow(log: log, onLink: { viewModel.linkTo(log: log) })
                }
                ForEach(viewModel.uiState.availableEntries) { entry in
                    AvailableEntryRow(entry: entry, onLink: { viewModel.linkTo(entry: entry) })
                }
                ForEach(viewModel.uiState.availableTrainings) { training in
                    AvailableTrainingRow(training: training, onLink: { viewModel.linkTo(training: training) })
                }
            }
        }
    }

    private var hasNoOptions: Bool {
        viewModel.uiState.availableTrainings.isEmpty
            && viewModel.uiState.availableEntries.isEmpty
            && viewModel.uiState.availableLogs.isEmpty
    }
}

// MARK: - Log rows

private struct LinkedLogRow: View {
    let log: WorkoutLog
    let onTap: () -> Void
    let onUnlink: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.green)
                        .frame(width: 50, height: 50)
                        .background(Color.green.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(log.sessionName)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("\(log.exercises.count) ej. · \(log.totalSets) series" + (log.endedAt != nil ? " · \(log.durationFormatted)" : ""))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text("Vinculado")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        .padding(.top, 2)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            UnlinkButton(action: onUnlink)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.green.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

private struct AvailableLogRow: View {
    let log: WorkoutLog
    let onLink: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(log.sessionName).fontWeight(.medium)
                Text("\(log.exercises.count) ej. · \(log.totalSets) series")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            LinkPillButton(action: onLink)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Linked rows

private struct LinkedTrainingRow: View {
    let training: Training
    let onUnlink: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(training.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 2) {
                    Text(training.name).font(.headline).fontWeight(.bold)
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("Vinculado")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
                Spacer()
            }
            UnlinkButton(action: onUnlink)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.green.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

private struct LinkedEntryRow: View {
    let entry: WorkoutEntryByDay
    let onTap: () -> Void
    let onUnlink: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.green)
                        .frame(width: 50, height: 50)
                        .background(Color.green.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.exercisesFormatted)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("\(entry.totalSeriesFormatted) · \(entry.durationFormatted)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text("Vinculado")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        .padding(.top, 2)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            UnlinkButton(action: onUnlink)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.green.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

private struct UnlinkButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "link.badge.minus")
                    .font(.system(size: 13, weight: .semibold))
                Text("Desvincular")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.red.opacity(0.6), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Available rows

private struct AvailableTrainingRow: View {
    let training: Training
    let onLink: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(training.image)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Text(training.name).fontWeight(.medium)
            Spacer()
            LinkPillButton(action: onLink)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct AvailableEntryRow: View {
    let entry: WorkoutEntryByDay
    let onLink: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.green)
                .frame(width: 44, height: 44)
                .background(Color.green.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.exercisesFormatted).fontWeight(.medium)
                Text("\(entry.totalSeriesFormatted) · \(entry.durationFormatted)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            LinkPillButton(action: onLink)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct LinkPillButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "link")
                    .font(.system(size: 12, weight: .bold))
                Text("Vincular")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.green)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

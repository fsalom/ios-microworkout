import SwiftUI

struct WorkoutLogDetailView: View {
    @StateObject var viewModel: WorkoutLogDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.uiState.hasSiblings {
                    SessionDateSelector(
                        date: viewModel.uiState.log.startedAt,
                        canGoBack: viewModel.uiState.canGoBack,
                        canGoForward: viewModel.uiState.canGoForward,
                        position: viewModel.uiState.currentSiblingIndex + 1,
                        total: viewModel.uiState.siblingLogs.count,
                        onBack: { viewModel.goToPreviousSibling() },
                        onForward: { viewModel.goToNextSibling() }
                    )
                }

                Header(
                    log: viewModel.uiState.log,
                    linkedWorkout: viewModel.uiState.linkedHealthWorkout
                )

                if let watch = viewModel.uiState.linkedHealthWorkout {
                    AppleWatchInfoCard(workout: watch)
                }

                ForEach(viewModel.uiState.log.exercises) { exerciseLog in
                    ExerciseSummaryCard(
                        exerciseLog: exerciseLog,
                        previousReference: viewModel.uiState.previousByExerciseId[exerciseLog.exercise.id],
                        isNotesExpanded: viewModel.uiState.expandedNotes.contains(exerciseLog.id),
                        mediaUseCase: viewModel.mediaUseCase,
                        onToggleNotes: { viewModel.toggleNotes(for: exerciseLog.id) },
                        onTapSet: { viewModel.openMediaGallery(setId: $0) }
                    )
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.uiState.log.sessionName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Editar") { viewModel.goToEdit() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive, action: {
                        if viewModel.delete() { dismiss() }
                    }) {
                        Label("Eliminar", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear { viewModel.reloadFromStorage() }
        .onReceive(NotificationCenter.default.publisher(for: .workoutLogsChanged)) { _ in
            viewModel.reloadFromStorage()
        }
        .sheet(item: mediaSheetBinding) { setId in
            NavigationStack {
                SetMediaGalleryView(setId: setId.id, useCase: viewModel.mediaUseCase)
                    .padding()
                    .navigationTitle("Multimedia")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Cerrar") { viewModel.closeMediaGallery() }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var mediaSheetBinding: Binding<IdentifiableUUID?> {
        Binding(
            get: { viewModel.uiState.mediaSheetSetId.map { IdentifiableUUID(id: $0) } },
            set: { if $0 == nil { viewModel.closeMediaGallery() } }
        )
    }
}

private struct IdentifiableUUID: Identifiable, Hashable {
    let id: UUID
}

private struct Header: View {
    let log: WorkoutLog
    let linkedWorkout: HealthWorkout?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(formatDate(log.startedAt).uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .tracking(1)
            HStack(spacing: 12) {
                Stat(value: "\(log.exercises.count)", label: "ejercicios")
                Stat(value: "\(log.totalSets)", label: "series")
                Stat(value: durationValue, label: durationLabel)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    private var durationValue: String {
        if let watch = linkedWorkout {
            return watch.durationFormatted
        }
        return log.endedAt != nil ? log.durationFormatted : "—"
    }

    private var durationLabel: String {
        linkedWorkout != nil ? "duración (Watch)" : "duración"
    }

    private func formatDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Hoy" }
        if cal.isDateInYesterday(date) { return "Ayer" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "EEEE d MMM"
        return formatter.string(from: date)
    }
}

private struct AppleWatchInfoCard: View {
    let workout: HealthWorkout

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "applewatch")
                    .foregroundColor(.green)
                Text(workout.activityTypeName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Spacer()
                Text("VINCULADO")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.15))
                    .clipShape(Capsule())
            }

            Text(workout.timeRangeFormatted)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                if let cal = workout.caloriesFormatted {
                    InfoChip(icon: "flame.fill", text: cal, color: .orange)
                }
                if let hr = workout.heartRateFormatted {
                    InfoChip(icon: "heart.fill", text: hr, color: .red)
                }
                if let dist = workout.distanceFormatted {
                    InfoChip(icon: "figure.run", text: dist, color: .blue)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.green.opacity(0.35), lineWidth: 1)
        )
    }
}

private struct InfoChip: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

private struct Stat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ExerciseSummaryCard: View {
    let exerciseLog: LoggedExercise
    let previousReference: PreviousExerciseReference?
    let isNotesExpanded: Bool
    let mediaUseCase: SetMediaUseCase
    let onToggleNotes: () -> Void
    let onTapSet: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(exerciseLog.exercise.name)
                    .font(.headline)
                Spacer()
                if exerciseLog.notes?.isEmpty == false {
                    Button(action: onToggleNotes) {
                        Image(systemName: "note.text")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }

            if let previousReference {
                PreviousTopSetCard(
                    current: exerciseLog,
                    previous: previousReference.exercise,
                    previousDate: previousReference.date
                )
            }

            if exerciseLog.sets.isEmpty {
                Text("Sin series registradas")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                HStack(spacing: 8) {
                    Text("#").frame(width: 24, alignment: .leading)
                    Text("KG").frame(maxWidth: .infinity)
                    Text("REPS").frame(maxWidth: .infinity)
                    Text("RIR").frame(maxWidth: .infinity)
                    Image(systemName: "photo")
                        .frame(width: 36)
                }
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .tracking(0.5)

                ForEach(Array(exerciseLog.sets.enumerated()), id: \.element.id) { index, set in
                    Button {
                        onTapSet(set.id)
                    } label: {
                        HStack(spacing: 8) {
                            Text("\(index + 1)")
                                .font(.system(size: 15, weight: .bold))
                                .frame(width: 24, alignment: .leading)
                            Text(set.weight.map { format($0) } ?? "—")
                                .frame(maxWidth: .infinity)
                            Text(set.reps.map { String($0) } ?? "—")
                                .frame(maxWidth: .infinity)
                            Text(set.rir.map { format(Double($0)) } ?? "—")
                                .frame(maxWidth: .infinity)
                            DetailMediaIndicator(setId: set.id, useCase: mediaUseCase)
                                .frame(width: 36)
                        }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            if isNotesExpanded, let notes = exerciseLog.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sensaciones")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(notes)
                        .font(.subheadline)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6))
                )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func format(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 { return String(Int(value)) }
        return String(format: "%.1f", value)
    }
}

private struct SessionDateSelector: View {
    let date: Date
    let canGoBack: Bool
    let canGoForward: Bool
    let position: Int
    let total: Int
    let onBack: () -> Void
    let onForward: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(canGoBack ? .accentColor : .secondary.opacity(0.4))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color(.tertiarySystemGroupedBackground)))
            }
            .buttonStyle(.plain)
            .disabled(!canGoBack)

            VStack(spacing: 2) {
                Text(formatDate(date))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("\(position) de \(total)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            Button(action: onForward) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(canGoForward ? .accentColor : .secondary.opacity(0.4))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color(.tertiarySystemGroupedBackground)))
            }
            .buttonStyle(.plain)
            .disabled(!canGoForward)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func formatDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Hoy" }
        if cal.isDateInYesterday(date) { return "Ayer" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "EEE d MMM"
        return formatter.string(from: date).capitalized
    }
}

private struct DetailMediaIndicator: View {
    let setId: UUID
    let useCase: SetMediaUseCase
    @State private var count: Int = 0

    var body: some View {
        Group {
            if count > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.caption2)
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.accentColor))
            } else {
                Image(systemName: "plus.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(.accentColor.opacity(0.55))
            }
        }
        .task(id: setId) {
            await reload()
        }
    }

    private func reload() async {
        do {
            count = try await useCase.getMedia(forSetId: setId).count
        } catch {
            count = 0
        }
    }
}

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
        .fullScreenCover(item: mediaSheetBinding) { setId in
            DirectMediaViewer(
                setId: setId.id,
                useCase: viewModel.mediaUseCase,
                onCompare: { sourceSetId in
                    viewModel.closeMediaGallery()
                    viewModel.goToProgression(sourceSetId: sourceSetId)
                }
            )
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

private struct DirectMediaViewer: View {
    let setId: UUID
    let useCase: SetMediaUseCase
    var onCompare: ((UUID) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var media: [SetMedia]?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let media {
                if media.isEmpty {
                    VStack(spacing: 16) {
                        Text("Sin multimedia")
                            .foregroundColor(.white)
                        Button("Cerrar") { dismiss() }
                            .foregroundColor(.white)
                    }
                } else {
                    SetMediaViewer(
                        media: media,
                        initialIndex: 0,
                        useCase: useCase,
                        onDelete: { item in
                            Task {
                                try? await useCase.delete(item.id)
                                self.media = (try? await useCase.getMedia(forSetId: setId)) ?? []
                            }
                        },
                        onCompare: onCompare
                    )
                }
            } else {
                VStack(spacing: 10) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.large)
                        .tint(.white)
                    Text("Abriendo…")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
        }
        .task {
            do {
                let loaded = try await useCase.getMedia(forSetId: setId)
                media = loaded
                // Kick off preload of the first video as soon as we know what it is,
                // in parallel with the cover's presentation animation (~400ms head start).
                if let firstVideo = loaded.first(where: { $0.type == .video }) {
                    let url = useCase.fileURL(for: firstVideo)
                    Task.detached(priority: .userInitiated) {
                        _ = await VideoPreloader.shared.preload(url)
                    }
                }
            } catch {
                media = []
            }
        }
    }
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

    @State private var mediaBySetId: [UUID: [SetMedia]] = [:]

    /// Sky-blue tone that contrasts with the app's green accent and the orange/red badges.
    static let highlightColor = Color(red: 0.30, green: 0.65, blue: 0.95)

    private func mediaFor(_ setId: UUID) -> [SetMedia] {
        mediaBySetId[setId] ?? []
    }

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
                    Text("#").frame(width: 44, alignment: .leading)
                    Text("KG").frame(maxWidth: .infinity)
                    Text("REPS").frame(maxWidth: .infinity)
                    Text("RIR").frame(maxWidth: .infinity)
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(0.8)
                .padding(.bottom, 2)

                VStack(spacing: 4) {
                    ForEach(Array(exerciseLog.sets.enumerated()), id: \.element.id) { index, set in
                        let setMedia = mediaFor(set.id)
                        let hasMedia = !setMedia.isEmpty

                        let row = VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                HStack(spacing: 6) {
                                    Text("\(index + 1)")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundColor(.primary)
                                        .monospacedDigit()
                                    DetailMediaIndicator(media: setMedia)
                                }
                                .frame(width: 44, alignment: .leading)
                                Text(set.weight.map { format($0) } ?? "—")
                                    .frame(maxWidth: .infinity)
                                Text(set.reps.map { String($0) } ?? "—")
                                    .frame(maxWidth: .infinity)
                                Text(set.rir.map { format(Double($0)) } ?? "—")
                                    .frame(maxWidth: .infinity)
                            }
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                            .monospacedDigit()

                            if !set.tags.isEmpty {
                                HStack(spacing: 6) {
                                    ForEach(set.tags, id: \.self) { tag in
                                        SetTagBadge(tag: tag)
                                    }
                                    Spacer()
                                }
                                .padding(.leading, 44)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .background(
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(hasMedia ? Self.highlightColor.opacity(0.30) : Color.clear)
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(hasMedia ? Self.highlightColor.opacity(0.85) : Color.clear, lineWidth: 1.5)
                                if hasMedia {
                                    UnevenRoundedRectangle(
                                        cornerRadii: .init(topLeading: 10, bottomLeading: 10),
                                        style: .continuous
                                    )
                                    .fill(Self.highlightColor)
                                    .frame(width: 6)
                                }
                            }
                        )
                        .shadow(color: hasMedia ? Self.highlightColor.opacity(0.25) : .clear, radius: 4, x: 0, y: 1)
                        .contentShape(Rectangle())

                        if hasMedia {
                            Button { onTapSet(set.id) } label: { row }
                                .buttonStyle(.plain)
                        } else {
                            row
                        }
                    }
                }
                .task { await loadAllMedia() }
                .onReceive(NotificationCenter.default.publisher(for: .setMediaChanged)) { note in
                    guard let setId = note.object as? UUID else { return }
                    if exerciseLog.sets.contains(where: { $0.id == setId }) {
                        Task { await reload(setId: setId) }
                    }
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

    private func loadAllMedia() async {
        var result: [UUID: [SetMedia]] = [:]
        for set in exerciseLog.sets {
            let items = (try? await mediaUseCase.getMedia(forSetId: set.id)) ?? []
            if !items.isEmpty { result[set.id] = items }
        }
        mediaBySetId = result
        warmVideoCache(for: result)
    }

    private func reload(setId: UUID) async {
        let items = (try? await mediaUseCase.getMedia(forSetId: setId)) ?? []
        if items.isEmpty {
            mediaBySetId[setId] = nil
        } else {
            mediaBySetId[setId] = items
        }
    }

    /// Pre-warms the AVPlayerItem cache for the first video of each set,
    /// so opening the viewer feels instantaneous.
    private func warmVideoCache(for map: [UUID: [SetMedia]]) {
        let firstVideos: [URL] = map.values.compactMap { items in
            items.first(where: { $0.type == .video }).map { mediaUseCase.fileURL(for: $0) }
        }
        guard !firstVideos.isEmpty else { return }
        Task.detached(priority: .userInitiated) {
            await withTaskGroup(of: Void.self) { group in
                for url in firstVideos {
                    group.addTask { _ = await VideoPreloader.shared.preload(url) }
                }
            }
        }
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

struct SetTagBadge: View {
    let tag: SetTag

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: tag.symbol)
                .font(.system(size: 9, weight: .bold))
            Text(tag.shortLabel)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(tag.color)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Capsule().fill(tag.color.opacity(0.18)))
        .overlay(Capsule().strokeBorder(tag.color.opacity(0.5), lineWidth: 0.8))
    }
}

struct DetailMediaIndicator: View {
    let media: [SetMedia]

    var body: some View {
        if media.isEmpty {
            Color.clear.frame(height: 18)
        } else {
            HStack(spacing: 3) {
                let hasVideo = media.contains { $0.type == .video }
                ZStack {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(ExerciseSummaryCard.highlightColor)
                        .frame(width: 16, height: 16)
                    Image(systemName: hasVideo ? "play.fill" : "photo.fill")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white)
                }
                if media.count > 1 {
                    Text("\(media.count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(ExerciseSummaryCard.highlightColor)
                        .monospacedDigit()
                }
            }
            .frame(height: 18)
        }
    }
}

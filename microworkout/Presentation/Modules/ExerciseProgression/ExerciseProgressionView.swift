import SwiftUI

struct ExerciseProgressionView: View {
    @StateObject var viewModel: ExerciseProgressionViewModel

    var body: some View {
        Group {
            if viewModel.uiState.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.uiState.matches.isEmpty {
                emptyState
            } else {
                content
            }
        }
        .navigationTitle("Progresión")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .task { await viewModel.load() }
        .fullScreenCover(item: $viewModel.uiState.viewerIndex) { selection in
            SetMediaViewer(
                media: selection.media,
                initialIndex: selection.initialIndex,
                useCase: selection.useCase
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.uiState.exerciseName)
                .font(.title2)
                .fontWeight(.bold)
            HStack(spacing: 6) {
                Text(criteriaText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(viewModel.uiState.matches.count) vídeo\(viewModel.uiState.matches.count == 1 ? "" : "s")")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.accentColor.opacity(0.15)))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private var criteriaText: String {
        let kg = viewModel.uiState.weight.map { formatNumber($0) } ?? "—"
        let reps = viewModel.uiState.reps.map { String($0) } ?? "—"
        return "\(kg) kg × \(reps) reps"
    }

    private func formatNumber(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 { return String(Int(value)) }
        return String(format: "%.1f", value)
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.uiState.matches) { match in
                        MatchCard(match: match, useCase: viewModel.mediaUseCase)
                            .onTapGesture { viewModel.openViewer(for: match) }
                    }
                }
                .padding(16)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "video.slash")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            Text("No hay otros vídeos")
                .font(.headline)
            Text("Aún no has grabado más series con el mismo peso y reps de este ejercicio.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct MatchCard: View {
    let match: ExerciseProgressionMatch
    let useCase: SetMediaUseCase

    @Environment(\.displayScale) private var displayScale
    @State private var thumbnail: UIImage?

    private var thumbnailURL: URL? {
        guard let first = match.media.first else { return nil }
        return useCase.thumbnailURL(for: first) ?? useCase.fileURL(for: first)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.06)
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                playOverlay
                if match.isCurrent {
                    currentBadge
                        .padding(10)
                }
            }
            .frame(height: 220)
            .clipped()

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(formattedDate)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    if let rir = match.rir {
                        Text("RIR \(formatNumber(Double(rir)))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                if !match.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(match.tags, id: \.self) { tag in
                            SetTagBadge(tag: tag)
                        }
                    }
                }
            }
            .padding(12)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(match.isCurrent ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .task(id: thumbnailURL) {
            guard let url = thumbnailURL else { return }
            thumbnail = await MediaImageLoader.load(
                url: url,
                maxPixelSize: 1400,
                scale: displayScale
            )
        }
    }

    private var playOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white, .black.opacity(0.6))
                    .shadow(radius: 4)
                Spacer()
                if match.media.count > 1 {
                    Text("\(match.media.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.black.opacity(0.6)))
                }
            }
            .padding(12)
        }
    }

    private var currentBadge: some View {
        Text("Actual")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.accentColor))
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "EEEE d MMM yyyy"
        return f.string(from: match.date).capitalized
    }

    private func formatNumber(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 { return String(Int(value)) }
        return String(format: "%.1f", value)
    }
}

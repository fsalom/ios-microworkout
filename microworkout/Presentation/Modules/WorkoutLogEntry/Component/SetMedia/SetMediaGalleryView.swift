import PhotosUI
import SwiftUI

struct SetMediaGalleryView: View {
    let setId: UUID
    let useCase: SetMediaUseCase

    @State private var media: [SetMedia] = []
    @State private var pickerSelection: [PhotosPickerItem] = []
    @State private var viewerOpen: Bool = false
    @State private var isProcessing: Bool = false

    var body: some View {
        Group {
            if media.isEmpty {
                if isProcessing {
                    processingPlaceholder
                } else {
                    emptyState
                }
            } else {
                compactRow
            }
        }
        .task { await load() }
        .onChange(of: pickerSelection) { _, newValue in
            guard !newValue.isEmpty else { return }
            handlePickerSelection(newValue)
        }
        .onReceive(NotificationCenter.default.publisher(for: .setMediaChanged)) { note in
            if let changed = note.object as? UUID, changed == setId {
                Task { await load() }
            }
        }
        .fullScreenCover(isPresented: $viewerOpen) {
            SetMediaViewer(
                media: media,
                initialIndex: 0,
                useCase: useCase,
                onDelete: { item in
                    Task { await deleteSilently(item) }
                }
            )
        }
    }

    private var compactRow: some View {
        HStack(spacing: 8) {
            Button {
                viewerOpen = true
            } label: {
                HStack(spacing: 10) {
                    chip
                    Text(mediaSummary)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    if isProcessing {
                        ProgressView()
                            .controlSize(.mini)
                            .tint(.accentColor)
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .disabled(media.isEmpty)

            PhotosPicker(
                selection: $pickerSelection,
                maxSelectionCount: 10,
                matching: .any(of: [.images, .videos])
            ) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .padding(.vertical, 6)
            }
        }
    }

    @ViewBuilder
    private var chip: some View {
        let hasVideo = media.contains { $0.type == .video }
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color.accentColor)
                .frame(width: 22, height: 22)
            Image(systemName: hasVideo ? "play.fill" : "photo.fill")
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.white)
        }
    }

    private var mediaIconName: String {
        let hasVideo = media.contains { $0.type == .video }
        let hasPhoto = media.contains { $0.type == .photo }
        switch (hasPhoto, hasVideo) {
        case (true, true): return "photo.on.rectangle.angled"
        case (false, true): return "video.fill"
        default: return "photo.fill"
        }
    }

    private var mediaSummary: String {
        let photos = media.filter { $0.type == .photo }.count
        let videos = media.filter { $0.type == .video }.count
        var parts: [String] = []
        if photos > 0 { parts.append("\(photos) foto\(photos == 1 ? "" : "s")") }
        if videos > 0 { parts.append("\(videos) vídeo\(videos == 1 ? "" : "s")") }
        return parts.joined(separator: " · ")
    }

    private var processingPlaceholder: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
                .tint(.accentColor)
            Text("Procesando archivo…")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var emptyState: some View {
        PhotosPicker(
            selection: $pickerSelection,
            maxSelectionCount: 10,
            matching: .any(of: [.images, .videos])
        ) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.accentColor)
                        .frame(width: 32, height: 32)
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Añadir foto o vídeo")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text("Elige de la galería")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func load() async {
        do {
            media = try await useCase.getMedia(forSetId: setId)
        } catch {
            media = []
        }
    }

    private func handlePickerSelection(_ items: [PhotosPickerItem]) {
        let setId = self.setId
        let useCase = self.useCase
        // Detach so the work survives if the parent screen dismisses before it finishes.
        Task.detached(priority: .userInitiated) {
            for item in items {
                do {
                    if let movie = try await item.loadTransferable(type: VideoTransferable.self) {
                        let jobId = MediaProcessingTracker.shared.begin(.video)
                        defer { MediaProcessingTracker.shared.end(jobId) }
                        _ = try await useCase.addVideo(setId: setId, sourceURL: movie.url)
                    } else if let data = try await item.loadTransferable(type: Data.self),
                              UIImage(data: data) != nil {
                        let jobId = MediaProcessingTracker.shared.begin(.photo)
                        defer { MediaProcessingTracker.shared.end(jobId) }
                        _ = try await useCase.addPhoto(setId: setId, imageData: data)
                    }
                } catch {}
            }
        }
        // Clear local selection state immediately so the picker is ready for next use.
        pickerSelection = []
        isProcessing = false
    }

    private func deleteSilently(_ item: SetMedia) async {
        do {
            try await useCase.delete(item.id)
            await load()
        } catch {}
    }
}

struct VideoTransferable: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { transferable in
            SentTransferredFile(transferable.url)
        } importing: { received in
            let ext = received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension
            let cacheURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(UUID().uuidString).\(ext)")
            if FileManager.default.fileExists(atPath: cacheURL.path) {
                try FileManager.default.removeItem(at: cacheURL)
            }
            try FileManager.default.copyItem(at: received.file, to: cacheURL)
            return Self(url: cacheURL)
        }
    }
}

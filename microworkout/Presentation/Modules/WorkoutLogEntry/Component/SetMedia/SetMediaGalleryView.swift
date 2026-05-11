import PhotosUI
import SwiftUI

struct SetMediaGalleryView: View {
    let setId: UUID
    let useCase: SetMediaUseCase

    @State private var media: [SetMedia] = []
    @State private var cameraMode: CameraSheet? = nil
    @State private var showLibraryPicker: Bool = false
    @State private var libraryItem: PhotosPickerItem? = nil
    @State private var viewerIndex: ViewerPresentation? = nil
    @State private var mediaToDelete: SetMedia? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Multimedia")
                    .font(.headline)
                Spacer()
                if !media.isEmpty {
                    Text("\(media.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if media.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        addButton

                        ForEach(Array(media.enumerated()), id: \.element.id) { index, item in
                            Button {
                                viewerIndex = ViewerPresentation(index: index)
                            } label: {
                                SetMediaThumbnail(
                                    media: item,
                                    imageURL: useCase.thumbnailURL(for: item) ?? useCase.fileURL(for: item)
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    mediaToDelete = item
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .frame(height: 88)
            }
        }
        .task { await load() }
        .sheet(item: $cameraMode) { sheet in
            CameraPicker(
                mode: sheet.mode,
                onPicked: { result in
                    cameraMode = nil
                    Task { await handleCameraResult(result) }
                },
                onCancel: { cameraMode = nil }
            )
            .ignoresSafeArea()
        }
        .photosPicker(
            isPresented: $showLibraryPicker,
            selection: $libraryItem,
            matching: .any(of: [.images, .videos])
        )
        .onChange(of: libraryItem) { _, newValue in
            guard let newValue else { return }
            Task { await handleLibraryItem(newValue) }
        }
        .fullScreenCover(item: $viewerIndex) { presentation in
            SetMediaViewer(
                media: media,
                initialIndex: presentation.index,
                useCase: useCase
            )
        }
        .alert(
            "¿Eliminar este archivo?",
            isPresented: Binding(
                get: { mediaToDelete != nil },
                set: { if !$0 { mediaToDelete = nil } }
            ),
            presenting: mediaToDelete
        ) { item in
            Button("Eliminar", role: .destructive) {
                Task { await delete(item) }
            }
            Button("Cancelar", role: .cancel) {}
        }
    }

    private var addMenu: some View {
        Group {
            Button {
                cameraMode = CameraSheet(mode: .photo)
            } label: {
                Label("Hacer foto", systemImage: "camera")
            }
            Button {
                cameraMode = CameraSheet(mode: .video)
            } label: {
                Label("Grabar vídeo", systemImage: "video")
            }
            Button {
                showLibraryPicker = true
            } label: {
                Label("Elegir de la galería", systemImage: "photo.on.rectangle")
            }
        }
    }

    /// Compact "+" button shown next to existing thumbnails.
    private var addButton: some View {
        Menu {
            addMenu
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.title2)
                Text("Añadir")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .frame(width: 80, height: 80)
            .background(Color.accentColor.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.accentColor.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [4]))
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .foregroundColor(.accentColor)
        }
    }

    /// Large CTA shown when there are no media items yet.
    private var emptyState: some View {
        Menu {
            addMenu
        } label: {
            VStack(spacing: 10) {
                Image(systemName: "camera.fill")
                    .font(.title)
                Text("Añadir foto o vídeo")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("Graba la técnica de la serie")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.accentColor.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.accentColor.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [5]))
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .foregroundColor(.accentColor)
        }
    }

    private func load() async {
        do {
            media = try await useCase.getMedia(forSetId: setId)
        } catch {
            media = []
        }
    }

    private func handleCameraResult(_ result: CameraPicker.Result) async {
        do {
            switch result {
            case .photo(let image):
                _ = try await useCase.addPhoto(setId: setId, image: image)
            case .video(let url):
                _ = try await useCase.addVideo(setId: setId, sourceURL: url)
            }
            await load()
        } catch {}
    }

    private func handleLibraryItem(_ item: PhotosPickerItem) async {
        defer { libraryItem = nil }
        do {
            if let movie = try await item.loadTransferable(type: VideoTransferable.self) {
                _ = try await useCase.addVideo(setId: setId, sourceURL: movie.url)
            } else if let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) {
                _ = try await useCase.addPhoto(setId: setId, image: image)
            }
            await load()
        } catch {}
    }

    private func delete(_ item: SetMedia) async {
        mediaToDelete = nil
        do {
            try await useCase.delete(item.id)
            await load()
        } catch {}
    }
}

private struct CameraSheet: Identifiable {
    let mode: CameraPicker.CaptureMode
    var id: String {
        switch mode {
        case .photo: return "photo"
        case .video: return "video"
        }
    }
}

private struct ViewerPresentation: Identifiable {
    let index: Int
    var id: Int { index }
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

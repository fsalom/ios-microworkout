import SwiftUI

/// Variante de `SetMediaViewer` que carga el contenido de manera asíncrona dado un `setId`.
/// Muestra estados de carga y vacío. Internamente delega el renderizado a `SetMediaViewer`.
struct AsyncSetMediaViewer: View {
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
                // Precarga el primer vídeo en paralelo con la animación de presentación
                // (~400ms head start) para reducir latencia perceptible.
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

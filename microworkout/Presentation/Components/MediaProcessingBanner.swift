import SwiftUI

/// Tracks media processing jobs (compress + write) that may outlive the screen
/// that started them, so we can show a global "Procesando vídeo…" banner.
final class MediaProcessingTracker: ObservableObject {
    static let shared = MediaProcessingTracker()

    enum Kind { case photo, video }

    struct Job: Identifiable {
        let id: UUID
        let kind: Kind
    }

    @Published private(set) var jobs: [Job] = []

    private init() {}

    @discardableResult
    func begin(_ kind: Kind) -> UUID {
        let id = UUID()
        DispatchQueue.main.async { [weak self] in
            self?.jobs.append(Job(id: id, kind: kind))
        }
        return id
    }

    func end(_ id: UUID) {
        DispatchQueue.main.async { [weak self] in
            self?.jobs.removeAll { $0.id == id }
        }
    }
}

/// Floating pill shown over the root view while there are in-flight media jobs.
struct MediaProcessingBanner: View {
    @ObservedObject private var tracker = MediaProcessingTracker.shared

    var body: some View {
        VStack {
            Spacer()
            if !tracker.jobs.isEmpty {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                    Text(message)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(Capsule().fill(Color.black.opacity(0.88)))
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                .padding(.bottom, 28)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .allowsHitTesting(false)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: tracker.jobs.count)
    }

    private var message: String {
        let videos = tracker.jobs.filter { $0.kind == .video }.count
        let photos = tracker.jobs.filter { $0.kind == .photo }.count
        if videos > 0 && photos == 0 {
            return videos == 1 ? "Procesando vídeo…" : "Procesando \(videos) vídeos…"
        }
        if photos > 0 && videos == 0 {
            return photos == 1 ? "Procesando foto…" : "Procesando \(photos) fotos…"
        }
        return "Procesando archivos…"
    }
}

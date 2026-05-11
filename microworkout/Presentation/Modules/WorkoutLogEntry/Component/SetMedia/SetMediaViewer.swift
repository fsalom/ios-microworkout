import AVKit
import SwiftUI

struct SetMediaViewer: View {
    let media: [SetMedia]
    let initialIndex: Int
    let useCase: SetMediaUseCase
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int

    init(media: [SetMedia], initialIndex: Int, useCase: SetMediaUseCase) {
        self.media = media
        self.initialIndex = initialIndex
        self.useCase = useCase
        _currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(media.enumerated()), id: \.element.id) { index, item in
                    page(for: item)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white, .black.opacity(0.5))
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func page(for item: SetMedia) -> some View {
        switch item.type {
        case .photo:
            if let image = UIImage(contentsOfFile: useCase.fileURL(for: item).path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                missingPlaceholder
            }
        case .video:
            VideoPlayer(player: AVPlayer(url: useCase.fileURL(for: item)))
                .ignoresSafeArea()
        }
    }

    private var missingPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
            Text("No se pudo cargar el archivo")
        }
        .foregroundColor(.white)
    }
}

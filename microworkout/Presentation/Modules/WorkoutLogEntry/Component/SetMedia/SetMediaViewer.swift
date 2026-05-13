import AVKit
import Combine
import SwiftUI

struct SetMediaViewer: View {
    let media: [SetMedia]
    let initialIndex: Int
    let useCase: SetMediaUseCase
    var onDelete: ((SetMedia) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var items: [SetMedia]
    @State private var currentIndex: Int
    @State private var dragOffset: CGFloat = 0
    @State private var backgroundOpacity: Double = 1
    @State private var showDeleteConfirm: Bool = false

    init(
        media: [SetMedia],
        initialIndex: Int,
        useCase: SetMediaUseCase,
        onDelete: ((SetMedia) -> Void)? = nil
    ) {
        self.media = media
        self.initialIndex = initialIndex
        self.useCase = useCase
        self.onDelete = onDelete
        _items = State(initialValue: media)
        _currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black
                .opacity(backgroundOpacity)
                .ignoresSafeArea()

            GeometryReader { geo in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            page(for: item, isCurrent: index == currentIndex)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .id(index)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: scrollPositionBinding)
                .offset(y: dragOffset)
            }

            topBar
        }
        .statusBarHidden(true)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    let translation = value.translation.height
                    guard translation > 0,
                          abs(translation) > abs(value.translation.width) else { return }
                    dragOffset = translation
                    backgroundOpacity = max(0.3, 1 - Double(translation / 500))
                }
                .onEnded { value in
                    if value.translation.height > 120 {
                        dismiss()
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            dragOffset = 0
                            backgroundOpacity = 1
                        }
                    }
                }
        )
        .alert("¿Eliminar este archivo?", isPresented: $showDeleteConfirm) {
            Button("Eliminar", role: .destructive) {
                deleteCurrent()
            }
            Button("Cancelar", role: .cancel) {}
        }
    }

    private var topBar: some View {
        VStack {
            HStack {
                if items.count > 1 {
                    Text("\(min(currentIndex, items.count - 1) + 1) / \(items.count)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.black.opacity(0.55)))
                        .padding(.leading, 16)
                }
                Spacer()
                if onDelete != nil {
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(Color.black.opacity(0.55)))
                    }
                    .padding(.trailing, 8)
                }
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Circle().fill(Color.black.opacity(0.55)))
                }
                .padding(.trailing, 16)
            }
            .padding(.top, 8)
            Spacer()
        }
    }

    private var scrollPositionBinding: Binding<Int?> {
        Binding(
            get: { currentIndex },
            set: { newValue in
                if let newValue, newValue != currentIndex {
                    currentIndex = newValue
                }
            }
        )
    }

    @ViewBuilder
    private func page(for item: SetMedia, isCurrent: Bool) -> some View {
        switch item.type {
        case .photo:
            ZoomablePhoto(url: useCase.fileURL(for: item))
        case .video:
            FullScreenVideoPlayer(
                url: useCase.fileURL(for: item),
                thumbnailURL: useCase.thumbnailURL(for: item),
                isActive: isCurrent
            )
        }
    }

    private func deleteCurrent() {
        guard currentIndex < items.count else { return }
        let removed = items[currentIndex]
        items.remove(at: currentIndex)
        onDelete?(removed)

        if items.isEmpty {
            dismiss()
        } else if currentIndex >= items.count {
            currentIndex = items.count - 1
        }
    }
}

// MARK: - Zoomable photo

private struct ZoomablePhoto: View {
    let url: URL

    @State private var image: UIImage?
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(zoomGesture)
                        .simultaneousGesture(panGesture)
                        .onTapGesture(count: 2) { toggleZoom() }
                } else {
                    VStack(spacing: 10) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .controlSize(.large)
                            .tint(.white)
                        Text("Cargando foto…")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .task(id: url) {
            await loadImage()
        }
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = max(1, min(lastScale * value, 5))
            }
            .onEnded { _ in
                lastScale = scale
                if scale <= 1.01 {
                    withAnimation(.spring()) {
                        scale = 1
                        lastScale = 1
                        offset = .zero
                        lastOffset = .zero
                    }
                }
            }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else { return }
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private func toggleZoom() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            if scale > 1 {
                scale = 1
                lastScale = 1
                offset = .zero
                lastOffset = .zero
            } else {
                scale = 2.5
                lastScale = 2.5
            }
        }
    }

    private func loadImage() async {
        image = await MediaImageLoader.load(url: url, maxPixelSize: 4000)
    }
}

// MARK: - Video player

private struct FullScreenVideoPlayer: View {
    let url: URL
    let thumbnailURL: URL?
    let isActive: Bool

    @Environment(\.displayScale) private var displayScale
    @State private var player: AVPlayer?
    @State private var thumbnail: UIImage?
    @State private var isReadyToShow: Bool = false
    @State private var statusObserver: AnyCancellable?

    var body: some View {
        ZStack {
            Color.black

            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .opacity(isReadyToShow ? 0 : 1)
            }

            if let player, isActive {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .opacity(isReadyToShow ? 1 : 0)
            }

            if !isReadyToShow {
                ZStack {
                    Color.black.opacity(thumbnail == nil ? 0 : 0.35)
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .controlSize(.large)
                            .tint(.white)
                        Text("Cargando vídeo…")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
                .transition(.opacity)
            }
        }
        .task(id: thumbnailURL) {
            guard let thumbnailURL else { return }
            thumbnail = await MediaImageLoader.load(
                url: thumbnailURL,
                maxPixelSize: 1600,
                scale: displayScale
            )
        }
        .onChange(of: isActive, initial: true) { _, active in
            if active {
                Task { await ensurePlayer() }
            } else {
                tearDownPlayer()
            }
        }
        .onDisappear {
            tearDownPlayer()
        }
    }

    private func ensurePlayer() async {
        if let existing = player {
            await existing.seek(to: .zero)
            existing.play()
            return
        }
        let url = self.url

        let item: AVPlayerItem
        if let cached = await VideoPreloader.shared.consume(url) {
            item = cached
        } else {
            item = await VideoPreloader.shared.preload(url)
        }

        guard isActive else { return }

        let p = AVPlayer(playerItem: item)
        p.actionAtItemEnd = .pause
        p.automaticallyWaitsToMinimizeStalling = false

        self.player = p
        observeReadiness(for: p)
    }

    private func observeReadiness(for player: AVPlayer) {
        guard let item = player.currentItem else { return }
        statusObserver = item
            .publisher(for: \.status)
            .receive(on: RunLoop.main)
            .sink { status in
                guard status == .readyToPlay else { return }
                // Preroll the decode pipeline before play so the first frame is ready.
                player.preroll(atRate: 1) { _ in
                    DispatchQueue.main.async {
                        player.seek(to: .zero)
                        player.play()
                        withAnimation(.easeOut(duration: 0.18)) {
                            isReadyToShow = true
                        }
                    }
                }
            }
    }

    private func tearDownPlayer() {
        statusObserver?.cancel()
        statusObserver = nil
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        isReadyToShow = false
    }
}

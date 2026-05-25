import Foundation
import SwiftUI

struct ExerciseProgressionUiState {
    var matches: [ExerciseProgressionMatch] = []
    var isLoading: Bool = true
    var exerciseName: String = ""
    var weight: Double?
    var reps: Int?
    var viewerIndex: ViewerSelection?
}

struct ViewerSelection: Identifiable, Equatable {
    let id = UUID()
    let media: [SetMedia]
    let initialIndex: Int
    let useCase: SetMediaUseCase

    static func == (lhs: ViewerSelection, rhs: ViewerSelection) -> Bool {
        lhs.id == rhs.id
    }
}

final class ExerciseProgressionViewModel: ObservableObject {
    @Published var uiState = ExerciseProgressionUiState()

    let mediaUseCase: SetMediaUseCase
    private let progressionUseCase: ExerciseProgressionUseCaseProtocol
    private let sourceSetId: UUID
    private let router: ExerciseProgressionRouter

    init(
        sourceSetId: UUID,
        progressionUseCase: ExerciseProgressionUseCaseProtocol,
        mediaUseCase: SetMediaUseCase,
        router: ExerciseProgressionRouter
    ) {
        self.sourceSetId = sourceSetId
        self.progressionUseCase = progressionUseCase
        self.mediaUseCase = mediaUseCase
        self.router = router
    }

    func close() {
        router.goBack()
    }

    func load() async {
        await MainActor.run { uiState.isLoading = true }
        let matches = await progressionUseCase.videoMatches(forSetId: sourceSetId)
        await MainActor.run {
            uiState.matches = matches
            if let first = matches.first {
                uiState.exerciseName = first.exerciseName
                uiState.weight = first.weight
                uiState.reps = first.reps
            }
            uiState.isLoading = false
        }
    }

    func openViewer(for match: ExerciseProgressionMatch) {
        guard !match.media.isEmpty else { return }
        uiState.viewerIndex = ViewerSelection(
            media: match.media,
            initialIndex: 0,
            useCase: mediaUseCase
        )
    }

    func closeViewer() {
        uiState.viewerIndex = nil
    }
}

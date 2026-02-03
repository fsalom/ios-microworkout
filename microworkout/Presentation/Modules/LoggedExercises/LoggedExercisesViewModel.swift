import Foundation
import SwiftUI

struct LoggedExercisesUiState {
    var entryDay: WorkoutEntryByDay
    var error: String?
}

final class LoggedExercisesViewModel: ObservableObject {
    @Published var uiState: LoggedExercisesUiState
    private var router: LoggedExercisesRouter
    private var exerciseUseCase: ExerciseUseCaseProtocol
    private var workoutEntryUseCase: WorkoutEntryUseCaseProtocol

    init(router: LoggedExercisesRouter,
         exerciseUseCase: ExerciseUseCaseProtocol,
         workoutEntryUseCase: WorkoutEntryUseCaseProtocol,
         entryDay: WorkoutEntryByDay) {
        self.uiState = .init(entryDay: entryDay, error: nil)
        self.router = router
        self.exerciseUseCase = exerciseUseCase
        self.workoutEntryUseCase = workoutEntryUseCase
    }

    func groupedByExercise() -> [Exercise: [WorkoutEntry]] {
        workoutEntryUseCase.groupByExercise(these: self.uiState.entryDay.entries)
    }

    func orderedExercises() -> [Exercise] {
        workoutEntryUseCase.order(these: self.uiState.entryDay.entries)
    }

    func delete() {
        Task {
            try await workoutEntryUseCase.deleteEntries(for: uiState.entryDay)
            router.comeBack()
        }
    }
}

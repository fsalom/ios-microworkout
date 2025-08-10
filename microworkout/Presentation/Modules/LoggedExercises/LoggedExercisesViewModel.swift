import Foundation
import SwiftUICore

struct LoggedExercisesUiState {
    var loggedExercises: LoggedExerciseByDay
    var error: String?
}

final class LoggedExercisesViewModel: ObservableObject {
    @Published var uiState: LoggedExercisesUiState
    private var router: LoggedExercisesRouter
    private var loggedExerciseUseCase: LoggedExerciseUseCase

    init(router: LoggedExercisesRouter,
         loggedExerciseUseCase: LoggedExerciseUseCase,
         loggedExercises: LoggedExerciseByDay) {
        self.uiState = .init(loggedExercises: loggedExercises, error: nil)
        self.router = router
        self.loggedExerciseUseCase = loggedExerciseUseCase
    }

    func groupedByExercise() -> [Exercise: [LoggedExercise]] {
        self.loggedExerciseUseCase.groupByExercise(these: self.uiState.loggedExercises.exercises)
    }

    func orderedExercises() -> [Exercise] {
        self.loggedExerciseUseCase.order(these: self.uiState.loggedExercises.exercises)
    }

    func delete() {
        Task {
            try await self.loggedExerciseUseCase.delete(this: uiState.loggedExercises)
            self.router.comeBack()
        }
    }
}

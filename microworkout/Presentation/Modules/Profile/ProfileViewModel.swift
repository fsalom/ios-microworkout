import SwiftUI
import Combine

class ProfileViewModel: ObservableObject {
    private var exerciseUseCase: ExerciseUseCaseProtocol
    private var workoutEntryUseCase: WorkoutEntryUseCaseProtocol

init(exerciseUseCase: ExerciseUseCaseProtocol,
     workoutEntryUseCase: WorkoutEntryUseCaseProtocol) {
    self.exerciseUseCase = exerciseUseCase
    self.workoutEntryUseCase = workoutEntryUseCase
}

    
}

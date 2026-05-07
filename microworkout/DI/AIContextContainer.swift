import Foundation

class AIContextContainer {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func makeUseCase() -> AIContextUseCaseProtocol {
        return AIContextUseCase(
            userProfileUseCase: UserProfileContainer(component: component).makeUseCase(),
            workoutLogUseCase: WorkoutLogContainer(component: component).makeUseCase(),
            workoutEntryUseCase: WorkoutEntryContainer(component: component).makeUseCase(),
            mealUseCase: MealContainer(component: component).makeUseCase(),
            healthUseCase: HealthContainer(component: component).makeUseCase()
        )
    }
}

//
//  MealContainer.swift
//  microworkout
//

import Foundation

/// Contenedor de dependencias para casos de uso de comidas.
class MealContainer {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func makeUseCase() -> MealUseCase {
        let storage = component.makeUserDefaultsManager()
        let localDataSource = MealLocalDataSource(storage: storage)
        let remoteApi = OpenFoodFactsApi()
        let repository = MealRepository(
            localDataSource: localDataSource,
            remoteApi: remoteApi
        )
        return MealUseCase(repository: repository)
    }
}

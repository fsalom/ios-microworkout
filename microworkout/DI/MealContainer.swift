//
//  MealContainer.swift
//  microworkout
//

import Foundation

/// Contenedor de dependencias para casos de uso de comidas.
class MealContainer {
    func makeUseCase() -> MealUseCase {
        let storage = UserDefaultsManager()
        let localDataSource = MealLocalDataSource(storage: storage)
        let remoteApi = OpenFoodFactsApi()
        let repository = MealRepository(
            localDataSource: localDataSource,
            remoteApi: remoteApi
        )
        return MealUseCase(repository: repository)
    }
}

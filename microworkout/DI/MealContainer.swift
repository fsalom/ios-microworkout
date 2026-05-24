//
//  MealContainer.swift
//  microworkout
//

import Foundation

// AppComponentProtocol es accesible desde aquí (está en DI/AppComponentProtocol.swift)

/// Contenedor de dependencias para casos de uso de comidas.
class MealContainer {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func makeUseCase() -> MealUseCase {
        let localDataSource = MealLocalDataSource(storage: component.makeUserDefaultsManager())
        let remoteApi = OpenFoodFactsApi()
        let repository = MealRepository(
            localDataSource: localDataSource,
            remoteApi: remoteApi
        )
        return MealUseCase(repository: repository)
    }
}

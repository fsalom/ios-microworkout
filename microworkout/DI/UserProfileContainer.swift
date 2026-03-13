//
//  UserProfileContainer.swift
//  microworkout
//

import Foundation

/// Contenedor de dependencias para casos de uso del perfil de usuario.
class UserProfileContainer {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func makeUseCase() -> UserProfileUseCase {
        let storage = component.makeUserDefaultsManager()
        let localDataSource = UserLocalDataSource(storage: storage)
        let repository = UserProfileRepository(localDataSource: localDataSource)
        return UserProfileUseCase(repository: repository)
    }
}

//
//  UserProfileContainer.swift
//  microworkout
//

import Foundation

/// Contenedor de dependencias para casos de uso del perfil de usuario.
class UserProfileContainer {
    func makeUseCase() -> UserProfileUseCase {
        let storage = UserDefaultsManager()
        let localDataSource = UserLocalDataSource(storage: storage)
        let repository = UserProfileRepository(localDataSource: localDataSource)
        return UserProfileUseCase(repository: repository)
    }
}

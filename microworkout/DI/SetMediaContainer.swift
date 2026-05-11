import Foundation

class SetMediaContainer {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func makeUseCase() -> SetMediaUseCase {
        let storage = component.makeUserDefaultsManager()
        let localDataSource = SetMediaLocalDataSource(storage: storage)
        let repository = SetMediaRepository(localDataSource: localDataSource)
        return SetMediaUseCase(repository: repository)
    }
}

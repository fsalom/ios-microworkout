import Foundation

/// Implementación por defecto del contenedor de dependencias.
/// Esta implementación es deliberadamente simple: crea instancias concretas.
/// Está pensada para reemplazarse en tests o para extender las provisiones.
struct DefaultAppComponent: AppComponentProtocol {
    init() {}

    func makeUserDefaultsManager() -> UserDefaultsManagerProtocol {
        return UserDefaultsManager()
    }

    func makeHealthKitManager() -> HealthKitManagerProtocol {
        return HealthKitManager()
    }
}

extension DefaultAppComponent {
    static let preview = DefaultAppComponent()
}

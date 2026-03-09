import Foundation

/// Protocolo que expone proveedores mínimos de dependencias.
protocol AppComponentProtocol {
    func makeUserDefaultsManager() -> UserDefaultsManagerProtocol
    func makeHealthKitManager() -> HealthKitManagerProtocol
}

/// Implementación por defecto del contenedor de dependencias.
/// Esta implementación es deliberadamente simple: crea instancias concretas.
/// Está pensada para reemplazarse en tests o para extender las provisiones.
struct DefaultAppComponent: AppComponentProtocol {
    func makeUserDefaultsManager() -> UserDefaultsManagerProtocol {
        return UserDefaultsManager()
    }

    func makeHealthKitManager() -> HealthKitManagerProtocol {
        return HealthKitManager()
    }
}

import Foundation

/// Protocolo que expone proveedores mínimos de dependencias.
protocol AppComponentProtocol {
    func makeUserDefaultsManager() -> UserDefaultsManagerProtocol
    func makeHealthKitManager() -> HealthKitManagerProtocol
}

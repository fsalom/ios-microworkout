// Proposal: Extensión de AppComponent para proveer HealthKit y UserDefaults
// Este archivo es una propuesta. No modifica archivos existentes; muestra el cambio mínimo recomendado.

import Foundation

// AppComponent actualizado: añade un proveedor de HealthKitManagerProtocol.
// Reemplaza o extiende el AppComponentProtocol actual en una migración incremental.
protocol AppComponentProtocol {
    func makeUserDefaultsManager() -> UserDefaultsManagerProtocol
    func makeHealthKitManager() -> HealthKitManagerProtocol
}

// Implementación por defecto que devuelve las implementaciones concretas.
// Usa UserDefaultsManager ya existente y el singleton HealthKitManager.
struct DefaultAppComponent: AppComponentProtocol {
    func makeUserDefaultsManager() -> UserDefaultsManagerProtocol {
        return UserDefaultsManager()
    }

    func makeHealthKitManager() -> HealthKitManagerProtocol {
        return HealthKitManager()
    }
}

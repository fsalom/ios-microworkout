import UIKit
import UserNotifications

/// Lo que el sistema pone de su parte: permiso y registro en APNs.
///
/// Como protocolo para que el use case se pueda testear sin UIKit ni diálogos:
/// en tests se sustituye por un doble que concede o deniega.
protocol SystemPushRegistrarProtocol {
    /// Pide el permiso de notificaciones. `true` = concedido.
    func requestAuthorization() async -> Bool
    /// `true` si el permiso ya está concedido (sin preguntar).
    func isAuthorized() async -> Bool
    /// Pide a APNs un token para este dispositivo; llega por el AppDelegate.
    func registerWithAPNs() async
}

struct SystemPushRegistrar: SystemPushRegistrarProtocol {
    func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func isAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    func registerWithAPNs() async {
        await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
    }
}

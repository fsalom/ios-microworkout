import UIKit
import UserNotifications

/// Callbacks de UIKit que SwiftUI no expone: el token de APNs y la presentación
/// de notificaciones con la app abierta.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // El token viaja en hex, que es como lo espera el backend.
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        PushTokenRelay.shared.receive(token)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // Simulador o sin red: los avisos simplemente no se activan.
        print("APNs no dio token: \(error.localizedDescription)")
    }

    /// Con la app abierta, el aviso se enseña igual: el cierre del día a las 21h
    /// con la app en primer plano es el mismo aviso, no uno que perderse.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}

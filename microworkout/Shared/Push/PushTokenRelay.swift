import Foundation

/// Puente entre el AppDelegate y el resto de la app para el token de APNs.
///
/// El token llega por un callback de UIKit en el AppDelegate, que no conoce el
/// grafo de dependencias; quien lo necesita (el use case de avisos) vive dentro
/// de él. Este relé desacopla a los dos: el AppDelegate deposita, el use case
/// recoge — y si el token llega antes de que nadie escuche, queda guardado.
final class PushTokenRelay {
    static let shared = PushTokenRelay()

    private(set) var lastToken: String?
    var onToken: ((String) -> Void)?

    func receive(_ token: String) {
        lastToken = token
        onToken?(token)
    }
}

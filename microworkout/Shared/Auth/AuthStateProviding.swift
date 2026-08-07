import Foundation

/// Quién decide si hay sesión iniciada.
///
/// Existe para que los repositorios no lean `AuthSession.shared` directamente.
/// Ese singleton es estado global compartido por toda la app y, en los tests —que
/// corren en PARALELO—, un test que lo cambia hace fallar a otro que se estaba
/// ejecutando a la vez: el fallo aparece en una clase que no tiene nada que ver y
/// no hay forma de deducir la causa. Inyectándolo, cada test trae el suyo y no hay
/// nada compartido que romper.
///
/// En producción no cambia nada: el valor por defecto sigue siendo la sesión real.
protocol AuthStateProviding: Sendable {
    var isAuthenticated: Bool { get async }
}

/// La sesión de verdad de la app.
struct SharedAuthState: AuthStateProviding {
    var isAuthenticated: Bool {
        get async { await MainActor.run { AuthSession.shared.state.isAuthenticated } }
    }
}

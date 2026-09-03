import Foundation

/// Los avisos proactivos del coach: el interruptor y la fontanería del token.
///
/// El estado real vive en dos sitios que no controlamos del todo: el permiso del
/// sistema (revocable desde Ajustes) y el token de APNs (rota cuando quiere).
/// Este use case reconcilia ambos con la preferencia del usuario, que es lo único
/// nuestro: encendido → registrado en la cuenta; apagado → de baja.
protocol CoachBriefsUseCaseProtocol {
    var isEnabled: Bool { get }
    /// Enciende los avisos. `false` = el sistema denegó el permiso: el llamador
    /// debe decir que se activan en Ajustes.
    func enable() async -> Bool
    func disable() async
    /// El token de APNs acaba de llegar (o rotar): se registra si toca.
    func handleToken(_ token: String) async
    /// Al arrancar: si están encendidos y el permiso sigue, refresca el token
    /// (APNs puede rotarlo y el registro caducaría en silencio).
    func refreshOnLaunch() async
}

final class CoachBriefsUseCase: CoachBriefsUseCaseProtocol {
    private static let enabledKey = "coachBriefs.enabled"

    private let repository: DeviceRepositoryProtocol
    private let registrar: SystemPushRegistrarProtocol
    private let storage: UserDefaultsManagerProtocol
    private let relay: PushTokenRelay

    init(
        repository: DeviceRepositoryProtocol,
        registrar: SystemPushRegistrarProtocol,
        storage: UserDefaultsManagerProtocol,
        relay: PushTokenRelay = .shared
    ) {
        self.repository = repository
        self.registrar = registrar
        self.storage = storage
        self.relay = relay
    }

    var isEnabled: Bool {
        storage.get(forKey: Self.enabledKey) ?? false
    }

    func enable() async -> Bool {
        guard await registrar.requestAuthorization() else { return false }
        storage.save(true, forKey: Self.enabledKey)
        // Si APNs ya nos dio token (p. ej. en un arranque anterior), se registra
        // ya; si no, llegará por el AppDelegate y `handleToken` lo recogerá.
        await registrar.registerWithAPNs()
        if let token = relay.lastToken {
            try? await repository.register(token: token)
        }
        return true
    }

    func disable() async {
        storage.save(false, forKey: Self.enabledKey)
        if let token = relay.lastToken {
            // `try?`: sin red, el token queda huérfano en el servidor hasta que
            // APNs lo declare muerto (410) y el backend lo pode. Aceptable.
            try? await repository.remove(token: token)
        }
    }

    func handleToken(_ token: String) async {
        guard isEnabled else { return }
        try? await repository.register(token: token)
    }

    func refreshOnLaunch() async {
        guard isEnabled, await registrar.isAuthorized() else { return }
        await registrar.registerWithAPNs()
    }
}

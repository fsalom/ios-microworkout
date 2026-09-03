import XCTest
@testable import microworkout

/// El interruptor de los avisos y la fontanería del token de APNs.
///
/// Lo delicado: el token llega por un callback de UIKit CUANDO APNs quiere —
/// antes o después de que el usuario encienda los avisos, y rotando sin avisar.
/// Estos tests fijan que el registro en la cuenta ocurre exactamente cuando debe:
/// encendido y con permiso, ni una vez más.
final class CoachBriefsTests: XCTestCase {

    private final class SpyDeviceRepository: DeviceRepositoryProtocol {
        private(set) var registered: [String] = []
        private(set) var removed: [String] = []
        func register(token: String) async throws { registered.append(token) }
        func remove(token: String) async throws { removed.append(token) }
    }

    private final class StubRegistrar: SystemPushRegistrarProtocol {
        var grantsPermission = true
        var alreadyAuthorized = false
        private(set) var apnsRegistrations = 0
        func requestAuthorization() async -> Bool { grantsPermission }
        func isAuthorized() async -> Bool { alreadyAuthorized }
        func registerWithAPNs() async { apnsRegistrations += 1 }
    }

    private final class InMemoryStorage: UserDefaultsManagerProtocol {
        var store: [String: Data] = [:]
        func save<T: Codable>(_ object: T, forKey key: String) {
            store[key] = try? JSONEncoder().encode(object)
        }
        func get<T: Codable>(forKey key: String) -> T? {
            store[key].flatMap { try? JSONDecoder().decode(T.self, from: $0) }
        }
        func remove(forKey key: String) { store[key] = nil }
    }

    private func makeUseCase(
        repository: SpyDeviceRepository = SpyDeviceRepository(),
        registrar: StubRegistrar = StubRegistrar(),
        relay: PushTokenRelay = PushTokenRelay()
    ) -> (CoachBriefsUseCase, SpyDeviceRepository, StubRegistrar, PushTokenRelay) {
        let useCase = CoachBriefsUseCase(
            repository: repository,
            registrar: registrar,
            storage: InMemoryStorage(),
            relay: relay
        )
        return (useCase, repository, registrar, relay)
    }

    // MARK: - Encender

    func testEnableWithPermissionRegistersTheKnownToken() async {
        let (useCase, repository, registrar, relay) = makeUseCase()
        relay.receive("aa11")   // APNs ya había dado token en un arranque anterior

        let granted = await useCase.enable()

        XCTAssertTrue(granted)
        XCTAssertTrue(useCase.isEnabled)
        XCTAssertEqual(registrar.apnsRegistrations, 1)
        XCTAssertEqual(repository.registered, ["aa11"])
    }

    func testDeniedPermissionLeavesEverythingOff() async {
        let (useCase, repository, registrar, _) = makeUseCase()
        registrar.grantsPermission = false

        let granted = await useCase.enable()

        XCTAssertFalse(granted)
        XCTAssertFalse(useCase.isEnabled, "el toggle no puede quedarse en verde sin permiso")
        XCTAssertTrue(repository.registered.isEmpty)
    }

    // MARK: - El token llega cuando quiere

    func testTokenArrivingAfterEnableIsRegistered() async {
        let (useCase, repository, _, relay) = makeUseCase()
        _ = await useCase.enable()   // sin token todavía

        await useCase.handleToken("bb22")
        _ = relay   // el relé no interviene: el use case recibe directo

        XCTAssertEqual(repository.registered, ["bb22"])
    }

    func testTokenWithBriefsOffIsNotRegistered() async {
        let (useCase, repository, _, _) = makeUseCase()

        await useCase.handleToken("cc33")

        XCTAssertTrue(
            repository.registered.isEmpty,
            "sin avisos encendidos no hay nada que registrar: el token se guarda en el relé y ya"
        )
    }

    // MARK: - Apagar

    func testDisableRemovesTheDeviceAndRemembersOff() async {
        let (useCase, repository, _, relay) = makeUseCase()
        relay.receive("dd44")
        _ = await useCase.enable()

        await useCase.disable()

        XCTAssertFalse(useCase.isEnabled)
        XCTAssertEqual(repository.removed, ["dd44"])

        // Y un token que rote DESPUÉS de apagar no revive el registro.
        await useCase.handleToken("ee55")
        XCTAssertEqual(repository.registered, ["dd44"], "solo el del enable")
    }

    // MARK: - Arranque

    func testLaunchRefreshOnlyActsWhenEnabledAndAuthorized() async {
        let (useCase, _, registrar, _) = makeUseCase()

        await useCase.refreshOnLaunch()
        XCTAssertEqual(registrar.apnsRegistrations, 0, "apagado: ni tocar APNs")

        registrar.alreadyAuthorized = true
        _ = await useCase.enable()
        await useCase.refreshOnLaunch()
        XCTAssertEqual(registrar.apnsRegistrations, 2, "enable + refresco")
    }

    /// El usuario encendió los avisos y luego revocó el permiso en Ajustes: el
    /// arranque no debe re-registrar un dispositivo que ya no puede recibir.
    func testLaunchRefreshSkipsWhenPermissionWasRevoked() async {
        let (useCase, _, registrar, _) = makeUseCase()
        _ = await useCase.enable()
        registrar.alreadyAuthorized = false   // revocado en Ajustes

        await useCase.refreshOnLaunch()

        XCTAssertEqual(registrar.apnsRegistrations, 1, "solo el del enable")
    }
}

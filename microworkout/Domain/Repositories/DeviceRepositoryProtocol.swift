protocol DeviceRepositoryProtocol {
    /// Da de alta el token en la cuenta. Sin sesión, se descarta en silencio:
    /// los avisos salen del servidor y un invitado no existe allí.
    func register(token: String) async throws
    func remove(token: String) async throws
}

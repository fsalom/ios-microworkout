protocol AIContextUseCaseProtocol {
    /// Construye un snapshot serializable con TODA la información de la app
    /// (perfil, plantillas, logs, comidas, salud, Apple Watch).
    /// `mealDaysBack` controla cuántos días hacia atrás se incluyen las comidas.
    /// `healthWeeksBack` cuántas semanas de datos de salud diarios se incluyen.
    func buildContext(mealDaysBack: Int, healthWeeksBack: Int) async -> AIContext

    /// Serializa el contexto a JSON con `pretty` para inspección manual.
    func toJSON(_ context: AIContext, pretty: Bool) -> String
}

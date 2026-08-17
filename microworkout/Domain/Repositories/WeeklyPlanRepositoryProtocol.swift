import Foundation

protocol WeeklyPlanRepositoryProtocol {
    /// El plan en vigor. Nunca falla por no haber plan: sin plan, el plan es vacío.
    func getPlan() async throws -> WeeklyPlan
    func savePlan(_ plan: WeeklyPlan) async throws
    /// 1 si el plan de este dispositivo todavía no está en la cuenta, 0 si sí.
    ///
    /// El plan es UNO, no una lista, así que el contador solo puede valer 0 o 1. Se
    /// mantiene la forma de las demás categorías para que la pantalla de
    /// sincronización no tenga que tratarlo como un caso aparte.
    func pendingSyncCount() async throws -> Int
    func syncLocalToRemote() async throws -> Int
}

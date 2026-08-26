protocol CoachFeedbackRepositoryProtocol {
    /// Envía la señal a la cuenta. Lanza si no se pudo; quien llama decide si
    /// le importa (normalmente no: el feedback nunca puede romper la UX).
    func send(_ signal: CoachFeedbackSignal) async throws
}

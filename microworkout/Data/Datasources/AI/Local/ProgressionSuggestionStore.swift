import Foundation

/// Objetivos de progresión aceptados, en el dispositivo.
///
/// No se sincronizan: son un recordatorio de corta vida ("la próxima vez que
/// hagas banca, 62,5"), no historial. A los 14 días un objetivo que no se ha
/// usado ya no describe tu estado — mejor que desaparezca a que te pida un peso
/// calculado sobre quien eras hace un mes.
final class ProgressionSuggestionStore: ProgressionSuggestionStoreProtocol {
    static let expiryDays = 14
    private static let key = "coach.progressionSuggestions"

    private let storage: UserDefaultsManagerProtocol

    init(storage: UserDefaultsManagerProtocol) {
        self.storage = storage
    }

    func save(_ suggestion: ProgressionSuggestion) {
        var all = load()
        all[Self.normalize(suggestion.exerciseName)] = suggestion
        storage.save(all, forKey: Self.key)
    }

    func suggestion(for exerciseName: String) -> ProgressionSuggestion? {
        guard let suggestion = load()[Self.normalize(exerciseName)] else { return nil }
        let ageDays = Date().timeIntervalSince(suggestion.savedAt) / 86_400
        guard ageDays < Double(Self.expiryDays) else { return nil }
        return suggestion
    }

    private func load() -> [String: ProgressionSuggestion] {
        storage.get(forKey: Self.key) ?? [:]
    }

    /// Minúsculas y sin espacios sobrantes: "press banca" y "Press Banca " son el
    /// mismo ejercicio aunque el modelo lo escriba distinto.
    private static func normalize(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

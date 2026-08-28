import Foundation

/// Un objetivo del coach para la próxima sesión de un ejercicio, ya aceptado por
/// el usuario. Vive hasta que caduca o lo sustituye otro del mismo ejercicio.
struct ProgressionSuggestion: Equatable, Codable {
    let exerciseName: String
    let weightKg: Double?
    let reps: Int?
    let sets: Int?
    let savedAt: Date

    /// Texto corto para la pantalla de registro: "62,5 kg × 8 (3 series)".
    var displayTarget: String {
        var parts: [String] = []
        if let weightKg {
            let formatted = weightKg.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(weightKg))
                : String(format: "%.1f", weightKg).replacingOccurrences(of: ".", with: ",")
            parts.append("\(formatted) kg")
        }
        if let reps { parts.append(parts.isEmpty ? "\(reps) reps" : "× \(reps)") }
        var text = parts.joined(separator: " ")
        if let sets { text += " (\(sets) series)" }
        return text
    }
}

/// Guarda y sirve los objetivos aceptados, por ejercicio.
///
/// La clave es el NOMBRE del ejercicio normalizado, no un id: el coach habla en
/// nombres (es lo que ve en el historial), y es también como la pantalla de
/// registro preguntará.
protocol ProgressionSuggestionStoreProtocol {
    func save(_ suggestion: ProgressionSuggestion)
    /// La sugerencia vigente para un ejercicio, si la hay y no ha caducado.
    func suggestion(for exerciseName: String) -> ProgressionSuggestion?
}

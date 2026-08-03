import Foundation

/// Área sobre la que asesora el coach. Determina el prompt que usa el backend
/// (`POST /v1/ai/coach` y `/v1/ai/insight`) y la etiqueta de la tarjeta.
///
/// Los `rawValue` son el contrato con el backend (`AITopic` en
/// `domain/entities/ai.py`): no se traducen ni se localizan.
public enum AICoachTopic: String, Codable, CaseIterable, Sendable {
    /// El día en conjunto: entreno + comida + actividad. Es el de la Home.
    case daily
    /// Progresión por ejercicio a partir del histórico de series.
    case workout
    /// Estructura del plan (plantillas de sesión) y adherencia real.
    case plan
    /// Calorías, macros y tendencia de los últimos días.
    case nutrition
    /// Pregunta libre del usuario en el chat.
    case free

    /// Etiqueta corta para la esquina de la tarjeta.
    var shortLabel: String {
        switch self {
        case .daily: return "RESUMEN"
        case .workout: return "PROGRESIÓN"
        case .plan: return "PLAN"
        case .nutrition: return "NUTRICIÓN"
        case .free: return "COACH"
        }
    }
}

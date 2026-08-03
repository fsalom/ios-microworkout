import Foundation

/// Contrato de red con `POST /v1/ai/coach` y `POST /v1/ai/insight`.
///
/// Espejo exacto de `CoachRequest` en `domain/entities/ai.py`. El modelo Pydantic
/// del backend usa `extra="forbid"`, así que **cualquier clave que no exista allí
/// devuelve 422**: al añadir un campo hay que tocar los dos lados.
///
/// Los `Optional` se omiten al serializar (el `encode` sintetizado usa
/// `encodeIfPresent`), que es justo lo que quiere el backend: campo ausente en vez
/// de `null`, para que apliquen sus validadores de rango.
struct AICoachRequestApiDTO: Encodable {
    let date: String            // yyyy-MM-dd
    let topic: String
    let profile: Profile
    let today: TodaySnapshot
    let history: [HistoryEntry]
    let plan: [PlanSession]
    let nutritionHistory: [NutritionDay]
    let messages: [ChatTurn]
    let userQuestion: String?

    enum CodingKeys: String, CodingKey {
        case date, topic, profile, today, history, plan, messages
        case nutritionHistory = "nutrition_history"
        case userQuestion = "user_question"
    }

    // MARK: - Perfil

    struct Profile: Encodable {
        let name: String?
        let gender: String?        // male | female | other
        let age: Int?              // 10...120
        let heightCm: Double?      // >0, <=300
        let weightKg: Double?      // >0, <=400
        let activityLevel: String?
        let goal: String?
        let calorieTarget: Int?    // >0, <=10000
        let language: String

        enum CodingKeys: String, CodingKey {
            case name, gender, age, goal, language
            case heightCm = "height_cm"
            case weightKg = "weight_kg"
            case activityLevel = "activity_level"
            case calorieTarget = "calorie_target"
        }
    }

    // MARK: - Día actual

    struct TodaySnapshot: Encodable {
        let workouts: [Workout]
        let meals: [Meal]
        let health: Health?
    }

    struct Workout: Encodable {
        let name: String
        let startedAt: String?
        let durationMinutes: Double?
        let kcalBurned: Double?
        let avgHeartRate: Double?
        let exercises: [Exercise]

        enum CodingKeys: String, CodingKey {
            case name, exercises
            case startedAt = "started_at"
            case durationMinutes = "duration_minutes"
            case kcalBurned = "kcal_burned"
            case avgHeartRate = "avg_heart_rate"
        }
    }

    struct Exercise: Encodable {
        let name: String
        let sets: [ExerciseSet]
        let notes: String?
    }

    struct ExerciseSet: Encodable {
        let weightKg: Double?
        let reps: Int?
        let rir: Double?
        let tags: [String]

        enum CodingKeys: String, CodingKey {
            case reps, rir, tags
            case weightKg = "weight_kg"
        }
    }

    struct Meal: Encodable {
        let type: String?
        let macros: Macros
        let items: [String]
    }

    struct Macros: Encodable {
        let calories: Double?
        let proteinG: Double?
        let carbsG: Double?
        let fatG: Double?

        enum CodingKeys: String, CodingKey {
            case calories
            case proteinG = "protein_g"
            case carbsG = "carbs_g"
            case fatG = "fat_g"
        }
    }

    struct Health: Encodable {
        let steps: Int?
        let activeKcal: Double?
        let restingHeartRate: Double?
        let sleepHours: Double?

        enum CodingKeys: String, CodingKey {
            case steps
            case activeKcal = "active_kcal"
            case restingHeartRate = "resting_heart_rate"
            case sleepHours = "sleep_hours"
        }
    }

    // MARK: - Histórico

    struct HistoryEntry: Encodable {
        let date: String           // yyyy-MM-dd
        let sessionName: String?
        let topSets: [String]
        let totalVolumeKg: Double?

        enum CodingKeys: String, CodingKey {
            case date
            case sessionName = "session_name"
            case topSets = "top_sets"
            case totalVolumeKg = "total_volume_kg"
        }
    }

    struct PlanSession: Encodable {
        let name: String
        let exercises: [String]
        let lastPerformed: String?  // yyyy-MM-dd
        let timesPerformed: Int?

        enum CodingKeys: String, CodingKey {
            case name, exercises
            case lastPerformed = "last_performed"
            case timesPerformed = "times_performed"
        }
    }

    struct NutritionDay: Encodable {
        let date: String           // yyyy-MM-dd
        let calories: Double?
        let proteinG: Double?
        let carbsG: Double?
        let fatG: Double?
        let targetCalories: Double?

        enum CodingKeys: String, CodingKey {
            case date, calories
            case proteinG = "protein_g"
            case carbsG = "carbs_g"
            case fatG = "fat_g"
            case targetCalories = "target_calories"
        }
    }

    struct ChatTurn: Encodable {
        let role: String           // user | assistant
        let content: String
    }
}

/// Respuesta de `POST /v1/ai/insight`.
struct AIInsightApiDTO: Decodable {
    let topic: String
    let title: String
    let body: String
    let bullets: [String]
    let prompt: String

    func toDomain(fallbackTopic: AICoachTopic) -> CoachInsight {
        CoachInsight(
            topic: AICoachTopic(rawValue: topic) ?? fallbackTopic,
            title: title,
            body: body,
            bullets: bullets,
            prompt: prompt,
            isFromModel: true
        )
    }
}

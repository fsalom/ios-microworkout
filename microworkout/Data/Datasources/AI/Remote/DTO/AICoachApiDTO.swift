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
    /// Momento exacto de la petición, en hora local con offset.
    ///
    /// Sin esto el coach solo sabía el DÍA, así que no podía razonar sobre "a estas
    /// alturas": qué queda por entrenar, si lo comido hasta ahora va bien, cuánto ha
    /// pasado desde el entreno. No era un problema de prompt: era un dato que no
    /// salía del móvil.
    let now: String?
    let topic: String
    let profile: Profile
    let today: TodaySnapshot
    let history: [HistoryEntry]
    let plan: [PlanSession]
    let nutritionHistory: [NutritionDay]
    let messages: [ChatTurn]
    let userQuestion: String?

    enum CodingKeys: String, CodingKey {
        case date, now, topic, profile, today, history, plan, messages
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
        /// Macros objetivo de HOY, en gramos. Sin esto el coach no puede juzgar los
        /// macros de una comida: veía "P42" y no tenía contra qué compararlo, así que
        /// solo podía hablar de calorías.
        let proteinTargetG: Int?
        let carbsTargetG: Int?
        let fatTargetG: Int?
        let language: String
        /// Días libres de la semana, índices de `Calendar` (1=domingo … 7=sábado).
        ///
        /// `nil` —no lista vacía— cuando el usuario no cicla: así la clave viaja
        /// AUSENTE, como el resto de campos sin valor. Un `[]` en cada petición es
        /// ruido, y el backend ya tiene `default_factory=list`.
        let freeDays: [Int]?
        let freeDayExtraCalories: Int?

        enum CodingKeys: String, CodingKey {
            case name, gender, age, goal, language
            case heightCm = "height_cm"
            case weightKg = "weight_kg"
            case activityLevel = "activity_level"
            case calorieTarget = "calorie_target"
            case proteinTargetG = "protein_target_g"
            case carbsTargetG = "carbs_target_g"
            case fatTargetG = "fat_target_g"
            case freeDays = "free_days"
            case freeDayExtraCalories = "free_day_extra_calories"
        }
    }

    // MARK: - Día actual

    struct TodaySnapshot: Encodable {
        let workouts: [Workout]
        let meals: [Meal]
        let health: Health?
        /// Los totales del día YA SUMADOS, y lo que queda contra el objetivo.
        ///
        /// No es redundante con `meals`: son exactamente los números que el usuario
        /// tiene en la cabecera de su pantalla. Cuando el modelo los sumaba él se los
        /// inventaba — una tarjeta dijo "415 kcal" y "114 g de proteína" (imposible:
        /// 114 g son 456 kcal) con 484 y 48 en pantalla. Sumar es trabajo del móvil,
        /// que ya lo hace para pintar la cabecera.
        let totals: Macros?
        let remaining: Macros?
    }

    struct Workout: Encodable {
        let name: String
        let startedAt: String?
        let durationMinutes: Double?
        let kcalBurned: Double?
        let avgHeartRate: Double?
        /// Para el cardio. Sin ella una carrera llegaba como "Carrera, 42 min" y no
        /// se podía valorar si los carbohidratos del día sostienen esa tirada.
        let distanceKm: Double?
        let exercises: [Exercise]

        enum CodingKeys: String, CodingKey {
            case name, exercises
            case startedAt = "started_at"
            case durationMinutes = "duration_minutes"
            case kcalBurned = "kcal_burned"
            case avgHeartRate = "avg_heart_rate"
            case distanceKm = "distance_km"
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
        /// Cuándo se comió, mismo formato que `Workout.startedAt`. Es lo que permite
        /// cruzar comida y entreno ("cenó dos horas después de entrenar"); antes solo
        /// se conservaba el orden relativo, sin reloj.
        let at: String?
        let macros: Macros
        let items: [MealItem]
    }

    /// Un alimento con sus números.
    ///
    /// Antes de cada alimento solo viajaba el NOMBRE, y con eso el coach no podía
    /// hacer lo más útil que hay sobre una comida: decir qué alimento concreto aporta
    /// poco y cuánto pesa en el total ("las barritas son 138 kcal y el sándwich 108:
    /// entre los dos, 246"). Solo podía hablar del agregado del día.
    struct MealItem: Encodable {
        let name: String
        let grams: Double?
        let calories: Double?
        let proteinG: Double?
        let carbsG: Double?
        let fatG: Double?

        enum CodingKeys: String, CodingKey {
            case name, grams, calories
            case proteinG = "protein_g"
            case carbsG = "carbs_g"
            case fatG = "fat_g"
        }
    }

    struct Macros: Encodable {
        let calories: Double?
        let proteinG: Double?
        let carbsG: Double?
        let fatG: Double?
        /// La app la registra pero no salía del móvil, así que el coach no podía decir
        /// nada sobre fibra ni sobre si la dieta lleva verdura suficiente.
        let fiberG: Double?

        enum CodingKeys: String, CodingKey {
            case calories
            case proteinG = "protein_g"
            case carbsG = "carbs_g"
            case fatG = "fat_g"
            case fiberG = "fiber_g"
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
    /// Opcional: un backend anterior no las manda, y una tarjeta sin acciones es
    /// perfectamente válida.
    let actions: [AIActionApiDTO]?

    func toDomain(fallbackTopic: AICoachTopic) -> CoachInsight {
        CoachInsight(
            topic: AICoachTopic(rawValue: topic) ?? fallbackTopic,
            title: title,
            body: body,
            bullets: bullets,
            prompt: prompt,
            isFromModel: true,
            // `compactMap`: una acción que la app no sepa ejecutar se descarta aquí y
            // no llega a pintarse. Un botón que no hace nada es peor que no tenerlo.
            actions: (actions ?? []).compactMap { $0.toDomain() }
        )
    }
}

struct AIActionApiDTO: Decodable {
    let type: String
    let label: String
    let mealType: String?
    let foodName: String?
    let grams: Double?
    let calories: Double?
    let proteinG: Double?
    let carbsG: Double?
    let fatG: Double?

    enum CodingKeys: String, CodingKey {
        case type, label, grams, calories
        case mealType = "meal_type"
        case foodName = "food_name"
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
    }

    func toDomain() -> CoachAction? {
        switch type {
        case "add_food":
            // Sin nombre o sin gramos no hay acción: un botón "añadir pollo" que no
            // sabe cuánto añadiría aplicaría cualquier cosa.
            guard let foodName, let grams, grams > 0 else { return nil }
            return .addFood(
                CoachAction.AddFood(
                    label: label,
                    mealType: mealType.flatMap { MealType(rawValue: $0) },
                    foodName: foodName,
                    grams: grams,
                    nutrition: NutritionInfo(
                        calories: calories ?? 0,
                        carbohydrates: carbsG ?? 0,
                        proteins: proteinG ?? 0,
                        fats: fatG ?? 0,
                        fiber: nil
                    )
                )
            )
        default:
            return nil
        }
    }
}

import Foundation

/// Insight producido por el coach IA para mostrarse embebido en una pantalla.
/// Algo concreto que la app puede hacer, propuesto por el coach.
///
/// Hasta ahora el coach solo opinaba: decía "te faltan 34 g de proteína" y tú tenías
/// que ir a otra pantalla y rehacer el trabajo a mano. Esto cierra ese hueco sin
/// darle escritura directa — propone, y tú confirmas con un toque.
///
/// Es un enum cerrado a propósito: una acción de un tipo que la app no sepa ejecutar
/// se descarta al mapear, en vez de llegar a la pantalla como un botón que no hace
/// nada.
public enum CoachAction: Identifiable, Equatable {
    /// Añadir un alimento a una comida de hoy, con sus macros ya resueltos.
    case addFood(AddFood)
    /// Objetivo para la próxima sesión de un ejercicio. Aplicarlo lo guarda, y la
    /// pantalla de registro lo enseña cuando toque ese ejercicio — el único
    /// momento en que "sube a 62,5" sirve de algo.
    case suggestProgression(Progression)

    public struct AddFood: Equatable {
        /// Texto del botón, tal y como lo propone el coach.
        public let label: String
        /// Comida a la que va. `nil` = la que corresponda por la hora.
        public let mealType: MealType?
        public let foodName: String
        public let grams: Double
        /// Macros de ESA cantidad, no por 100 g.
        public let nutrition: NutritionInfo

        public init(
            label: String, mealType: MealType?, foodName: String,
            grams: Double, nutrition: NutritionInfo
        ) {
            self.label = label
            self.mealType = mealType
            self.foodName = foodName
            self.grams = grams
            self.nutrition = nutrition
        }
    }

    public struct Progression: Equatable {
        public let label: String
        /// Tal y como se llama el ejercicio en los registros del usuario: es la
        /// clave con la que la pantalla de registro lo encontrará.
        public let exerciseName: String
        public let weightKg: Double?
        public let reps: Int?
        public let sets: Int?

        public init(
            label: String, exerciseName: String,
            weightKg: Double?, reps: Int?, sets: Int?
        ) {
            self.label = label
            self.exerciseName = exerciseName
            self.weightKg = weightKg
            self.reps = reps
            self.sets = sets
        }
    }

    public var id: String {
        switch self {
        case .addFood(let food): return "add_food:\(food.foodName):\(food.grams)"
        case .suggestProgression(let progression):
            return "progression:\(progression.exerciseName):\(progression.weightKg ?? 0):\(progression.reps ?? 0)"
        }
    }

    public var label: String {
        switch self {
        case .addFood(let food): return food.label
        case .suggestProgression(let progression): return progression.label
        }
    }
}

public struct CoachInsight: Identifiable, Equatable {
    public let id: UUID
    /// Área del consejo. Es el mismo enum que viaja al backend, para no tener
    /// dos taxonomías que mantener en sincronía.
    public let topic: AICoachTopic
    public let title: String
    public let body: String
    public let bullets: [String]
    /// Prompt prefijado para abrir el chat continuando esta conversación.
    public let prompt: String
    /// `false` cuando el consejo lo ha calculado la app en local (invitado o sin
    /// red) en vez del modelo. La tarjeta lo indica para no atribuirle a la IA
    /// algo que no ha dicho.
    public let isFromModel: Bool
    /// Acciones que la tarjeta ofrece con un toque. Vacío = solo consejo.
    public let actions: [CoachAction]

    public init(
        id: UUID = UUID(),
        topic: AICoachTopic,
        title: String,
        body: String,
        bullets: [String] = [],
        prompt: String,
        isFromModel: Bool = false,
        actions: [CoachAction] = []
    ) {
        self.id = id
        self.topic = topic
        self.title = title
        self.body = body
        self.bullets = bullets
        self.prompt = prompt
        self.isFromModel = isFromModel
        self.actions = actions
    }
}

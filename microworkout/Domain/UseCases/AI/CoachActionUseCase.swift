import Foundation

/// Aplica una acción propuesta por el coach.
///
/// El coach NO escribe en los datos del usuario: propone, y esto ejecuta lo que el
/// usuario haya confirmado con un toque. Esa separación es deliberada — el modelo
/// puede equivocarse en los macros de un alimento, y una app que registra comidas
/// sola sin que nadie las apruebe es peor que una que no propone nada.
protocol CoachActionUseCaseProtocol {
    /// Ejecuta la acción y devuelve el texto de confirmación para el usuario.
    func apply(_ action: CoachAction) async throws -> String
}

final class CoachActionUseCase: CoachActionUseCaseProtocol {
    private let mealUseCase: MealUseCaseProtocol
    private let feedback: CoachFeedbackUseCaseProtocol?

    init(mealUseCase: MealUseCaseProtocol, feedback: CoachFeedbackUseCaseProtocol? = nil) {
        self.mealUseCase = mealUseCase
        self.feedback = feedback
    }

    func apply(_ action: CoachAction) async throws -> String {
        let confirmation: String
        switch action {
        case .addFood(let food):
            confirmation = try await addFood(food)
        }
        // Solo tras aplicarse de verdad: una acción que falló no es una aceptada.
        // Las acciones de hoy son de comida, de ahí el tema.
        await feedback?.actionApplied(action, topic: .nutrition)
        return confirmation
    }

    private func addFood(_ food: CoachAction.AddFood) async throws -> String {
        // El coach manda los macros DE ESA CANTIDAD, pero `FoodItem` los guarda por
        // 100 g y los reescala al pintar. Sin esta conversión, añadir 150 g de pollo
        // registraría los macros de 150 g multiplicados otra vez por 1,5.
        let per100g = food.grams > 0
            ? food.nutrition.scaled(by: 100 / food.grams)
            : food.nutrition

        let item = FoodItem(
            name: food.foodName,
            nutritionPer100g: per100g,
            quantity: food.grams
        )

        // A la comida que diga el coach y, si no lo dice, a la que toque por la hora.
        let meal = Meal(
            type: food.mealType ?? .forCurrentTime(),
            timestamp: Date(),
            items: [item]
        )
        try await mealUseCase.saveMeal(meal)

        let grams = Int(food.grams.rounded())
        return "Añadido: \(food.foodName), \(grams) g"
    }
}

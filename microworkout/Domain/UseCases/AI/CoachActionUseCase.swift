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

    init(mealUseCase: MealUseCaseProtocol) {
        self.mealUseCase = mealUseCase
    }

    func apply(_ action: CoachAction) async throws -> String {
        switch action {
        case .addFood(let food):
            return try await addFood(food)
        }
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

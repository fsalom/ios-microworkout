import Foundation

/// Wire-level types matching the FastAPI backend at `/v1/meals`, `/v1/foods/*`
/// and `/v1/my-meals`. Backend uses snake_case → mapped via CodingKeys.

struct NutritionInfoApiDTO: Codable {
    let calories: Double
    let carbohydrates: Double
    let proteins: Double
    let fats: Double
    let fiber: Double?
}

struct MealItemApiDTO: Codable {
    let id: UUID
    let foodId: UUID?
    let name: String
    let barcode: String?
    let nutritionPer100g: NutritionInfoApiDTO
    let quantity: Double
    let servingSize: Double?
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case foodId = "food_id"
        case name
        case barcode
        case nutritionPer100g = "nutrition_per_100g"
        case quantity
        case servingSize = "serving_size"
        case imageUrl = "image_url"
    }
}

struct MealApiDTO: Codable {
    let id: UUID
    let type: String
    let timestamp: Date
    let items: [MealItemApiDTO]
    let myMealName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case timestamp
        case items
        case myMealName = "my_meal_name"
    }
}

struct FoodApiDTO: Codable {
    let id: UUID?
    let name: String
    let barcode: String?
    let nutritionPer100g: NutritionInfoApiDTO
    let servingSize: Double?
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case barcode
        case nutritionPer100g = "nutrition_per_100g"
        case servingSize = "serving_size"
        case imageUrl = "image_url"
    }
}

struct MyMealApiDTO: Codable {
    let id: UUID
    let name: String
    let items: [MealItemApiDTO]
}

// MARK: - Domain ← Wire

extension NutritionInfoApiDTO {
    func toDomain() -> NutritionInfo {
        NutritionInfo(
            calories: calories,
            carbohydrates: carbohydrates,
            proteins: proteins,
            fats: fats,
            fiber: fiber
        )
    }
}

extension MealItemApiDTO {
    func toDomain() -> FoodItem {
        FoodItem(
            id: id,
            name: name,
            barcode: barcode,
            nutritionPer100g: nutritionPer100g.toDomain(),
            quantity: quantity,
            servingSize: servingSize,
            imageUrl: imageUrl
        )
    }
}

extension MealApiDTO {
    func toDomain() -> Meal {
        Meal(
            id: id,
            type: MealType(rawValue: type) ?? .snack,
            timestamp: timestamp,
            items: items.map { $0.toDomain() },
            myMealName: myMealName
        )
    }
}

extension FoodApiDTO {
    /// Recent/favorite foods on the backend don't carry a `quantity` (they're
    /// catalog entries, not meal items). We default to 100g — the canonical
    /// reference value the UI uses for unselected items.
    func toDomain() -> FoodItem {
        FoodItem(
            id: id ?? UUID(),
            name: name,
            barcode: barcode,
            nutritionPer100g: nutritionPer100g.toDomain(),
            quantity: 100,
            servingSize: servingSize,
            imageUrl: imageUrl
        )
    }
}

extension MyMealApiDTO {
    func toDomain() -> MyMeal {
        MyMeal(
            id: id,
            name: name,
            items: items.map { $0.toDomain() }
        )
    }
}

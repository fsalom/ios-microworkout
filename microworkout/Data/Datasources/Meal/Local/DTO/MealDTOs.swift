import Foundation

// MARK: - DTOs

/// Espejo on-disk de `Meal`. Mantiene los mismos nombres de campo y forma de
/// JSON que la entidad Domain — así la migración a este DTO no rompe datos
/// existentes de usuarios. El enum `MealType` se serializa como `String` para
/// que renombrar/quitar un caso de la entidad no rompa la deserialización.
struct MealDTO: Codable {
    let id: UUID
    var type: String
    var timestamp: Date
    var items: [FoodItemDTO]
    var myMealName: String?
}

struct FoodItemDTO: Codable {
    let id: UUID
    var name: String
    var barcode: String?
    var nutritionPer100g: NutritionInfoDTO
    var quantity: Double
    var servingSize: Double?
    var imageUrl: String?
}

struct NutritionInfoDTO: Codable {
    var calories: Double
    var carbohydrates: Double
    var proteins: Double
    var fats: Double
    var fiber: Double?
}

struct MyMealDTO: Codable {
    let id: UUID
    var name: String
    var items: [FoodItemDTO]
    var createdAt: Date
}

// MARK: - DTO → Domain

extension MealDTO {
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

extension FoodItemDTO {
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

extension NutritionInfoDTO {
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

extension MyMealDTO {
    func toDomain() -> MyMeal {
        MyMeal(id: id, name: name, items: items.map { $0.toDomain() }, createdAt: createdAt)
    }
}

// MARK: - Domain → DTO

extension Meal {
    func toDTO() -> MealDTO {
        MealDTO(
            id: id,
            type: type.rawValue,
            timestamp: timestamp,
            items: items.map { $0.toDTO() },
            myMealName: myMealName
        )
    }
}

extension FoodItem {
    func toDTO() -> FoodItemDTO {
        FoodItemDTO(
            id: id,
            name: name,
            barcode: barcode,
            nutritionPer100g: nutritionPer100g.toDTO(),
            quantity: quantity,
            servingSize: servingSize,
            imageUrl: imageUrl
        )
    }
}

extension NutritionInfo {
    func toDTO() -> NutritionInfoDTO {
        NutritionInfoDTO(
            calories: calories,
            carbohydrates: carbohydrates,
            proteins: proteins,
            fats: fats,
            fiber: fiber
        )
    }
}

extension MyMeal {
    func toDTO() -> MyMealDTO {
        MyMealDTO(id: id, name: name, items: items.map { $0.toDTO() }, createdAt: createdAt)
    }
}

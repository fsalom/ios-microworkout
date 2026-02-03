//
//  OpenFoodFactsDTO.swift
//  microworkout
//

import Foundation

/// DTO para la respuesta de Open Food Facts API.
struct OpenFoodFactsResponseDTO: Codable {
    let status: Int
    let product: OpenFoodFactsProductDTO?
}

/// DTO para el producto de Open Food Facts.
struct OpenFoodFactsProductDTO: Codable {
    let productName: String?
    let productNameEs: String?
    let brands: String?
    let imageUrl: String?
    let nutriments: OpenFoodFactsNutrimentsDTO?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case productNameEs = "product_name_es"
        case brands
        case imageUrl = "image_url"
        case nutriments
    }

    /// Nombre del producto (prioriza español)
    var displayName: String {
        productNameEs ?? productName ?? brands ?? "Producto desconocido"
    }
}

/// DTO para los nutrientes de Open Food Facts.
struct OpenFoodFactsNutrimentsDTO: Codable {
    let energyKcal100g: Double?
    let carbohydrates100g: Double?
    let proteins100g: Double?
    let fat100g: Double?
    let fiber100g: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case proteins100g = "proteins_100g"
        case fat100g = "fat_100g"
        case fiber100g = "fiber_100g"
    }
}

// MARK: - Mapping to Domain

extension OpenFoodFactsProductDTO {
    /// Convierte el DTO a entidad de dominio FoodItem.
    func toDomain(barcode: String) -> FoodItem {
        FoodItem(
            id: UUID(),
            name: displayName,
            barcode: barcode,
            nutritionPer100g: NutritionInfo(
                calories: nutriments?.energyKcal100g ?? 0,
                carbohydrates: nutriments?.carbohydrates100g ?? 0,
                proteins: nutriments?.proteins100g ?? 0,
                fats: nutriments?.fat100g ?? 0,
                fiber: nutriments?.fiber100g
            ),
            quantity: 100,
            servingSize: nil,
            imageUrl: imageUrl
        )
    }
}

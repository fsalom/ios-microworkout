//
//  OpenFoodFactsDTO.swift
//  microworkout
//

import Foundation

/// DTO para la respuesta de Open Food Facts API (producto individual).
struct OpenFoodFactsResponseDTO: Codable {
    let status: Int
    let product: OpenFoodFactsProductDTO?
}

/// DTO para la respuesta de búsqueda de Open Food Facts API.
struct OpenFoodFactsSearchResponseDTO: Codable {
    let count: Int?
    let page: Int?
    let pageSize: Int?
    let products: [OpenFoodFactsProductDTO]?

    enum CodingKeys: String, CodingKey {
        case count
        case page
        case pageSize = "page_size"
        case products
    }
}

/// DTO para el producto de Open Food Facts.
struct OpenFoodFactsProductDTO: Codable {
    let code: String?
    let productName: String?
    let productNameEs: String?
    let brands: String?
    let imageUrl: String?
    let imageFrontSmallUrl: String?
    let nutriments: OpenFoodFactsNutrimentsDTO?

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case productNameEs = "product_name_es"
        case brands
        case imageUrl = "image_url"
        case imageFrontSmallUrl = "image_front_small_url"
        case nutriments
    }

    /// Nombre del producto (prioriza español)
    var displayName: String {
        let name = productNameEs ?? productName ?? "Producto desconocido"
        if let brand = brands, !brand.isEmpty, !name.lowercased().contains(brand.lowercased()) {
            return "\(name) - \(brand)"
        }
        return name
    }

    /// URL de imagen (prioriza la pequeña para listas)
    var thumbnailUrl: String? {
        imageFrontSmallUrl ?? imageUrl
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
    func toDomain(barcode: String? = nil) -> FoodItem {
        FoodItem(
            id: UUID(),
            name: displayName,
            barcode: barcode ?? code,
            nutritionPer100g: NutritionInfo(
                calories: nutriments?.energyKcal100g ?? 0,
                carbohydrates: nutriments?.carbohydrates100g ?? 0,
                proteins: nutriments?.proteins100g ?? 0,
                fats: nutriments?.fat100g ?? 0,
                fiber: nutriments?.fiber100g
            ),
            quantity: 100,
            servingSize: nil,
            imageUrl: thumbnailUrl ?? imageUrl
        )
    }
}

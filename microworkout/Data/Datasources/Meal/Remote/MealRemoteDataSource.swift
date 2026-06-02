import Foundation
import TripleA

protocol MealRemoteDataSourceProtocol {
    // Meals
    func createMeal(_ meal: Meal) async throws -> MealApiDTO
    func listMeals(for date: Date) async throws -> [MealApiDTO]
    func listMeals(from start: Date, to end: Date) async throws -> [MealApiDTO]
    func deleteMeal(id: UUID) async throws

    // Foods
    func foodByBarcode(_ barcode: String) async throws -> FoodApiDTO?

    // Favorites
    func listFavorites() async throws -> [FoodApiDTO]
    func addFavorite(foodId: UUID) async throws
    func removeFavorite(foodId: UUID) async throws
    func createCustomFood(_ food: FoodItem) async throws -> FoodApiDTO

    // My meals
    func listMyMeals() async throws -> [MyMealApiDTO]
    func createMyMeal(_ myMeal: MyMeal) async throws -> MyMealApiDTO
    func deleteMyMeal(id: UUID) async throws
}

/// Talks to `/v1/meals`, `/v1/foods/*` and `/v1/my-meals` on the FastAPI backend.
final class MealRemoteDataSource: MealRemoteDataSourceProtocol {
    private let network: Network

    init(network: Network = Config.shared.network) {
        self.network = network
    }

    // MARK: - Meals

    func createMeal(_ meal: Meal) async throws -> MealApiDTO {
        var body: [String: Any] = [
            "id": meal.id.uuidString.lowercased(),
            "type": meal.type.rawValue,
            "timestamp": Self.iso8601.string(from: meal.timestamp),
            "items": meal.items.map { mealItemPayload($0) },
        ]
        if let name = meal.myMealName { body["my_meal_name"] = name }
        let endpoint = Endpoint(path: "v1/meals", httpMethod: .post, parameters: body)
        let (_, data) = try await network.loadAuthorized(this: endpoint)
        guard let data else { throw NetworkError.invalidResponse }
        return try Self.decoder.decode(MealApiDTO.self, from: data)
    }

    func listMeals(for date: Date) async throws -> [MealApiDTO] {
        let endpoint = Endpoint(
            path: "v1/meals",
            httpMethod: .get,
            query: ["date": Self.dateOnly.string(from: date)]
        )
        let (_, data) = try await network.loadAuthorized(this: endpoint)
        guard let data else { return [] }
        return try Self.decoder.decode([MealApiDTO].self, from: data)
    }

    func listMeals(from start: Date, to end: Date) async throws -> [MealApiDTO] {
        let endpoint = Endpoint(
            path: "v1/meals",
            httpMethod: .get,
            query: [
                "from": Self.dateOnly.string(from: start),
                "to": Self.dateOnly.string(from: end),
            ]
        )
        let (_, data) = try await network.loadAuthorized(this: endpoint)
        guard let data else { return [] }
        return try Self.decoder.decode([MealApiDTO].self, from: data)
    }

    func deleteMeal(id: UUID) async throws {
        let endpoint = Endpoint(
            path: "v1/meals/\(id.uuidString.lowercased())",
            httpMethod: .delete
        )
        _ = try await network.loadAuthorized(this: endpoint)
    }

    // MARK: - Foods

    func foodByBarcode(_ barcode: String) async throws -> FoodApiDTO? {
        let endpoint = Endpoint(
            path: "v1/foods/by-barcode/\(barcode)",
            httpMethod: .get
        )
        do {
            let (status, data) = try await network.loadAuthorized(this: endpoint)
            if status == 404 { return nil }
            guard let data else { return nil }
            return try Self.decoder.decode(FoodApiDTO.self, from: data)
        } catch let NetworkError.failure(statusCode, _, _) where statusCode == 404 {
            return nil
        }
    }

    // MARK: - Favorites

    func listFavorites() async throws -> [FoodApiDTO] {
        let endpoint = Endpoint(path: "v1/foods/favorites", httpMethod: .get)
        let (_, data) = try await network.loadAuthorized(this: endpoint)
        guard let data else { return [] }
        return try Self.decoder.decode([FoodApiDTO].self, from: data)
    }

    func addFavorite(foodId: UUID) async throws {
        let endpoint = Endpoint(
            path: "v1/foods/\(foodId.uuidString.lowercased())/favorite",
            httpMethod: .post
        )
        _ = try await network.loadAuthorized(this: endpoint)
    }

    func removeFavorite(foodId: UUID) async throws {
        let endpoint = Endpoint(
            path: "v1/foods/\(foodId.uuidString.lowercased())/favorite",
            httpMethod: .delete
        )
        _ = try await network.loadAuthorized(this: endpoint)
    }

    func createCustomFood(_ food: FoodItem) async throws -> FoodApiDTO {
        var body: [String: Any] = [
            "name": food.name,
            "nutrition_per_100g": nutritionPayload(food.nutritionPer100g),
        ]
        if let barcode = food.barcode { body["barcode"] = barcode }
        if let serving = food.servingSize { body["serving_size"] = serving }
        if let image = food.imageUrl { body["image_url"] = image }
        let endpoint = Endpoint(
            path: "v1/foods/custom",
            httpMethod: .post,
            parameters: body
        )
        let (_, data) = try await network.loadAuthorized(this: endpoint)
        guard let data else { throw NetworkError.invalidResponse }
        return try Self.decoder.decode(FoodApiDTO.self, from: data)
    }

    // MARK: - My meals

    func listMyMeals() async throws -> [MyMealApiDTO] {
        let endpoint = Endpoint(path: "v1/my-meals", httpMethod: .get)
        let (_, data) = try await network.loadAuthorized(this: endpoint)
        guard let data else { return [] }
        return try Self.decoder.decode([MyMealApiDTO].self, from: data)
    }

    func createMyMeal(_ myMeal: MyMeal) async throws -> MyMealApiDTO {
        let body: [String: Any] = [
            "id": myMeal.id.uuidString.lowercased(),
            "name": myMeal.name,
            "items": myMeal.items.map { mealItemPayload($0) },
        ]
        let endpoint = Endpoint(
            path: "v1/my-meals",
            httpMethod: .post,
            parameters: body
        )
        let (_, data) = try await network.loadAuthorized(this: endpoint)
        guard let data else { throw NetworkError.invalidResponse }
        return try Self.decoder.decode(MyMealApiDTO.self, from: data)
    }

    func deleteMyMeal(id: UUID) async throws {
        let endpoint = Endpoint(
            path: "v1/my-meals/\(id.uuidString.lowercased())",
            httpMethod: .delete
        )
        _ = try await network.loadAuthorized(this: endpoint)
    }

    // MARK: - Helpers

    private func nutritionPayload(_ info: NutritionInfo) -> [String: Any] {
        var dict: [String: Any] = [
            "calories": info.calories,
            "carbohydrates": info.carbohydrates,
            "proteins": info.proteins,
            "fats": info.fats,
        ]
        if let fiber = info.fiber { dict["fiber"] = fiber }
        return dict
    }

    private func mealItemPayload(_ item: FoodItem) -> [String: Any] {
        var dict: [String: Any] = [
            "id": item.id.uuidString.lowercased(),
            "name": item.name,
            "nutrition_per_100g": nutritionPayload(item.nutritionPer100g),
            "quantity": item.quantity,
        ]
        if let barcode = item.barcode { dict["barcode"] = barcode }
        if let serving = item.servingSize { dict["serving_size"] = serving }
        if let image = item.imageUrl { dict["image_url"] = image }
        return dict
    }

    private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let dateOnly: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            let withFraction = ISO8601DateFormatter()
            withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = withFraction.date(from: raw) { return date }
            let plain = ISO8601DateFormatter()
            plain.formatOptions = [.withInternetDateTime]
            if let date = plain.date(from: raw) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unrecognised date format: \(raw)"
            )
        }
        return d
    }()
}

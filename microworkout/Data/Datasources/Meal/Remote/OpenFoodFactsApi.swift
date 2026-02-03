//
//  OpenFoodFactsApi.swift
//  microworkout
//

import Foundation

/// Errores de la API de Open Food Facts.
enum OpenFoodFactsApiError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case productNotFound
}

/// Implementación de la API de Open Food Facts.
class OpenFoodFactsApi: OpenFoodFactsApiProtocol {
    private let baseURL = "https://world.openfoodfacts.org/api/v2/product"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchProduct(barcode: String) async throws -> OpenFoodFactsProductDTO? {
        guard let url = URL(string: "\(baseURL)/\(barcode).json") else {
            throw OpenFoodFactsApiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("MicroworkoutApp/1.0 (iOS)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, _) = try await session.data(for: request)
            let decoder = JSONDecoder()
            let response = try decoder.decode(OpenFoodFactsResponseDTO.self, from: data)

            guard response.status == 1, let product = response.product else {
                return nil
            }

            return product
        } catch let error as DecodingError {
            throw OpenFoodFactsApiError.decodingError(error)
        } catch {
            throw OpenFoodFactsApiError.networkError(error)
        }
    }
}

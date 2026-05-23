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
    private let productBaseURL = "https://world.openfoodfacts.org/api/v2/product"
    private let searchBaseURL = "https://search.openfoodfacts.org/search"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchProduct(barcode: String) async throws -> OpenFoodFactsProductDTO? {
        guard let url = URL(string: "\(productBaseURL)/\(barcode).json") else {
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

    func searchProducts(query: String, page: Int = 1, pageSize: Int = 20) async throws -> [OpenFoodFactsProductDTO] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard var components = URLComponents(string: searchBaseURL) else {
            throw OpenFoodFactsApiError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "q", value: trimmed),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)"),
            URLQueryItem(name: "fields", value: "code,product_name,product_name_es,brands,image_url,image_front_small_url,nutriments,countries_tags,states_tags"),
            URLQueryItem(name: "langs", value: "es")
        ]
        guard let url = components.url else {
            throw OpenFoodFactsApiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Microworkout - iOS - 1.0 - https://github.com/fersalom/microworkout", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        // Skip URLCache so a transient empty/failed response can't make subsequent
        // identical queries return stale empty results.
        request.cachePolicy = .reloadIgnoringLocalCacheData

        print("[OpenFoodFacts] GET \(url.absoluteString)")

        do {
            let (data, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse {
                print("[OpenFoodFacts] HTTP \(http.statusCode), \(data.count) bytes")
            }
            let decoder = JSONDecoder()
            do {
                let parsed = try decoder.decode(SearchALicousResponseDTO.self, from: data)
                // Stable sort by priority (Spain / verified first), preserving the original
                // relevance order within each group.
                let sortedHits = (parsed.hits ?? [])
                    .enumerated()
                    .sorted {
                        if $0.element.priorityRank != $1.element.priorityRank {
                            return $0.element.priorityRank < $1.element.priorityRank
                        }
                        return $0.offset < $1.offset
                    }
                    .map { $0.element }
                let products = sortedHits.map { $0.toProductDTO() }
                print("[OpenFoodFacts] received \(products.count) products for \"\(trimmed)\"")
                return products
            } catch let error as DecodingError {
                let body = String(data: data.prefix(400), encoding: .utf8) ?? "<binary>"
                print("[OpenFoodFacts] decoding error. Body preview: \(body)")
                throw OpenFoodFactsApiError.decodingError(error)
            }
        } catch let error as OpenFoodFactsApiError {
            throw error
        } catch {
            print("[OpenFoodFacts] network error: \(error)")
            throw OpenFoodFactsApiError.networkError(error)
        }
    }
}

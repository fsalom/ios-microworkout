//
//  OpenFoodFactsApiProtocol.swift
//  microworkout
//

import Foundation

/// Protocolo para la API de Open Food Facts.
protocol OpenFoodFactsApiProtocol {
    /// Busca un producto por código de barras.
    func fetchProduct(barcode: String) async throws -> OpenFoodFactsProductDTO?

    /// Busca productos por texto.
    func searchProducts(query: String, page: Int, pageSize: Int) async throws -> [OpenFoodFactsProductDTO]
}

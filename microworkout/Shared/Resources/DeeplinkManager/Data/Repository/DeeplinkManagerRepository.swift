//
//  Gula
//
//  DeeplinkManagerRepository.swift
//
//  Created by Rudo Apps on 9/5/25
//

final class DeeplinkManagerRepository: DeeplinkManagerRepositoryProtocol {
    private let dataSource: DeeplinkManagerDatasourceProtocol
    private let errorHandler: ErrorHandlerProtocol

    init(dataSource: DeeplinkManagerDatasourceProtocol, errorHandler: ErrorHandlerProtocol) {
        self.dataSource = dataSource
        self.errorHandler = errorHandler
    }

    func resendLinkVerification(email: String) async throws {
        do {
            try await dataSource.resendLinkVerification(email: email)
        } catch {
            throw errorHandler.handle(error)
        }
    }
}

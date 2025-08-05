//
//  Gula
//
//  DeeplinkManagerUseCase.swift
//
//  Created by Rudo Apps on 9/5/25
//

final class DeeplinkManagerUseCase: DeeplinkManagerUseCaseProtocol {
    private let repository: DeeplinkManagerRepositoryProtocol

    init(repository: DeeplinkManagerRepositoryProtocol) {
        self.repository = repository
    }

    func resendLinkVerification(email: String) async throws {
        try await repository.resendLinkVerification(email: email)
    }
}

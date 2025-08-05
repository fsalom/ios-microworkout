//
//  Gula
//
//  DeeplinkManagerDatasource.swift
//
//  Created by Rudo Apps on 9/5/25
//

import TripleA

final class DeeplinkManagerDatasource: DeeplinkManagerDatasourceProtocol {
    private let network: Network

    init(network: Network) {
        self.network = network
    }

    func resendLinkVerification(email: String) async throws {
        let parameters = ["email": email]
        let endpoint = Endpoint(path: "api/users/resend-link", httpMethod: .post, parameters: parameters)
        _ = try await network.load(this: endpoint)
    }
}

//
//  Gula
//
//  DeeplinkManagerRepositoryProtocol.swift
//
//  Created by Rudo Apps on 9/5/25
//

protocol DeeplinkManagerRepositoryProtocol {
    func resendLinkVerification(email: String) async throws
}

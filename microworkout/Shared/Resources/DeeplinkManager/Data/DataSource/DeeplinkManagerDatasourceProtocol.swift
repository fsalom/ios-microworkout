//
//  Gula
//
//  DeeplinkManagerDatasourceProtocol.swift
//
//  Created by Rudo Apps on 9/5/25
//

protocol DeeplinkManagerDatasourceProtocol {
    func resendLinkVerification(email: String) async throws
}

//
//  Gula
//
//  DeeplinkResendViewModel.swift
//
//  Created by Rudo Apps on 9/5/25
//

import Foundation

final class DeeplinkResendViewModel: ObservableObject {
    struct UIState {
        var needToShowToast: Bool = false
    }

    private let useCase: DeeplinkManagerUseCaseProtocol
    let config: DeeplinkResendConfig
    var uiState: UIState = .init()

    init(useCase: DeeplinkManagerUseCaseProtocol, config: DeeplinkResendConfig) {
        self.useCase = useCase
        self.config = config
    }

    @MainActor
    func resendLinkVerification() {
        Task {
            do {
                try await useCase.resendLinkVerification(email: config.email)
                uiState.needToShowToast = true
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

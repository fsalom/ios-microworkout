//
//  OnboardingBuilder.swift
//  microworkout
//

import Foundation

class OnboardingBuilder {
    func build(appState: AppState) -> OnboardingView {
        let viewModel = OnboardingViewModel(
            userProfileUseCase: UserProfileContainer().makeUseCase(),
            appState: appState
        )
        return OnboardingView(viewModel: viewModel)
    }
}

//
//  OnboardingBuilder.swift
//  microworkout
//

import Foundation

class OnboardingBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build(appState: AppState) -> OnboardingView {
        let viewModel = OnboardingViewModel(
            userProfileUseCase: UserProfileContainer(component: component).makeUseCase(),
            appState: appState
        )
        return OnboardingView(viewModel: viewModel)
    }
}

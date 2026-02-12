//
//  OnboardingViewModel.swift
//  microworkout
//

import Foundation
import SwiftUI

final class OnboardingViewModel: ObservableObject {
    @Published var currentStep: Int = 0
    @Published var name: String = ""
    @Published var weight: Double = 70
    @Published var height: Double = 170
    @Published var age: Int = 30
    @Published var gender: UserProfile.Gender = .male
    @Published var activityLevel: UserProfile.ActivityLevel = .moderate
    @Published var fitnessGoal: UserProfile.FitnessGoal = .maintain

    private let userProfileUseCase: UserProfileUseCaseProtocol
    private let appState: AppState

    let totalSteps = 4

    init(userProfileUseCase: UserProfileUseCaseProtocol, appState: AppState) {
        self.userProfileUseCase = userProfileUseCase
        self.appState = appState
    }

    func nextStep() {
        if currentStep < totalSteps - 1 {
            withAnimation {
                currentStep += 1
            }
        }
    }

    func previousStep() {
        if currentStep > 0 {
            withAnimation {
                currentStep -= 1
            }
        }
    }

    func finish() {
        let profile = UserProfile(
            name: name.isEmpty ? "Usuario" : name,
            height: height,
            weight: weight,
            age: age,
            gender: gender,
            activityLevel: activityLevel,
            fitnessGoal: fitnessGoal
        )
        userProfileUseCase.saveProfile(profile)
        userProfileUseCase.setOnboardingCompleted(true)
        appState.changeScreen(to: .home)
    }

    func skip() {
        userProfileUseCase.setOnboardingCompleted(true)
        appState.changeScreen(to: .home)
    }
}

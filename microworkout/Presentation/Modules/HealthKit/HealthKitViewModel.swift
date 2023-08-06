//
//  HealthKitViewModel.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 5/8/23.
//

import Foundation
import HealthKit

class HealthKitViewModel: ObservableObject, HealthKitViewModelProtocol {
    @Published var workouts: [WorkoutPlan]
    private let healthStore: HKHealthStore

    var useCase: WorkoutUseCaseProtocol!

    init(useCase: WorkoutUseCaseProtocol) {
        self.useCase = useCase
        self.workouts = []
        guard HKHealthStore.isHealthDataAvailable() else {  fatalError("This app requires a device that supports HealthKit") }
        healthStore = HKHealthStore()
        requestHealthkitPermissions()

    }

    func load() {
        Task {
            let workouts = try await useCase.getWorkouts()

            await MainActor.run {
                self.workouts = workouts
            }
        }
    }

    private func requestHealthkitPermissions() {
        let sampleTypesToRead = Set([
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        ])

        healthStore.requestAuthorization(toShare: nil, read: sampleTypesToRead) { (success, error) in
            print("Request Authorization -- Success: ", success, " Error: ", error ?? "nil")
        }
    }

    func accessHealthInfo() -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }
        return true
    }
}

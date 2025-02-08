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
    @Published var beats: [Beat] = []
    private let healthStore: HKHealthStore
    let heartRateUnit:HKUnit = HKUnit(from: "count/min")


    var useCase: WorkoutUseCaseProtocol!

    init(useCase: WorkoutUseCaseProtocol) {
        self.useCase = useCase
        self.workouts = []
        guard HKHealthStore.isHealthDataAvailable() else {  fatalError("This app requires a device that supports HealthKit") }
        healthStore = HKHealthStore()
        requestHealthkitPermissions()
    }

    func load() async {
        do {
            let workouts = try await useCase.getWorkouts()
            readHeartRate()
            await MainActor.run {
                self.workouts = workouts
            }
        } catch {
            
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

    private func readHeartRate(){
        let quantityType  = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let sampleQuery = HKSampleQuery.init(sampleType: quantityType,
                                             predicate: get24hPredicate(),
                                             limit: HKObjectQueryNoLimit,
                                             sortDescriptors: [sortDescriptor],
                                             resultsHandler: { (query, results, error) in

            guard let samples = results as? [HKQuantitySample] else {
                print(error!)
                return
            }
            DispatchQueue.main.async {
                self.beats = samples.map({ Beat(value: $0.quantity.doubleValue(for: self.heartRateUnit), start: $0.startDate, end: $0.endDate)})
            }
            for sample in samples {
                print("[\(sample)]")
                print("Heart Rate: \(sample.quantity.doubleValue(for: self.heartRateUnit))")
                print("quantityType: \(sample.quantityType)")
                print("Start Date: \(sample.startDate)")
                print("End Date: \(sample.endDate)")
                print("Metadata: \(sample.metadata)")
                print("UUID: \(sample.uuid)")
                print("Source: \(sample.sourceRevision)")
                print("Device: \(sample.device)")
                print("---------------------------------\n")
            }

        })
        self.healthStore.execute(sampleQuery)

    }

    private func get24hPredicate() ->  NSPredicate{
        let today = Date()
        let startDate = Calendar.current.date(byAdding: .hour, value: -24, to: today)
        let predicate = HKQuery.predicateForSamples(withStart: startDate,end: today,options: [])
        return predicate
    }
}

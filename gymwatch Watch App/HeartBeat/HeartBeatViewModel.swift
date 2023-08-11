//
//  HeartBeatViewModel.swift
//  gymwatch Watch App
//
//  Created by Fernando Salom Carratala on 7/8/23.
//

import Foundation
import HealthKit

class HeartBeatViewModel: ObservableObject {
    private var healthStore = HKHealthStore()
    let heartRateQuantity = HKUnit(from: "count/min")
    @Published var value = 0
    
    func start() {
        autorizeHealthKit()
        startHeartRateQuery(quantityTypeIdentifier: .heartRate)
    }
    
    func autorizeHealthKit() {
        let healthKitTypes: Set = [
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!]

        healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { hasAuthorization, error in
            print(hasAuthorization)
            print(error)
        }
    }
    
    private func startHeartRateQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier) {
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        let updateHandler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = {
            query, samples, deletedObjects, queryAnchor, error in
            guard let samples = samples as? [HKQuantitySample] else {
                return
            }
            Task {
                await self.process(samples, type: quantityTypeIdentifier)
            }
            
        }
        let query = HKAnchoredObjectQuery(type: HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier)!,
                                          predicate: devicePredicate,
                                          anchor: nil,
                                          limit: HKObjectQueryNoLimit,
                                          resultsHandler: updateHandler)
        query.updateHandler = updateHandler
        healthStore.execute(query)
    }
    
    private func process(_ samples: [HKQuantitySample], type: HKQuantityTypeIdentifier) async {
        await MainActor.run {
            var lastHeartRate = 0.0
            
            for sample in samples {
                
                if type == .heartRate {
                    lastHeartRate = sample.quantity.doubleValue(for: heartRateQuantity)
                }
                self.value = Int(lastHeartRate)
            }
        }
    }
}

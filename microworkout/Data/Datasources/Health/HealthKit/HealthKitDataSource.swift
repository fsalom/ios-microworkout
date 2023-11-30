//
//  HealthKitDataSource.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 22/11/23.
//

import Foundation
import HealthKit

enum HealthKitError: Error {
    case notAuthorized
}

class HealthKitDataSource: HealthKitDataSourceProtocol {

    private let healthStore: HKHealthStore = HKHealthStore()
    private let heartRateUnit: HKUnit = HKUnit(from: "count/min")

    private func getTypesToRead() -> [HKObjectType] {
        var hkObjects = [HKObjectType]()
        for healthType in HealthKit.allCases {
            hkObjects.append(healthType.hkObject)
        }
        return hkObjects
    }

    private func requestHealthkitPermissions(authorized: @escaping (Bool) -> Void) {
        let typesToRead = Set(getTypesToRead())

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { (success, error) in
            authorized(success)
            print("Request Authorization -- Success: ", success, " Error: ", error ?? "nil")
        }
    }

    func isHealthDataAvailable() -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }
        return true
    }

    private func readHeartRate() -> [Beat] {
        var beats = [Beat]()
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
            beats = samples.map({ Beat(value: $0.quantity.doubleValue(for: self.heartRateUnit), start: $0.startDate, end: $0.endDate)})
        })
        self.healthStore.execute(sampleQuery)
        return beats
    }

    private func get24hPredicate() ->  NSPredicate{
        let today = Date()
        let startDate = Calendar.current.date(byAdding: .hour, value: -24, to: today)
        let predicate = HKQuery.predicateForSamples(withStart: startDate,end: today,options: [])
        return predicate
    }

    func log() {
        /*
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
         */
    }
}

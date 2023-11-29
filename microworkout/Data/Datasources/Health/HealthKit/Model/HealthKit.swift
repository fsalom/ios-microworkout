//
//  HealthKit.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 22/11/23.
//

import Foundation
import HealthKit

enum HealthKit: CaseIterable {
    case beats
    case steps
    case sleep

    var hkObject: HKSampleType {
        switch self {
        case .beats: return HKObjectType.quantityType(forIdentifier: .heartRate)!
        case .steps: return HKObjectType.quantityType(forIdentifier: .stepCount)!
        case .sleep: return HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        }
    }
}

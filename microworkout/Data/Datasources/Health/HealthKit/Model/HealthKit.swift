import Foundation
import HealthKit

enum HealthKit: CaseIterable {
    case beats
    case steps
    case sleep

    /// Devuelve el tipo de HealthKit de forma segura (puede ser nil si el identificador no existe)
    var hkObject: HKSampleType? {
        switch self {
        case .beats: return HKObjectType.quantityType(forIdentifier: .heartRate)
        case .steps: return HKObjectType.quantityType(forIdentifier: .stepCount)
        case .sleep: return HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
        }
    }
}

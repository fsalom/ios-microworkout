import HealthKit
import Foundation

class HealthKitManager: HealthKitManagerProtocol {
    static let shared = HealthKitManager()

    private let healthStore: HealthStoreProtocol = HealthKitStore()

    // Tipos de HealthKit como opcionales para evitar force-unwraps que pueden provocar crashes
    private let stepCountType: HKQuantityType? = HKQuantityType.quantityType(forIdentifier: .stepCount)
    private let heartRateType: HKQuantityType? = HKQuantityType.quantityType(forIdentifier: .heartRate)
    private let exerciseTimeType: HKQuantityType? = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)
    private let standingTimeType: HKQuantityType? = HKQuantityType.quantityType(forIdentifier: .appleStandTime)
    private let activeEnergyType: HKQuantityType? = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
    private let distanceType: HKQuantityType? = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)

    var store: HealthStoreProtocol { healthStore }

    init() {}

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Devuelve el estado de autorización de escritura para stepCount (proxy para saber si se pidió permiso)
    var authorizationStatus: HKAuthorizationStatus {
        guard let step = stepCountType else { return .notDetermined }
        return healthStore.authorizationStatus(for: step)
    }

    /// Solicita permisos de acceso a HealthKit
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit no está disponible en este dispositivo."]))
            return
        }

        var readTypes = Set<HKObjectType>()
        var writeTypes = Set<HKSampleType>()

        if let s = stepCountType { readTypes.insert(s); writeTypes.insert(s) }
        if let h = heartRateType { readTypes.insert(h) }
        if let e = exerciseTimeType { readTypes.insert(e) }
        if let st = standingTimeType { readTypes.insert(st) }
        if let ae = activeEnergyType { readTypes.insert(ae) }
        if let d = distanceType { readTypes.insert(d) }
        readTypes.insert(HKObjectType.workoutType())
        writeTypes.insert(HKObjectType.workoutType())

        guard !readTypes.isEmpty else {
            completion(false, NSError(domain: "HealthKit", code: 2, userInfo: [NSLocalizedDescriptionKey: "No hay tipos de HealthKit disponibles en este dispositivo."]))
            return
        }

        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
            completion(success, error)
        }
    }

    /// Obtiene el número de pasos del día actual
    func fetchStepCount(completion: @escaping (Double?, Error?) -> Void) {
        guard let stepType = stepCountType else {
            completion(nil, NSError(domain: "HealthKit", code: 3, userInfo: [NSLocalizedDescriptionKey: "Tipo stepCount no disponible."]))
            return
        }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(nil, error)
                return
            }
            let stepCount = sum.doubleValue(for: HKUnit.count())
            completion(stepCount, nil)
        }

        healthStore.execute(query)
    }

    func fetchStepCount(startDate: Date, endDate: Date, completion: @escaping ([Date: Double]?, Error?) -> Void) {
        guard let stepType = stepCountType else {
            completion(nil, NSError(domain: "HealthKit", code: 3, userInfo: [NSLocalizedDescriptionKey: "Tipo stepCount no disponible."]))
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let interval = DateComponents(day: 1) // Agrupar por día

        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: interval
        )

        query.initialResultsHandler = { _, result, error in
            guard let result = result else {
                completion(nil, error)
                return
            }

            var stepsData: [Date: Double] = [:]
            result.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    let steps = sum.doubleValue(for: .count())
                    let date = statistics.startDate
                    stepsData[date] = steps
                }
            }

            completion(stepsData, nil)
        }

        healthStore.execute(query)
    }


    /// Obtiene la última medición de frecuencia cardíaca
    func fetchLatestHeartRate(completion: @escaping (Double?, Error?) -> Void) {
        guard let hrType = heartRateType else {
            completion(nil, NSError(domain: "HealthKit", code: 4, userInfo: [NSLocalizedDescriptionKey: "Tipo heartRate no disponible."]))
            return
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: hrType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard let sample = samples?.first as? HKQuantitySample else {
                completion(nil, error)
                return
            }
            let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            completion(heartRate, nil)
        }

        healthStore.execute(query)
    }

    /// Obtiene los minutos de ejercicio del día actual
    func fetchExerciseTimeToday(completion: @escaping (Double?, Error?) -> Void) {
        guard let exType = exerciseTimeType else {
            completion(nil, NSError(domain: "HealthKit", code: 5, userInfo: [NSLocalizedDescriptionKey: "Tipo exerciseTime no disponible."]))
            return
        }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: exType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(nil, error)
                return
            }
            let exerciseMinutes = sum.doubleValue(for: HKUnit.minute())
            completion(exerciseMinutes, nil)
        }

        healthStore.execute(query)
    }

    /// Obtiene los minutos de ejercicio en un rango de fechas
    func fetchExerciseTime(startDate: Date, endDate: Date, completion: @escaping ([Date: Double]?, Error?) -> Void) {
        guard let exType = exerciseTimeType else {
            completion(nil, NSError(domain: "HealthKit", code: 5, userInfo: [NSLocalizedDescriptionKey: "Tipo exerciseTime no disponible."]))
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let interval = DateComponents(day: 1) // Agrupar por día

        let query = HKStatisticsCollectionQuery(
            quantityType: exType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: interval
        )

        query.initialResultsHandler = { _, result, error in
            guard let result = result else {
                completion(nil, error)
                return
            }

            var exerciseData: [Date: Double] = [:]
            result.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    let minutes = sum.doubleValue(for: HKUnit.minute())
                    let date = statistics.startDate
                    exerciseData[date] = minutes
                }
            }

            completion(exerciseData, nil)
        }

        healthStore.execute(query)
    }

    /// Obtiene los minutos de ejercicio en un rango de fechas
    func fetchStandingTime(completion: @escaping (Double?, Error?) -> Void) {
        // Este método pedía autorización internamente; dejamos la lógica pero evitamos crashes si el tipo no existe
        requestAuthorization { success, error in
            if success {
                guard let stType = self.standingTimeType else {
                    completion(nil, NSError(domain: "HealthKit", code: 6, userInfo: [NSLocalizedDescriptionKey: "Tipo standingTime no disponible."]))
                    return
                }

                let now = Date()
                let startOfDay = Calendar.current.startOfDay(for: now)
                let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

                let query = HKStatisticsQuery(quantityType: stType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                    guard let result = result, let sum = result.sumQuantity() else {
                        completion(nil, error)
                        return
                    }

                    let seconds = sum.doubleValue(for: .second())
                    let minutes = seconds / 60

                    completion(minutes, nil)
                }

                self.healthStore.execute(query)
            } else {
                completion(nil, error)
            }
        }
    }

    func fetchStandingTime(startDate: Date, endDate: Date, completion: @escaping ([Date: Double]?, Error?) -> Void) {
        guard let stType = standingTimeType else {
            completion(nil, NSError(domain: "HealthKit", code: 6, userInfo: [NSLocalizedDescriptionKey: "Tipo standingTime no disponible."]))
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let interval = DateComponents(day: 1) // Agrupar por día

        let query = HKStatisticsCollectionQuery(
            quantityType: stType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: interval
        )

        query.initialResultsHandler = { _, result, error in
            guard let result = result else {
                completion(nil, error)
                return
            }

            var standingData: [Date: Double] = [:]
            result.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    let seconds = sum.doubleValue(for: .second())
                    let minutes = seconds / 60
                    let date = statistics.startDate
                    standingData[date] = minutes
                }
            }

            completion(standingData, nil)
        }

        healthStore.execute(query)
    }
}

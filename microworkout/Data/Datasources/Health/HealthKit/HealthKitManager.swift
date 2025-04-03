import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    private let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    private let exerciseTimeType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!

    private init() {}

    /// Solicita permisos de acceso a HealthKit
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit no está disponible en este dispositivo."]))
            return
        }

        let readTypes: Set<HKObjectType> = [stepCountType, heartRateType, exerciseTimeType]
        let writeTypes: Set<HKSampleType> = [stepCountType]

        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
            completion(success, error)
        }
    }

    /// Obtiene el número de pasos del día actual
    func fetchStepCount(completion: @escaping (Double?, Error?) -> Void) {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepCountType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(nil, error)
                return
            }
            let stepCount = sum.doubleValue(for: HKUnit.count())
            completion(stepCount, nil)
        }

        healthStore.execute(query)
    }

    /// Obtiene la última medición de frecuencia cardíaca
    func fetchLatestHeartRate(completion: @escaping (Double?, Error?) -> Void) {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
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
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: exerciseTimeType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
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
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let interval = DateComponents(day: 1) // Agrupar por día

        let query = HKStatisticsCollectionQuery(
            quantityType: exerciseTimeType,
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
}

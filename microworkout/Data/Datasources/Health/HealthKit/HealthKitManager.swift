import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    private let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    private let exerciseTimeType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!
    private let standingTimeType = HKQuantityType.quantityType(forIdentifier: .appleStandTime)!

    private init() {}

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Devuelve el estado de autorización de escritura para stepCount (proxy para saber si se pidió permiso)
    var authorizationStatus: HKAuthorizationStatus {
        healthStore.authorizationStatus(for: stepCountType)
    }

    /// Solicita permisos de acceso a HealthKit
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit no está disponible en este dispositivo."]))
            return
        }

        let readTypes: Set<HKObjectType> = [stepCountType, heartRateType, exerciseTimeType, standingTimeType, HKObjectType.workoutType()]
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

    func fetchStepCount(startDate: Date, endDate: Date, completion: @escaping ([Date: Double]?, Error?) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let interval = DateComponents(day: 1) // Agrupar por día

        let query = HKStatisticsCollectionQuery(
            quantityType: stepCountType,
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

    /// Obtiene los minutos de ejercicio en un rango de fechas
    func fetchStandingTime(completion: @escaping (Double?, Error?) -> Void) {
        requestAuthorization { success, error in
            if success {
                let now = Date()
                let startOfDay = Calendar.current.startOfDay(for: now)
                let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

                let query = HKStatisticsQuery(quantityType: self.standingTimeType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                    guard let result = result, let sum = result.sumQuantity() else {
                        completion(nil, error)
                        return
                    }

                    let seconds = sum.doubleValue(for: .second())
                    let minutes = seconds / 60

                    completion(minutes, nil)
                }

                self.healthStore.execute(query)
            }
        }
    }

    func fetchStandingTime(startDate: Date, endDate: Date, completion: @escaping ([Date: Double]?, Error?) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let interval = DateComponents(day: 1) // Agrupar por día

        let query = HKStatisticsCollectionQuery(
            quantityType: standingTimeType,
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
                    let seconds = sum.doubleValue(for: .second())
                    let minutes = seconds / 60
                    //let minutes = sum.doubleValue(for: HKUnit.minute())
                    let date = statistics.startDate
                    exerciseData[date] = minutes
                }
            }

            completion(exerciseData, nil)
        }

        healthStore.execute(query)
    }

    /// Obtiene los workouts de los ultimos 7 dias
    func fetchWorkouts(completion: @escaping ([HKWorkout]?, Error?) -> Void) {
        let now = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: sevenDaysAgo, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(
            sampleType: HKObjectType.workoutType(),
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            let workouts = samples as? [HKWorkout]
            completion(workouts, error)
        }

        healthStore.execute(query)
    }

    /// Obtiene la frecuencia cardiaca media de un workout usando statistics (iOS 16+)
    func fetchAverageHeartRate(for workout: HKWorkout, completion: @escaping (Double?) -> Void) {
        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(
            withStart: workout.startDate,
            end: workout.endDate,
            options: .strictStartDate
        )

        let query = HKStatisticsQuery(
            quantityType: hrType,
            quantitySamplePredicate: predicate,
            options: .discreteAverage
        ) { _, result, _ in
            guard let avg = result?.averageQuantity() else {
                completion(nil)
                return
            }
            let bpm = avg.doubleValue(for: HKUnit(from: "count/min"))
            completion(bpm)
        }

        healthStore.execute(query)
    }
}

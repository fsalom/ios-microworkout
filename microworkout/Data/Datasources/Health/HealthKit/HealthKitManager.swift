import HealthKit
import Foundation

class HealthKitManager: HealthKitManagerProtocol {
    private let healthStore: HealthStoreProtocol = HealthKitStore()

    private let stepCountType: HKQuantityType? = HKQuantityType.quantityType(forIdentifier: .stepCount)
    private let heartRateType: HKQuantityType? = HKQuantityType.quantityType(forIdentifier: .heartRate)
    private let exerciseTimeType: HKQuantityType? = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)
    private let standingTimeType: HKQuantityType? = HKQuantityType.quantityType(forIdentifier: .appleStandTime)
    private let activeEnergyType: HKQuantityType? = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
    private let distanceType: HKQuantityType? = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)
    private let bodyMassType: HKQuantityType? = HKQuantityType.quantityType(forIdentifier: .bodyMass)
    private let restingHeartRateType: HKQuantityType? = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)

    var store: HealthStoreProtocol { healthStore }

    init() {}

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Estado de autorización de escritura para stepCount (proxy para saber si se pidió permiso).
    var authorizationStatus: HKAuthorizationStatus {
        guard let step = stepCountType else { return .notDetermined }
        return healthStore.authorizationStatus(for: step)
    }

    // MARK: - Auth

    func requestAuthorization() async throws -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit no está disponible en este dispositivo."])
        }

        var readTypes = Set<HKObjectType>()
        var writeTypes = Set<HKSampleType>()

        if let s = stepCountType { readTypes.insert(s); writeTypes.insert(s) }
        if let h = heartRateType { readTypes.insert(h) }
        if let e = exerciseTimeType { readTypes.insert(e) }
        if let st = standingTimeType { readTypes.insert(st) }
        if let ae = activeEnergyType { readTypes.insert(ae) }
        if let d = distanceType { readTypes.insert(d) }
        // El peso se pide de lectura Y escritura: Salud es la fuente (ahí escribe
        // la báscula) y lo que el usuario anote en la app se devuelve allí, para
        // no acabar con dos historiales que se contradicen.
        if let bm = bodyMassType { readTypes.insert(bm); writeTypes.insert(bm) }
        // La FC en reposo solo se lee: la calcula el reloj y no somos quién para
        // escribirla.
        if let rhr = restingHeartRateType { readTypes.insert(rhr) }
        readTypes.insert(HKObjectType.workoutType())
        writeTypes.insert(HKObjectType.workoutType())

        guard !readTypes.isEmpty else {
            throw NSError(domain: "HealthKit", code: 2, userInfo: [NSLocalizedDescriptionKey: "No hay tipos de HealthKit disponibles en este dispositivo."])
        }

        return try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }

    // MARK: - Step count

    func fetchStepCount() async throws -> Double? {
        guard let stepType = stepCountType else {
            throw NSError(domain: "HealthKit", code: 3, userInfo: [NSLocalizedDescriptionKey: "Tipo stepCount no disponible."])
        }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        return try await cumulativeSum(quantityType: stepType, from: startOfDay, to: now, unit: .count())
    }

    func fetchStepCount(startDate: Date, endDate: Date) async throws -> [Date: Double]? {
        guard let stepType = stepCountType else {
            throw NSError(domain: "HealthKit", code: 3, userInfo: [NSLocalizedDescriptionKey: "Tipo stepCount no disponible."])
        }
        return try await dailyCumulativeSum(quantityType: stepType, from: startDate, to: endDate, unit: .count())
    }

    // MARK: - Heart rate

    func fetchLatestHeartRate() async throws -> Double? {
        guard let hrType = heartRateType else {
            throw NSError(domain: "HealthKit", code: 4, userInfo: [NSLocalizedDescriptionKey: "Tipo heartRate no disponible."])
        }
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double?, Error>) in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: hrType, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: HKUnit(from: "count/min")))
            }
            healthStore.execute(query)
        }
    }

    func fetchAverageHeartRate(for workout: HKWorkout) async -> Double? {
        guard let hrType = heartRateType else { return nil }
        return await withCheckedContinuation { (continuation: CheckedContinuation<Double?, Never>) in
            let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
            let query = HKStatisticsQuery(quantityType: hrType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, _ in
                continuation.resume(returning: result?.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min")))
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Exercise time

    func fetchExerciseTimeToday() async throws -> Double? {
        guard let exType = exerciseTimeType else {
            throw NSError(domain: "HealthKit", code: 5, userInfo: [NSLocalizedDescriptionKey: "Tipo exerciseTime no disponible."])
        }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        return try await cumulativeSum(quantityType: exType, from: startOfDay, to: now, unit: .minute())
    }

    func fetchExerciseTime(startDate: Date, endDate: Date) async throws -> [Date: Double]? {
        guard let exType = exerciseTimeType else {
            throw NSError(domain: "HealthKit", code: 5, userInfo: [NSLocalizedDescriptionKey: "Tipo exerciseTime no disponible."])
        }
        return try await dailyCumulativeSum(quantityType: exType, from: startDate, to: endDate, unit: .minute())
    }

    // MARK: - Standing time

    func fetchStandingTime() async throws -> Double? {
        guard let stType = standingTimeType else {
            throw NSError(domain: "HealthKit", code: 6, userInfo: [NSLocalizedDescriptionKey: "Tipo standingTime no disponible."])
        }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        // HK guarda standing time en segundos; lo convertimos a minutos al final.
        let seconds = try await cumulativeSum(quantityType: stType, from: startOfDay, to: now, unit: .second())
        return seconds.map { $0 / 60 }
    }

    func fetchStandingTime(startDate: Date, endDate: Date) async throws -> [Date: Double]? {
        guard let stType = standingTimeType else {
            throw NSError(domain: "HealthKit", code: 6, userInfo: [NSLocalizedDescriptionKey: "Tipo standingTime no disponible."])
        }
        let secondsByDay = try await dailyCumulativeSum(quantityType: stType, from: startDate, to: endDate, unit: .second())
        return secondsByDay?.mapValues { $0 / 60 }
    }

    // MARK: - Peso

    /// Peso por día en el rango, en kilos.
    ///
    /// `.discreteMostRecent` y no una media: si te pesas tres veces un martes, el
    /// peso de ese martes es el último, no el promedio de las tres. Coincide con
    /// la regla del servidor (una medida por día, gana la última).
    func fetchBodyMass(startDate: Date, endDate: Date) async throws -> [Date: Double] {
        guard let bodyMassType else {
            throw NSError(domain: "HealthKit", code: 7, userInfo: [NSLocalizedDescriptionKey: "Tipo bodyMass no disponible."])
        }
        return try await dailyStatistic(
            quantityType: bodyMassType,
            from: startDate,
            to: endDate,
            options: .discreteMostRecent,
            unit: .gramUnit(with: .kilo),
            value: { $0.mostRecentQuantity() }
        )
    }

    /// Escribe un peso en Salud con la fecha indicada.
    func saveBodyMass(kilograms: Double, on date: Date) async throws {
        guard let bodyMassType else {
            throw NSError(domain: "HealthKit", code: 7, userInfo: [NSLocalizedDescriptionKey: "Tipo bodyMass no disponible."])
        }
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kilograms)
        let sample = HKQuantitySample(
            type: bodyMassType, quantity: quantity, start: date, end: date
        )
        try await healthStore.save(sample)
    }

    // MARK: - Energía activa y recuperación

    func fetchActiveEnergy(startDate: Date, endDate: Date) async throws -> [Date: Double] {
        guard let activeEnergyType else {
            throw NSError(domain: "HealthKit", code: 8, userInfo: [NSLocalizedDescriptionKey: "Tipo activeEnergy no disponible."])
        }
        let byDay = try await dailyCumulativeSum(
            quantityType: activeEnergyType, from: startDate, to: endDate, unit: .kilocalorie()
        )
        return byDay ?? [:]
    }

    /// Frecuencia cardiaca en reposo por día.
    ///
    /// `.discreteAverage` y no una suma: promediar es lo único que significa algo
    /// en una medida instantánea. Aun así el reloj suele dar un valor al día.
    func fetchRestingHeartRate(startDate: Date, endDate: Date) async throws -> [Date: Double] {
        guard let restingHeartRateType else {
            throw NSError(domain: "HealthKit", code: 9, userInfo: [NSLocalizedDescriptionKey: "Tipo restingHeartRate no disponible."])
        }
        return try await dailyStatistic(
            quantityType: restingHeartRateType,
            from: startDate,
            to: endDate,
            options: .discreteAverage,
            unit: HKUnit(from: "count/min"),
            value: { $0.averageQuantity() }
        )
    }

    // MARK: - Workouts

    func fetchWorkouts() async throws -> [HKWorkout] {
        try await withCheckedThrowingContinuation { continuation in
            let workoutType = HKObjectType.workoutType()
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: workoutType, predicate: nil, limit: 50, sortDescriptors: [sort]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (samples as? [HKWorkout]) ?? [])
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Helpers

    /// Suma acumulada de un quantity type en un rango simple (un único bucket).
    private func cumulativeSum(quantityType: HKQuantityType, from start: Date, to end: Date, unit: HKUnit) async throws -> Double? {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double?, Error>) in
            let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: result?.sumQuantity()?.doubleValue(for: unit))
            }
            healthStore.execute(query)
        }
    }

    /// Un valor por día para métricas que NO se suman (peso, FC en reposo).
    ///
    /// Los días sin muestra se omiten en vez de rellenarse con cero: un hueco en
    /// la serie es información — "no me pesé" no es "peso cero" — y rellenarlo
    /// hundiría cualquier media que se calcule después.
    private func dailyStatistic(
        quantityType: HKQuantityType,
        from start: Date,
        to end: Date,
        options: HKStatisticsOptions,
        unit: HKUnit,
        value: @escaping (HKStatistics) -> HKQuantity?
    ) async throws -> [Date: Double] {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let anchor = Calendar.current.startOfDay(for: start)
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[Date: Double], Error>) in
            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: options,
                anchorDate: anchor,
                intervalComponents: DateComponents(day: 1)
            )
            query.initialResultsHandler = { _, result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result else {
                    continuation.resume(returning: [:])
                    return
                }
                var byDay: [Date: Double] = [:]
                result.enumerateStatistics(from: anchor, to: end) { statistics, _ in
                    guard let quantity = value(statistics) else { return }
                    byDay[Calendar.current.startOfDay(for: statistics.startDate)] =
                        quantity.doubleValue(for: unit)
                }
                continuation.resume(returning: byDay)
            }
            healthStore.execute(query)
        }
    }

    /// Suma acumulada agrupada por día, devuelve diccionario fecha → valor.
    private func dailyCumulativeSum(quantityType: HKQuantityType, from start: Date, to end: Date, unit: HKUnit) async throws -> [Date: Double]? {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[Date: Double]?, Error>) in
            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: start,
                intervalComponents: DateComponents(day: 1)
            )
            query.initialResultsHandler = { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result = result else {
                    continuation.resume(returning: nil)
                    return
                }
                var dataByDay: [Date: Double] = [:]
                result.enumerateStatistics(from: start, to: end) { statistics, _ in
                    if let sum = statistics.sumQuantity() {
                        dataByDay[statistics.startDate] = sum.doubleValue(for: unit)
                    }
                }
                continuation.resume(returning: dataByDay)
            }
            healthStore.execute(query)
        }
    }
}

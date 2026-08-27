import Foundation

/// Gasto energético REAL estimado a partir de lo registrado.
///
/// Mifflin-St Jeor es una estimación de partida: dos personas con los mismos datos
/// gastan distinto. Pero la app tiene lo necesario para medirlo de verdad: cuánto
/// comes (comidas registradas) y qué hace tu peso (báscula/Salud). Si comes 2.000
/// kcal/día y pierdes 0,3 kg/semana, tu gasto ronda 2.000 + 330 = 2.330 — sin
/// fórmulas de población, con TUS números.
struct TDEEEstimate: Equatable {
    /// Gasto diario estimado, en kcal.
    let tdee: Double
    /// Tendencia de peso medida en la ventana (negativo = pierdes).
    let weeklyChangeKg: Double
    /// Ingesta media de los días bien registrados.
    let meanDailyIntake: Double
    /// Días con registro de comida plausible dentro de la ventana.
    let loggedDays: Int
    /// Pesadas usadas y días que abarcan (primera → última).
    let weighInCount: Int
    let spanDays: Int

    /// Objetivo diario coherente con este gasto y el objetivo físico del usuario.
    /// El mismo ajuste (−500/0/+300) que aplica la fórmula, sobre el gasto real.
    func suggestedTarget(for goal: UserProfile.FitnessGoal) -> Double {
        tdee + goal.calorieAdjustment
    }
}

/// El cálculo, puro y sin dependencias para poder someterlo a tests con fechas
/// controladas. Las decisiones que encierra:
///
/// - **Regresión sobre las pesadas**, no primera-menos-última: el peso diario baila
///   ±1 kg de agua, y dos puntos sueltos pueden decir lo contrario que la tendencia.
/// - **Días a medio registrar fuera**: un día con un café anotado (300 kcal) no es
///   un día de 300 kcal, es un día sin registrar. Contarlo hundiría la ingesta
///   media y con ella el gasto estimado.
/// - **Umbrales mínimos** de datos: sin suficientes días y pesadas, la respuesta
///   honesta es "todavía no lo sé", no un número con autoridad falsa.
enum AdaptiveTDEECalculator {
    /// Ventana que se mira hacia atrás.
    static let windowDays = 28
    /// Un día con menos de esto registrado se considera a medio registrar.
    static let minPlausibleDayKcal: Double = 800
    /// Mínimo de días bien registrados dentro del tramo de pesadas.
    static let minLoggedDays = 14
    /// Mínimo de pesadas y de días entre la primera y la última.
    static let minWeighIns = 4
    static let minSpanDays = 14
    /// kcal por kg de peso corporal (mezcla típica de grasa y magro).
    static let kcalPerKg: Double = 7_700
    /// Fuera de este rango el dato es basura (registro roto), no un gasto.
    static let sanityRange: ClosedRange<Double> = 1_000...6_000

    /// - Parameters:
    ///   - intakeByDay: kcal totales registradas por día (inicio de día local).
    ///   - weighIns: pesadas fechadas, en kg. No hace falta que estén ordenadas.
    static func estimate(
        intakeByDay: [Date: Double],
        weighIns: [(date: Date, kg: Double)],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> TDEEEstimate? {
        let windowStart = calendar.date(byAdding: .day, value: -windowDays, to: now) ?? now
        let weights = weighIns
            .filter { $0.date >= windowStart && $0.date <= now }
            .sorted { $0.date < $1.date }

        guard weights.count >= minWeighIns,
              let first = weights.first, let last = weights.last else { return nil }
        let spanDays = calendar.dateComponents([.day], from: first.date, to: last.date).day ?? 0
        guard spanDays >= minSpanDays else { return nil }

        // Pendiente (kg/día) por mínimos cuadrados sobre (días desde la primera, kg).
        let points = weights.map { weight -> (x: Double, y: Double) in
            (x: weight.date.timeIntervalSince(first.date) / 86_400, y: weight.kg)
        }
        let n = Double(points.count)
        let sumX = points.reduce(0) { $0 + $1.x }
        let sumY = points.reduce(0) { $0 + $1.y }
        let sumXY = points.reduce(0) { $0 + $1.x * $1.y }
        let sumX2 = points.reduce(0) { $0 + $1.x * $1.x }
        let denominator = n * sumX2 - sumX * sumX
        guard denominator != 0 else { return nil }
        let slopeKgPerDay = (n * sumXY - sumX * sumY) / denominator

        // La ingesta se compara SOLO dentro del tramo que cubren las pesadas: el
        // balance energético es "lo comido entre estas dos medidas de peso".
        let validDays = intakeByDay.filter { day, kcal in
            day >= calendar.startOfDay(for: first.date)
                && day <= last.date
                && kcal >= minPlausibleDayKcal
        }
        guard validDays.count >= minLoggedDays else { return nil }
        let meanIntake = validDays.values.reduce(0, +) / Double(validDays.count)

        let tdee = meanIntake - slopeKgPerDay * kcalPerKg
        guard sanityRange.contains(tdee) else { return nil }

        return TDEEEstimate(
            tdee: tdee,
            weeklyChangeKg: slopeKgPerDay * 7,
            meanDailyIntake: meanIntake,
            loggedDays: validDays.count,
            weighInCount: weights.count,
            spanDays: spanDays
        )
    }
}

protocol AdaptiveTDEEUseCaseProtocol {
    /// La estimación con los datos actuales, o `nil` si aún no hay suficientes.
    /// No lanza: sin datos no es un error, es un "todavía no".
    func estimate() async -> TDEEEstimate?
}

final class AdaptiveTDEEUseCase: AdaptiveTDEEUseCaseProtocol {
    private let mealUseCase: MealUseCaseProtocol
    private let bodyMetricsUseCase: BodyMetricsUseCaseProtocol

    init(mealUseCase: MealUseCaseProtocol, bodyMetricsUseCase: BodyMetricsUseCaseProtocol) {
        self.mealUseCase = mealUseCase
        self.bodyMetricsUseCase = bodyMetricsUseCase
    }

    func estimate() async -> TDEEEstimate? {
        let calendar = Calendar.current
        let now = Date()
        let windowStart = calendar.date(
            byAdding: .day, value: -AdaptiveTDEECalculator.windowDays, to: now
        ) ?? now

        // Cada fuente con su `try?`: sin peso o sin comidas simplemente no hay
        // estimación todavía.
        let meals = (try? await mealUseCase.getMeals(from: windowStart, to: now)) ?? []
        let metrics = (try? await bodyMetricsUseCase.getRecent(
            days: AdaptiveTDEECalculator.windowDays
        )) ?? []

        var intakeByDay: [Date: Double] = [:]
        for meal in meals {
            let day = calendar.startOfDay(for: meal.timestamp)
            intakeByDay[day, default: 0] += meal.totalNutrition.calories
        }

        let weighIns = metrics.compactMap { metric -> (date: Date, kg: Double)? in
            guard let kg = metric.weightKg else { return nil }
            return (date: metric.date, kg: kg)
        }

        return AdaptiveTDEECalculator.estimate(
            intakeByDay: intakeByDay, weighIns: weighIns, now: now, calendar: calendar
        )
    }
}

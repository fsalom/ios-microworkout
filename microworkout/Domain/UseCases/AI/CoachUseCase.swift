import Foundation

/// Implementación temporal: genera insights "mock" derivados de datos reales del
/// usuario (logs, comidas, salud). Cuando conectemos un modelo real, sustituye el
/// cuerpo de cada función por una llamada al modelo pasando `AIContext` y el prompt
/// adecuado.
class CoachUseCase: CoachUseCaseProtocol {
    private let contextUseCase: AIContextUseCaseProtocol

    init(contextUseCase: AIContextUseCaseProtocol) {
        self.contextUseCase = contextUseCase
    }

    func workoutInsight() async -> CoachInsight {
        let ctx = await contextUseCase.buildContext(mealDaysBack: 0, healthWeeksBack: 1)
        let logs = ctx.workoutLogs.sorted { $0.startedAt > $1.startedAt }
        let recent = logs.prefix(7)
        let exerciseStats = collectExerciseStats(from: Array(recent))

        let title: String
        let body: String
        var bullets: [String] = []

        if logs.isEmpty {
            title = "Empieza a registrar tus entrenos"
            body = "Cuando guardes algunos entrenamientos, te daré recomendaciones de progresión por ejercicio."
        } else if exerciseStats.isEmpty {
            title = "Próxima semana: añade peso poco a poco"
            body = "Estás registrando series sin peso. Si añades carga te diré cuándo subir."
        } else {
            title = "Próxima semana: sube empuje, mantén pierna"
            body = "Análisis de tus últimas \(recent.count) sesiones."
            bullets = exerciseStats.prefix(4).map { stat in
                let trend = stat.suggestion
                return "\(stat.name): \(trend)"
            }
        }

        return CoachInsight(
            kind: .workout,
            title: title,
            body: body,
            bullets: bullets,
            prompt: "¿Cómo progreso la próxima semana en mis ejercicios?"
        )
    }

    func nutritionInsight() async -> CoachInsight {
        let ctx = await contextUseCase.buildContext(mealDaysBack: 1, healthWeeksBack: 0)
        let cal = Calendar.current
        let today = ctx.meals.filter { cal.isDateInToday($0.timestamp) }

        var kcal: Double = 0
        var protein: Double = 0
        var carbs: Double = 0
        var fats: Double = 0
        for meal in today {
            kcal += meal.totalNutrition.calories
            protein += meal.totalNutrition.proteinsG
            carbs += meal.totalNutrition.carbohydratesG
            fats += meal.totalNutrition.fatsG
        }

        let target = ctx.profile?.todayCalorieTarget ?? 0
        let macros = ctx.profile?.macroTargets

        let title = nutritionTitle(today: today, kcal: kcal, target: target)
        let body = today.isEmpty
            ? "Cuando añadas algo te diré cómo encaja con tu objetivo del día."
            : "Estado de tus macros del día."

        var bullets: [String] = []
        if !today.isEmpty {
            if let m = macros {
                bullets.append(macroLine("Proteína", current: protein, target: m.proteinsG, unit: "g"))
                bullets.append(macroLine("Carbos", current: carbs, target: m.carbohydratesG, unit: "g"))
                bullets.append(macroLine("Grasa", current: fats, target: m.fatsG, unit: "g"))
            } else {
                bullets.append("Proteína: \(Int(protein))g")
                bullets.append("Carbos: \(Int(carbs))g")
                bullets.append("Grasa: \(Int(fats))g")
            }
        }

        return CoachInsight(
            kind: .nutrition,
            title: title,
            body: body,
            bullets: bullets,
            prompt: "Analiza mis comidas de hoy y dame recomendaciones."
        )
    }

    private func nutritionTitle(today: [AIMealSnapshot], kcal: Double, target: Double) -> String {
        if today.isEmpty {
            return "Aún no has registrado comidas hoy"
        }
        guard target > 0 else {
            return "\(Int(kcal)) kcal hoy"
        }
        let diff = target - kcal
        if diff > 200 { return "Te quedan \(Int(diff)) kcal por comer" }
        if diff < -200 { return "Te has pasado \(Int(-diff)) kcal del objetivo" }
        return "Vas en línea con tu objetivo"
    }

    func homeInsight() async -> CoachInsight {
        let ctx = await contextUseCase.buildContext(mealDaysBack: 7, healthWeeksBack: 1)
        let cal = Calendar.current
        let last7 = ctx.workoutLogs.filter {
            guard let days = cal.dateComponents([.day], from: $0.startedAt, to: Date()).day else { return false }
            return days < 7
        }.count
        let kcalToday = ctx.meals
            .filter { cal.isDateInToday($0.timestamp) }
            .reduce(0.0) { $0 + $1.totalNutrition.calories }
        let stepsToday = ctx.healthDays.first(where: { cal.isDateInToday($0.date) })?.steps ?? 0

        let title = "Resumen del día"
        var bullets: [String] = []
        bullets.append("Entrenos esta semana: \(last7)")
        if kcalToday > 0 {
            bullets.append("Has comido \(Int(kcalToday)) kcal hoy")
        } else {
            bullets.append("Aún no has registrado comidas hoy")
        }
        if stepsToday > 0 {
            bullets.append("Pasos: \(stepsToday)")
        }

        let body = "Visión rápida de tu día."

        return CoachInsight(
            kind: .home,
            title: title,
            body: body,
            bullets: bullets,
            prompt: "Hazme un resumen del día y de la semana."
        )
    }

    // MARK: - Helpers

    private struct ExerciseStat {
        let name: String
        let firstTopWeight: Double
        let lastTopWeight: Double

        var suggestion: String {
            if lastTopWeight > firstTopWeight {
                let diff = lastTopWeight - firstTopWeight
                return "subes \(format(diff)) kg → mantén"
            } else if lastTopWeight < firstTopWeight {
                return "estancado en \(format(lastTopWeight)) kg → repite"
            } else {
                return "estable en \(format(lastTopWeight)) kg → +2.5 kg"
            }
        }

        private func format(_ v: Double) -> String {
            v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.1f", v)
        }
    }

    private func collectExerciseStats(from logs: [AIWorkoutLogSnapshot]) -> [ExerciseStat] {
        var byName: [String: [(date: Date, top: Double)]] = [:]
        for log in logs {
            for ex in log.exercises {
                let topWeight = ex.sets.compactMap { $0.weightKg }.max() ?? 0
                guard topWeight > 0 else { continue }
                byName[ex.name, default: []].append((log.startedAt, topWeight))
            }
        }
        return byName.compactMap { name, points in
            let sorted = points.sorted { $0.date < $1.date }
            guard let first = sorted.first, let last = sorted.last else { return nil }
            return ExerciseStat(name: name, firstTopWeight: first.top, lastTopWeight: last.top)
        }
        .sorted { $0.name < $1.name }
    }

    private func macroLine(_ label: String, current: Double, target: Double, unit: String) -> String {
        guard target > 0 else { return "\(label): \(Int(current))\(unit)" }
        let diff = target - current
        if abs(diff) < 5 {
            return "\(label): \(Int(current))/\(Int(target))\(unit) ✅"
        }
        let sign = diff > 0 ? "−" : "+"
        return "\(label): \(Int(current))/\(Int(target))\(unit) (\(sign)\(Int(abs(diff)))\(unit))"
    }
}

import Foundation

/// Consejo calculado en el dispositivo, sin modelo.
///
/// Es el plan B de `CoachUseCase`: en modo invitado no hay backend al que llamar,
/// y con la red caída o el servidor caído la tarjeta seguiría teniendo que decir
/// algo. Son las mismas reglas que la app usaba antes de conectar la IA.
///
/// Sus insights se marcan con `isFromModel = false` para no atribuirle al modelo
/// algo que ha calculado un `if`.
struct HeuristicCoach {

    func insight(for topic: AICoachTopic, context: AIContext) -> CoachInsight {
        switch topic {
        case .workout: return workout(context)
        case .plan: return plan(context)
        case .nutrition: return nutrition(context)
        case .daily, .free: return daily(context)
        }
    }

    // MARK: - Entreno

    private func workout(_ context: AIContext) -> CoachInsight {
        let logs = context.workoutLogs.sorted { $0.startedAt > $1.startedAt }
        let recent = Array(logs.prefix(7))
        let stats = exerciseStats(from: recent)

        let title: String
        let body: String
        var bullets: [String] = []

        if logs.isEmpty {
            title = "Empieza a registrar tus entrenos"
            body = "Cuando guardes algunos entrenamientos te diré cómo progresar por ejercicio."
        } else if stats.isEmpty {
            title = "Añade peso a tus series"
            body = "Estás registrando series sin carga. Si la anotas, puedo decirte cuándo subir."
        } else {
            title = "Progresión de tus últimas \(recent.count) sesiones"
            body = "Comparativa entre la primera y la última vez que hiciste cada ejercicio."
            bullets = stats.prefix(4).map { "\($0.name): \($0.suggestion)" }
        }

        return CoachInsight(
            topic: .workout,
            title: title,
            body: body,
            bullets: bullets,
            prompt: "¿Cómo progreso la próxima semana en mis ejercicios?"
        )
    }

    // MARK: - Plan

    private func plan(_ context: AIContext) -> CoachInsight {
        let sessions = context.workoutSessions
        guard !sessions.isEmpty else {
            return CoachInsight(
                topic: .plan,
                title: "Aún no tienes plan definido",
                body: "Crea plantillas de sesión y podré revisar su estructura y tu adherencia.",
                prompt: "¿Cómo debería estructurar mi plan de entrenamiento?"
            )
        }

        let calendar = Calendar.current
        var lastByName: [String: Date] = [:]
        var countByName: [String: Int] = [:]
        for log in context.workoutLogs {
            let key = log.sessionName.lowercased()
            lastByName[key] = max(lastByName[key] ?? .distantPast, log.startedAt)
            countByName[key] = (countByName[key] ?? 0) + 1
        }

        let stale = sessions.filter { session in
            guard let last = lastByName[session.name.lowercased()] else { return true }
            guard let days = calendar.dateComponents([.day], from: last, to: Date()).day else { return true }
            return days > 14
        }

        let bullets = sessions.prefix(4).map { session -> String in
            let key = session.name.lowercased()
            let times = countByName[key] ?? 0
            guard let last = lastByName[key] else {
                return "\(session.name): definida pero nunca ejecutada"
            }
            let days = calendar.dateComponents([.day], from: last, to: Date()).day ?? 0
            return "\(session.name): \(times) veces, última hace \(days) d"
        }

        let title = stale.isEmpty
            ? "Plan al día: \(sessions.count) sesiones activas"
            : "\(stale.count) de \(sessions.count) sesiones sin tocar"

        return CoachInsight(
            topic: .plan,
            title: title,
            body: stale.isEmpty
                ? "Estás rotando todas las sesiones que tienes definidas."
                : "Hay sesiones definidas que llevas más de dos semanas sin hacer.",
            bullets: Array(bullets),
            prompt: "¿Cómo puedo mejorar la estructura de mi plan de entrenamiento?"
        )
    }

    // MARK: - Nutrición

    private func nutrition(_ context: AIContext) -> CoachInsight {
        let calendar = Calendar.current
        let todayMeals = context.meals.filter { calendar.isDateInToday($0.timestamp) }

        var kcal = 0.0, protein = 0.0, carbs = 0.0, fats = 0.0
        for meal in todayMeals {
            kcal += meal.totalNutrition.calories
            protein += meal.totalNutrition.proteinsG
            carbs += meal.totalNutrition.carbohydratesG
            fats += meal.totalNutrition.fatsG
        }

        let target = context.profile?.todayCalorieTarget ?? 0
        let macros = context.profile?.macroTargets

        var bullets: [String] = []
        if !todayMeals.isEmpty {
            if let macros {
                bullets = [
                    macroLine("Proteína", current: protein, target: macros.proteinsG),
                    macroLine("Carbos", current: carbs, target: macros.carbohydratesG),
                    macroLine("Grasa", current: fats, target: macros.fatsG)
                ]
            } else {
                bullets = [
                    "Proteína: \(Int(protein))g",
                    "Carbos: \(Int(carbs))g",
                    "Grasa: \(Int(fats))g"
                ]
            }
        }

        return CoachInsight(
            topic: .nutrition,
            title: nutritionTitle(mealCount: todayMeals.count, kcal: kcal, target: target),
            body: todayMeals.isEmpty
                ? "Cuando añadas algo te diré cómo encaja con tu objetivo del día."
                : "Estado de tus macros de hoy.",
            bullets: bullets,
            prompt: "Analiza mis comidas de hoy y dame recomendaciones."
        )
    }

    private func nutritionTitle(mealCount: Int, kcal: Double, target: Double) -> String {
        if mealCount == 0 { return "Aún no has registrado comidas hoy" }
        guard target > 0 else { return "\(Int(kcal)) kcal hoy" }
        let diff = target - kcal
        if diff > 200 { return "Te quedan \(Int(diff)) kcal por comer" }
        if diff < -200 { return "Te has pasado \(Int(-diff)) kcal del objetivo" }
        return "Vas en línea con tu objetivo"
    }

    private func macroLine(_ label: String, current: Double, target: Double) -> String {
        guard target > 0 else { return "\(label): \(Int(current))g" }
        let diff = target - current
        if abs(diff) < 5 { return "\(label): \(Int(current))/\(Int(target))g ✅" }
        let sign = diff > 0 ? "−" : "+"
        return "\(label): \(Int(current))/\(Int(target))g (\(sign)\(Int(abs(diff)))g)"
    }

    // MARK: - Día

    private func daily(_ context: AIContext) -> CoachInsight {
        let calendar = Calendar.current
        let weekLogs = context.workoutLogs.filter {
            guard let days = calendar.dateComponents([.day], from: $0.startedAt, to: Date()).day else {
                return false
            }
            return days < 7
        }.count
        let kcalToday = context.meals
            .filter { calendar.isDateInToday($0.timestamp) }
            .reduce(0.0) { $0 + $1.totalNutrition.calories }
        let stepsToday = context.healthDays.first { calendar.isDateInToday($0.date) }?.steps ?? 0

        var bullets = ["Entrenos esta semana: \(weekLogs)"]
        bullets.append(
            kcalToday > 0
                ? "Has comido \(Int(kcalToday)) kcal hoy"
                : "Aún no has registrado comidas hoy"
        )
        if stepsToday > 0 { bullets.append("Pasos: \(stepsToday)") }

        return CoachInsight(
            topic: .daily,
            title: "Resumen del día",
            body: "Visión rápida de tu día.",
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
                return "subes \(format(lastTopWeight - firstTopWeight)) kg → mantén"
            } else if lastTopWeight < firstTopWeight {
                return "estancado en \(format(lastTopWeight)) kg → repite"
            } else {
                return "estable en \(format(lastTopWeight)) kg → +2.5 kg"
            }
        }

        private func format(_ value: Double) -> String {
            value.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(value))
                : String(format: "%.1f", value)
        }
    }

    private func exerciseStats(from logs: [AIWorkoutLogSnapshot]) -> [ExerciseStat] {
        var byName: [String: [(date: Date, top: Double)]] = [:]
        for log in logs {
            for exercise in log.exercises {
                let topWeight = exercise.sets.compactMap { $0.weightKg }.max() ?? 0
                guard topWeight > 0 else { continue }
                byName[exercise.name, default: []].append((log.startedAt, topWeight))
            }
        }
        return byName.compactMap { name, points in
            let sorted = points.sorted { $0.date < $1.date }
            guard let first = sorted.first, let last = sorted.last else { return nil }
            return ExerciseStat(name: name, firstTopWeight: first.top, lastTopWeight: last.top)
        }
        .sorted { $0.name < $1.name }
    }
}

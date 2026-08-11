import Foundation

/// Traduce el `AIContext` que arma la app al payload que espera el backend.
///
/// Aquí vive todo el recorte: el contexto local es completo (meses de logs, todas
/// las comidas), pero el prompt no puede serlo — cada límite de longitud tiene su
/// equivalente en los validadores de Pydantic, y pasarse devuelve 422. Se recorta
/// siempre por lo **más reciente**, que es lo que aporta señal.
///
/// El otro trabajo del mapper es saneado: el backend valida rangos
/// (`age` 10-120, `weight_kg` > 0…), así que un perfil a medio rellenar debe
/// enviarse con el campo ausente en vez de con un 0.
extension AICoachRequestApiDTO {

    /// Idioma en el que habla la app, y por tanto en el que debe hablar el coach.
    ///
    /// Constante mientras la interfaz sea solo española: derivarlo del dispositivo
    /// desacopla al coach de la app, que es un bug, no una funcionalidad.
    static let appLanguage = "es"

    // Límites del backend (`domain/entities/ai.py`).
    private enum Limits {
        static let history = 40
        static let plan = 30
        static let nutritionHistory = 60
        static let messages = 30
        static let topSets = 20
        static let mealItems = 20
        static let planExercises = 40
        static let question = 500
        static let turnContent = 4_000
    }

    init(
        context: AIContext,
        topic: AICoachTopic,
        question: String?,
        conversation: [AIChatTurn] = [],
        now: Date = Date()
    ) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        let logs = context.workoutLogs.sorted { $0.startedAt < $1.startedAt }
        let todayLogs = logs.filter { calendar.isDate($0.startedAt, inSameDayAs: today) }
        let pastLogs = logs.filter { !calendar.isDate($0.startedAt, inSameDayAs: today) }

        self.init(
            date: Self.day(today),
            now: Self.iso(now),
            topic: topic.rawValue,
            profile: Self.profile(from: context),
            today: Self.todaySnapshot(context: context, todayLogs: todayLogs, today: today),
            history: Self.history(from: pastLogs),
            plan: Self.plan(context: context, logs: logs),
            nutritionHistory: Self.nutritionHistory(context: context, today: today),
            messages: Self.messages(from: conversation),
            userQuestion: Self.trimmed(question, max: Limits.question)
        )
    }

    // MARK: - Perfil

    private static func profile(from context: AIContext) -> Profile {
        // `language` es lo único obligatorio; el backend solo mira si empieza por "en".
        //
        // Se manda el idioma de LA APP, no el del dispositivo. Toda la interfaz está
        // en español (no hay .lproj ni Localizable.strings), así que con el móvil en
        // inglés el coach contestaba en inglés dentro de una app en español — y de
        // paso ignoraba los prompts que el admin tiene guardados para "es".
        //
        // Cuando la app se localice, esto debe pasar a ser la localización efectiva
        // del bundle (`Bundle.main.preferredLocalizations.first`), no `Locale.current`.
        let language = appLanguage
        guard let snapshot = context.profile else {
            return Profile(
                name: nil, gender: nil, age: nil, heightCm: nil, weightKg: nil,
                activityLevel: nil, goal: nil, calorieTarget: nil,
                proteinTargetG: nil, carbsTargetG: nil, fatTargetG: nil,
                language: language, freeDays: nil, freeDayExtraCalories: nil
            )
        }

        return Profile(
            name: trimmed(snapshot.name, max: 80),
            gender: gender(from: snapshot.gender),
            age: (10...120).contains(snapshot.age) ? snapshot.age : nil,
            heightCm: inRange(snapshot.heightCm, upTo: 300),
            weightKg: inRange(snapshot.weightKg, upTo: 400),
            activityLevel: trimmed(snapshot.activityLevel, max: 40),
            goal: trimmed(snapshot.fitnessGoal, max: 40),
            calorieTarget: calorieTarget(snapshot.todayCalorieTarget),
            // Los de HOY, para que cuadren con las kcal de al lado: en un día libre
            // los de la media semanal describirían otro día.
            proteinTargetG: grams(snapshot.todayMacroTargets.proteinsG),
            carbsTargetG: grams(snapshot.todayMacroTargets.carbohydratesG),
            fatTargetG: grams(snapshot.todayMacroTargets.fatsG),
            language: language,
            // El ciclado semanal no salía del móvil: el coach veía el objetivo de hoy
            // pero no que el sábado es día libre, así que no podía nombrar el patrón
            // ni entender por qué un día sube. Solo se mandan índices válidos.
            freeDays: snapshot.hasWeeklyCycling
                ? (snapshot.freeDaysWeekdays ?? []).filter { (1...7).contains($0) }.sorted().nilIfEmpty
                : nil,
            freeDayExtraCalories: snapshot.hasWeeklyCycling
                ? snapshot.freeDayExtraCalories.flatMap { $0 > 0 ? Int($0) : nil }
                : nil
        )
    }

    /// Gramos redondeados; ausente si no hay objetivo. Al backend no le sirve un 0.
    private static func grams(_ value: Double) -> Int? {
        value > 0 ? Int(value.rounded()) : nil
    }

    /// El `rawValue` local está en español ("Hombre"/"Mujer"); el backend solo
    /// acepta `male`/`female`/`other`.
    private static func gender(from raw: String) -> String? {
        switch raw.lowercased() {
        case "hombre", "male", "m": return "male"
        case "mujer", "female", "f": return "female"
        case "": return nil
        default: return "other"
        }
    }

    // MARK: - Día actual

    private static func todaySnapshot(
        context: AIContext,
        todayLogs: [AIWorkoutLogSnapshot],
        today: Date
    ) -> TodaySnapshot {
        let calendar = Calendar.current

        // Los workouts del Watch enriquecen el log al que están vinculados (kcal, FC)
        // y, los que no están vinculados a nada, entran por su cuenta: suelen ser
        // cardio, que es contexto real del día.
        let watchToday = context.healthWorkouts.filter {
            calendar.isDate($0.startDate, inSameDayAs: today)
        }
        let watchById = Dictionary(watchToday.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let linkedWatchIds = Set(todayLogs.compactMap { $0.linkedHealthWorkoutId })

        var workouts: [Workout] = todayLogs.map { log in
            let watch = log.linkedHealthWorkoutId.flatMap { watchById[$0] }
            return Workout(
                name: clamp(log.sessionName.isEmpty ? "Entrenamiento" : log.sessionName, max: 120),
                startedAt: iso(log.startedAt),
                durationMinutes: log.durationSeconds.map { Double($0) / 60 },
                kcalBurned: watch?.totalCalories,
                avgHeartRate: watch?.averageHeartRate,
                exercises: log.exercises.map { exercise in
                    Exercise(
                        name: clamp(exercise.name.isEmpty ? "Ejercicio" : exercise.name, max: 120),
                        sets: exercise.sets.map {
                            ExerciseSet(
                                weightKg: nonNegative($0.weightKg),
                                reps: $0.reps.map { max(0, $0) },
                                rir: $0.rir.map { Double(max(0, $0)) },
                                tags: []
                            )
                        },
                        notes: trimmed(exercise.notes, max: 2_000)
                    )
                }
            )
        }

        workouts += watchToday
            .filter { !linkedWatchIds.contains($0.id) }
            .map { watch in
                Workout(
                    name: clamp(watch.activityType, max: 120),
                    startedAt: iso(watch.startDate),
                    durationMinutes: watch.durationSeconds / 60,
                    kcalBurned: watch.totalCalories,
                    avgHeartRate: watch.averageHeartRate,
                    exercises: []
                )
            }

        // Las entradas manuales de hoy no son una sesión con plantilla, pero son
        // series que el usuario ha hecho: van agrupadas como un "workout" más.
        let manualToday = context.manualEntries.filter {
            calendar.isDate($0.date, inSameDayAs: today) && $0.completed
        }
        if !manualToday.isEmpty {
            workouts.append(
                Workout(
                    name: "Registro suelto",
                    startedAt: iso(manualToday.map(\.date).min() ?? today),
                    durationMinutes: nil,
                    kcalBurned: manualToday.compactMap(\.calories).reduce(0, +).nilIfZero,
                    avgHeartRate: nil,
                    exercises: manualToday.map { entry in
                        Exercise(
                            name: clamp(entry.exerciseName, max: 120),
                            sets: [
                                ExerciseSet(
                                    weightKg: nonNegative(entry.weightKg),
                                    reps: entry.reps.map { max(0, $0) },
                                    rir: nil,
                                    tags: []
                                )
                            ],
                            notes: nil
                        )
                    }
                )
            )
        }

        let meals = context.meals
            .filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
            .sorted { $0.timestamp < $1.timestamp }
            .map { meal in
                Meal(
                    type: trimmed(meal.type, max: 40),
                    at: iso(meal.timestamp),
                    macros: Macros(
                        calories: nonNegative(meal.totalNutrition.calories),
                        proteinG: nonNegative(meal.totalNutrition.proteinsG),
                        carbsG: nonNegative(meal.totalNutrition.carbohydratesG),
                        fatG: nonNegative(meal.totalNutrition.fatsG)
                    ),
                    items: Array(meal.items.map { clamp($0.name, max: 120) }.prefix(Limits.mealItems))
                )
            }

        // Los entrenos se ordenan por hora antes de salir. Llegaban agrupados por
        // procedencia (logs, luego el reloj, luego "Registro suelto"), y ahora que la
        // hora de las comidas también viaja, el modelo tiene que poder leer el día
        // como una secuencia sin recomponerla él.
        workouts.sort { ($0.startedAt ?? "") < ($1.startedAt ?? "") }

        let steps = context.healthDays
            .first { calendar.isDate($0.date, inSameDayAs: today) }?
            .steps
        let health = steps.map {
            Health(steps: max(0, $0), activeKcal: nil, restingHeartRate: nil, sleepHours: nil)
        }

        return TodaySnapshot(workouts: workouts, meals: meals, health: health)
    }

    // MARK: - Histórico de entrenos

    private static func history(from pastLogs: [AIWorkoutLogSnapshot]) -> [HistoryEntry] {
        // Se recorta por las más recientes, pero se envía de más antigua a más
        // reciente: así el modelo lee la progresión en el orden natural.
        pastLogs.suffix(Limits.history).map { log in
            HistoryEntry(
                date: day(log.startedAt),
                sessionName: trimmed(log.sessionName, max: 120),
                topSets: Array(log.exercises.compactMap(topSetLine).prefix(Limits.topSets)),
                totalVolumeKg: volume(of: log).nilIfZero
            )
        }
    }

    /// "Sentadilla: 120kg×3 RIR1" — la mejor serie del ejercicio en esa sesión.
    private static func topSetLine(for exercise: AILoggedExerciseSnapshot) -> String? {
        let best = exercise.sets
            .filter { ($0.weightKg ?? 0) > 0 || ($0.reps ?? 0) > 0 }
            .max { lhs, rhs in
                let lhsScore = (lhs.weightKg ?? 0) * Double(lhs.reps ?? 1)
                let rhsScore = (rhs.weightKg ?? 0) * Double(rhs.reps ?? 1)
                return lhsScore < rhsScore
            }
        guard let best else { return nil }

        var line = exercise.name
        if let weight = best.weightKg, weight > 0 {
            line += ": \(number(weight))kg"
            if let reps = best.reps { line += "×\(reps)" }
        } else if let reps = best.reps {
            line += ": \(reps) reps"
        } else {
            return nil
        }
        if let rir = best.rir { line += " RIR\(number(Double(rir)))" }
        return clamp(line, max: 200)
    }

    private static func volume(of log: AIWorkoutLogSnapshot) -> Double {
        log.exercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { $0 + ($1.weightKg ?? 0) * Double($1.reps ?? 0) }
        }
    }

    // MARK: - Plan

    private static func plan(context: AIContext, logs: [AIWorkoutLogSnapshot]) -> [PlanSession] {
        // Adherencia: se cruzan las plantillas con los logs por id y, si el log no
        // guardó el id (sesiones antiguas), por nombre.
        var lastById: [String: Date] = [:]
        var countById: [String: Int] = [:]
        var lastByName: [String: Date] = [:]
        var countByName: [String: Int] = [:]

        for log in logs {
            if let sessionId = log.sessionId {
                lastById[sessionId] = max(lastById[sessionId] ?? .distantPast, log.startedAt)
                countById[sessionId, default: 0] += 1
            }
            let name = log.sessionName.lowercased()
            lastByName[name] = max(lastByName[name] ?? .distantPast, log.startedAt)
            countByName[name] = (countByName[name] ?? 0) + 1
        }

        return context.workoutSessions
            .sorted { $0.updatedAt > $1.updatedAt }
            .prefix(Limits.plan)
            .map { session in
                let key = session.name.lowercased()
                let last = lastById[session.id] ?? lastByName[key]
                let times = countById[session.id] ?? countByName[key] ?? 0
                return PlanSession(
                    name: clamp(session.name, max: 120),
                    exercises: Array(session.exercises.map { clamp($0, max: 120) }.prefix(Limits.planExercises)),
                    lastPerformed: last.map(day),
                    timesPerformed: times
                )
            }
    }

    // MARK: - Histórico de nutrición

    private static func nutritionHistory(context: AIContext, today: Date) -> [NutritionDay] {
        let calendar = Calendar.current
        var byDay: [Date: (kcal: Double, protein: Double, carbs: Double, fat: Double)] = [:]

        for meal in context.meals {
            let day = calendar.startOfDay(for: meal.timestamp)
            guard day < today else { continue }   // hoy ya viaja en `today`
            var acc = byDay[day] ?? (0, 0, 0, 0)
            acc.kcal += meal.totalNutrition.calories
            acc.protein += meal.totalNutrition.proteinsG
            acc.carbs += meal.totalNutrition.carbohydratesG
            acc.fat += meal.totalNutrition.fatsG
            byDay[day] = acc
        }

        return byDay
            .sorted { $0.key < $1.key }
            .suffix(Limits.nutritionHistory)
            .map { entry in
                NutritionDay(
                    date: day(entry.key),
                    calories: entry.value.kcal.nilIfZero,
                    proteinG: entry.value.protein.nilIfZero,
                    carbsG: entry.value.carbs.nilIfZero,
                    fatG: entry.value.fat.nilIfZero,
                    targetCalories: calorieTarget(of: entry.key, profile: context.profile)
                )
            }
    }

    /// Objetivo del día que toca, no el objetivo medio.
    ///
    /// Antes se mandaba `dailyCalorieTarget` —la MEDIA semanal— para todos los días,
    /// así que un sábado libre a +500 kcal llegaba comparado contra el objetivo
    /// estricto y el modelo lo leía como pasarse. Con el tema de nutrición mandando
    /// 14 días, eran dos sábados mal interpretados en cada consejo.
    ///
    /// La misma regla que `UserProfile.calorieTarget(on:)`, aquí sobre el snapshot.
    private static func calorieTarget(of day: Date, profile: AIProfileSnapshot?) -> Double? {
        guard let profile else { return nil }
        guard profile.hasWeeklyCycling else { return profile.dailyCalorieTarget.nilIfZero }

        let weekday = Calendar.current.component(.weekday, from: day)
        let isFreeDay = (profile.freeDaysWeekdays ?? []).contains(weekday)
        return (isFreeDay ? profile.freeDayCalorieTarget : profile.strictDayCalorieTarget).nilIfZero
    }

    // MARK: - Conversación

    private static func messages(from conversation: [AIChatTurn]) -> [ChatTurn] {
        conversation
            .suffix(Limits.messages)
            .compactMap { turn in
                let content = clamp(turn.content, max: Limits.turnContent)
                guard !content.isEmpty else { return nil }
                return ChatTurn(role: turn.role.rawValue, content: content)
            }
    }

    // MARK: - Helpers

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// Horas en la zona del usuario, CON su offset (`19:10:00+02:00`).
    ///
    /// `ISO8601DateFormatter` usa GMT por defecto, así que antes las horas de los
    /// entrenos viajaban en UTC: en verano, un entreno de las 19:10 llegaba como
    /// "17:10Z". El modelo no sabe en qué zona vive el usuario, así que razonaba con
    /// dos horas de desfase — y con la hora actual en el prompt eso sería decirle
    /// que son las cinco de la tarde cuando son las siete.
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = .current
        return formatter
    }()

    private static func day(_ date: Date) -> String { dayFormatter.string(from: date) }
    private static func iso(_ date: Date) -> String { isoFormatter.string(from: date) }

    private static func clamp(_ value: String, max limit: Int) -> String {
        String(value.trimmingCharacters(in: .whitespacesAndNewlines).prefix(limit))
    }

    private static func trimmed(_ value: String?, max limit: Int) -> String? {
        guard let value else { return nil }
        let clamped = clamp(value, max: limit)
        return clamped.isEmpty ? nil : clamped
    }

    private static func inRange(_ value: Double, upTo limit: Double) -> Double? {
        (value > 0 && value <= limit) ? value : nil
    }

    private static func nonNegative(_ value: Double?) -> Double? {
        guard let value, value >= 0 else { return nil }
        return value
    }

    private static func calorieTarget(_ value: Double) -> Int? {
        let rounded = Int(value.rounded())
        return (rounded > 0 && rounded <= 10_000) ? rounded : nil
    }

    private static func number(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
    }
}

private extension Double {
    /// El backend valida `ge=0`, así que un 0 real y un "no hay dato" se
    /// distinguen omitiendo el campo en vez de mandando 0.
    var nilIfZero: Double? { self > 0 ? self : nil }
}

private extension Array {
    /// Una lista vacía se manda como campo AUSENTE, igual que el resto de valores
    /// sin dato: `[]` en cada petición es ruido en el prompt.
    var nilIfEmpty: [Element]? { isEmpty ? nil : self }
}

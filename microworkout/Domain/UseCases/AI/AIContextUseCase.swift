import Foundation

class AIContextUseCase: AIContextUseCaseProtocol {
    private let userProfileUseCase: UserProfileUseCaseProtocol
    private let workoutLogUseCase: WorkoutLogUseCaseProtocol
    private let workoutEntryUseCase: WorkoutEntryUseCaseProtocol
    private let mealUseCase: MealUseCaseProtocol
    private let healthUseCase: HealthUseCaseProtocol
    private let weeklyPlanUseCase: WeeklyPlanUseCaseProtocol

    init(userProfileUseCase: UserProfileUseCaseProtocol,
         workoutLogUseCase: WorkoutLogUseCaseProtocol,
         workoutEntryUseCase: WorkoutEntryUseCaseProtocol,
         mealUseCase: MealUseCaseProtocol,
         healthUseCase: HealthUseCaseProtocol,
         weeklyPlanUseCase: WeeklyPlanUseCaseProtocol) {
        self.userProfileUseCase = userProfileUseCase
        self.workoutLogUseCase = workoutLogUseCase
        self.workoutEntryUseCase = workoutEntryUseCase
        self.mealUseCase = mealUseCase
        self.healthUseCase = healthUseCase
        self.weeklyPlanUseCase = weeklyPlanUseCase
    }

    func buildContext(mealDaysBack: Int = 30, healthWeeksBack: Int = 4) async -> AIContext {
        async let profileSnapshot = await buildProfileSnapshot()
        async let workoutSessions = await buildWorkoutSessions()
        async let workoutLogs = await buildWorkoutLogs()
        async let manualEntries = await buildManualEntries()
        async let meals = await buildMeals(daysBack: mealDaysBack)
        async let healthDays = await buildHealthDays(weeksBack: healthWeeksBack)
        async let healthWorkouts = await buildHealthWorkouts()
        async let weeklyPlan = await buildWeeklyPlan()

        return await AIContext(
            generatedAt: Date(),
            locale: Locale.current.identifier,
            profile: profileSnapshot,
            workoutSessions: workoutSessions,
            workoutLogs: workoutLogs,
            manualEntries: manualEntries,
            meals: meals,
            healthDays: healthDays,
            healthWorkouts: healthWorkouts,
            weeklyPlan: weeklyPlan
        )
    }

    func toJSON(_ context: AIContext, pretty: Bool = true) -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if pretty { encoder.outputFormatting = [.prettyPrinted, .sortedKeys] }
        guard let data = try? encoder.encode(context),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }

    // MARK: - Builders

    private func buildWeeklyPlan() async -> [AIPlannedDaySnapshot] {
        guard let week = try? await weeklyPlanUseCase.getResolvedWeek() else { return [] }
        return week.map { day in
            AIPlannedDaySnapshot(
                weekday: day.weekday,
                // Una sesión borrada no es un descanso: el usuario quería entrenar
                // ese día. Se dice tal cual para que el coach pueda avisar.
                sessionName: day.isMissingSession ? "(sesión eliminada)" : day.session?.name,
                note: day.note
            )
        }
    }

    private func buildProfileSnapshot() async -> AIProfileSnapshot? {
        guard let profile = try? await userProfileUseCase.getProfile() else { return nil }
        return AIProfileSnapshot(
            name: profile.name,
            age: profile.age,
            gender: profile.gender.rawValue,
            heightCm: profile.height,
            weightKg: profile.weight,
            activityLevel: profile.activityLevel.rawValue,
            fitnessGoal: profile.fitnessGoal?.rawValue,
            dailyCalorieTarget: profile.dailyCalorieTarget,
            todayCalorieTarget: profile.todayCalorieTarget,
            macroTargets: profile.macroTargets.toSnapshot(),
            todayMacroTargets: profile.todayMacroTargets.toSnapshot(),
            hasWeeklyCycling: profile.hasCycling,
            freeDaysWeekdays: profile.freeDays,
            // El extra RESUELTO, no el campo crudo: con días libres y sin extra
            // guardado el dominio usa 500, y mandar `nil` diría que no hay extra.
            freeDayExtraCalories: profile.hasCycling ? profile.resolvedFreeDayExtra : nil,
            strictDayCalorieTarget: profile.strictDayCalorieTarget,
            freeDayCalorieTarget: profile.freeDayCalorieTarget
        )
    }

    private func buildWorkoutSessions() async -> [AIWorkoutSessionSnapshot] {
        let sessions = (try? await workoutLogUseCase.getAllSessions()) ?? []
        return sessions.map {
            AIWorkoutSessionSnapshot(
                id: $0.id.uuidString,
                name: $0.name,
                exercises: $0.exercises.map { $0.name },
                createdAt: $0.createdAt,
                updatedAt: $0.updatedAt
            )
        }
    }

    private func buildWorkoutLogs() async -> [AIWorkoutLogSnapshot] {
        let logs = (try? await workoutLogUseCase.getAllLogs()) ?? []
        return logs.map { log in
            AIWorkoutLogSnapshot(
                id: log.id.uuidString,
                sessionId: log.sessionId?.uuidString,
                sessionName: log.sessionName,
                startedAt: log.startedAt,
                endedAt: log.endedAt,
                durationSeconds: log.endedAt != nil ? log.durationSeconds : nil,
                linkedHealthWorkoutId: log.linkedHealthWorkoutId?.uuidString,
                exercises: log.exercises.map { ex in
                    AILoggedExerciseSnapshot(
                        name: ex.exercise.name,
                        notes: ex.notes,
                        sets: ex.sets.map { set in
                            AILoggedSetSnapshot(
                                weightKg: set.weight,
                                reps: set.reps,
                                rir: set.rir
                            )
                        }
                    )
                }
            )
        }
    }

    private func buildManualEntries() async -> [AIWorkoutEntrySnapshot] {
        let entries = (try? await workoutEntryUseCase.getAll()) ?? []
        return entries.map {
            AIWorkoutEntrySnapshot(
                id: $0.id.uuidString,
                exerciseName: $0.exercise.name,
                date: $0.date,
                reps: $0.reps,
                weightKg: $0.weight,
                distanceMeters: $0.distanceMeters,
                calories: $0.calories,
                completed: $0.isCompleted
            )
        }
    }

    private func buildMeals(daysBack: Int) async -> [AIMealSnapshot] {
        // Una consulta por rango, no una por día: con 14 o 30 días eran 14 o 30
        // idas y venidas secuenciales al servidor, y bastaba que fallara la de HOY
        // para que `try?` se comiera el día entero y el coach dijera que no habías
        // registrado nada.
        let cal = Calendar.current
        let now = Date()
        let start = cal.startOfDay(
            for: cal.date(byAdding: .day, value: -(max(1, daysBack) - 1), to: now) ?? now
        )
        // Hasta el FIN de hoy, no hasta este instante.
        //
        // Con `to: now` se caían las comidas con hora posterior a la actual —posible
        // desde que la hora es editable— mientras la cabecera de Comidas, que mira el
        // día entero, sí las contaba. El coach decía "has comido 1.289 kcal" con la
        // pantalla mostrando 1.551 justo encima, y el usuario no tiene forma de saber
        // cuál de las dos miente.
        //
        // El modelo ya recibe la hora actual (`now` en el payload), así que puede
        // distinguir por sí mismo lo ya comido de lo que aún no toca. Esconderle
        // datos que la app sí muestra no le ayuda: le hace contradecirla.
        let endOfDay = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now))?
            .addingTimeInterval(-1) ?? now
        let all = (try? await mealUseCase.getMeals(from: start, to: endOfDay)) ?? []
        return all.map {
            AIMealSnapshot(
                id: $0.id.uuidString,
                type: $0.type.rawValue,
                timestamp: $0.timestamp,
                myMealName: $0.myMealName,
                totalNutrition: $0.totalNutrition.toSnapshot(),
                items: $0.items.map { item in
                    AIFoodItemSnapshot(
                        name: item.name,
                        quantityG: item.quantity,
                        nutrition: item.actualNutrition.toSnapshot()
                    )
                }
            )
        }
    }

    private func buildHealthDays(weeksBack: Int) async -> [AIHealthDaySnapshot] {
        let weeks = (try? await healthUseCase.getDaysPerWeeksWithHealthInfo(for: max(1, weeksBack))) ?? []
        return weeks.flatMap { $0 }.map {
            AIHealthDaySnapshot(
                date: $0.date,
                steps: $0.steps,
                minutesOfExercise: $0.minutesOfExercise,
                minutesStanding: $0.minutesStanding
            )
        }
    }

    private func buildHealthWorkouts() async -> [AIHealthWorkoutSnapshot] {
        let workouts = (try? await healthUseCase.getRecentWorkouts()) ?? []
        return workouts.map {
            AIHealthWorkoutSnapshot(
                id: $0.id,
                activityType: $0.activityTypeName,
                startDate: $0.startDate,
                endDate: $0.endDate,
                durationSeconds: $0.durationInSeconds,
                totalCalories: $0.totalCalories,
                totalDistanceMeters: $0.totalDistance,
                averageHeartRate: $0.averageHeartRate,
                linkedTrainingId: $0.linkedTrainingID?.uuidString,
                linkedEntryDate: $0.linkedEntryDate
            )
        }
    }
}

fileprivate extension NutritionInfo {
    func toSnapshot() -> AINutritionSnapshot {
        AINutritionSnapshot(
            calories: calories,
            carbohydratesG: carbohydrates,
            proteinsG: proteins,
            fatsG: fats,
            fiberG: fiber
        )
    }
}

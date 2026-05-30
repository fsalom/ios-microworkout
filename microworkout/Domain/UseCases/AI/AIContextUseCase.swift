import Foundation

class AIContextUseCase: AIContextUseCaseProtocol {
    private let userProfileUseCase: UserProfileUseCaseProtocol
    private let workoutLogUseCase: WorkoutLogUseCaseProtocol
    private let workoutEntryUseCase: WorkoutEntryUseCaseProtocol
    private let mealUseCase: MealUseCaseProtocol
    private let healthUseCase: HealthUseCaseProtocol

    init(userProfileUseCase: UserProfileUseCaseProtocol,
         workoutLogUseCase: WorkoutLogUseCaseProtocol,
         workoutEntryUseCase: WorkoutEntryUseCaseProtocol,
         mealUseCase: MealUseCaseProtocol,
         healthUseCase: HealthUseCaseProtocol) {
        self.userProfileUseCase = userProfileUseCase
        self.workoutLogUseCase = workoutLogUseCase
        self.workoutEntryUseCase = workoutEntryUseCase
        self.mealUseCase = mealUseCase
        self.healthUseCase = healthUseCase
    }

    func buildContext(mealDaysBack: Int = 30, healthWeeksBack: Int = 4) async -> AIContext {
        async let profileSnapshot = await buildProfileSnapshot()
        async let workoutSessions = await buildWorkoutSessions()
        async let workoutLogs = await buildWorkoutLogs()
        async let manualEntries = await buildManualEntries()
        async let meals = await buildMeals(daysBack: mealDaysBack)
        async let healthDays = await buildHealthDays(weeksBack: healthWeeksBack)
        async let healthWorkouts = await buildHealthWorkouts()

        return await AIContext(
            generatedAt: Date(),
            locale: Locale.current.identifier,
            profile: profileSnapshot,
            workoutSessions: workoutSessions,
            workoutLogs: workoutLogs,
            manualEntries: manualEntries,
            meals: meals,
            healthDays: healthDays,
            healthWorkouts: healthWorkouts
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
            hasWeeklyCycling: profile.hasCycling,
            freeDaysWeekdays: profile.freeDays,
            freeDayExtraCalories: profile.freeDayExtraCalories
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
        let cal = Calendar.current
        var all: [Meal] = []
        for offset in 0..<max(1, daysBack) {
            guard let date = cal.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            if let meals = try? await mealUseCase.getMeals(for: date) {
                all.append(contentsOf: meals)
            }
        }
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

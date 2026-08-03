import XCTest
@testable import microworkout

/// El backend valida el payload con Pydantic y `extra="forbid"`, así que un nombre
/// de clave mal puesto o un valor fuera de rango no es un bug silencioso: es un 422
/// y la pestaña se queda sin consejo. Estos tests fijan el contrato.
///
/// El JSON que produce `testPayloadShapeIsStable` se valida contra
/// `CoachRequest` del backend (ver `scripts` del repo de Python) cuando se cambia
/// el DTO por cualquiera de los dos lados.
final class AICoachRequestMapperTests: XCTestCase {

    // MARK: - Fixture

    private func makeContext(
        profile: AIProfileSnapshot? = nil,
        logs: [AIWorkoutLogSnapshot] = [],
        sessions: [AIWorkoutSessionSnapshot] = [],
        meals: [AIMealSnapshot] = [],
        healthDays: [AIHealthDaySnapshot] = [],
        healthWorkouts: [AIHealthWorkoutSnapshot] = [],
        manualEntries: [AIWorkoutEntrySnapshot] = []
    ) -> AIContext {
        AIContext(
            generatedAt: Date(),
            locale: "es_ES",
            profile: profile,
            workoutSessions: sessions,
            workoutLogs: logs,
            manualEntries: manualEntries,
            meals: meals,
            healthDays: healthDays,
            healthWorkouts: healthWorkouts
        )
    }

    private func nutrition(_ kcal: Double, protein: Double = 0) -> AINutritionSnapshot {
        AINutritionSnapshot(
            calories: kcal,
            carbohydratesG: 10,
            proteinsG: protein,
            fatsG: 5,
            fiberG: nil
        )
    }

    private func fullProfile() -> AIProfileSnapshot {
        AIProfileSnapshot(
            name: "Fer",
            age: 38,
            gender: "Hombre",
            heightCm: 178,
            weightKg: 78.4,
            activityLevel: "Moderadamente activo",
            fitnessGoal: "Ganar musculo",
            dailyCalorieTarget: 2600,
            todayCalorieTarget: 2600,
            macroTargets: nutrition(2600, protein: 160),
            hasWeeklyCycling: false,
            freeDaysWeekdays: nil,
            freeDayExtraCalories: nil
        )
    }

    private func encode(_ request: AICoachRequestApiDTO) throws -> [String: Any] {
        let data = try JSONEncoder().encode(request)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    // MARK: - Saneado del perfil

    func testGenderIsTranslatedToBackendVocabulary() throws {
        let request = AICoachRequestApiDTO(
            context: makeContext(profile: fullProfile()),
            topic: .workout,
            question: nil
        )
        XCTAssertEqual(request.profile.gender, "male")

        var female = fullProfile()
        female = AIProfileSnapshot(
            name: female.name, age: female.age, gender: "Mujer",
            heightCm: female.heightCm, weightKg: female.weightKg,
            activityLevel: female.activityLevel, fitnessGoal: female.fitnessGoal,
            dailyCalorieTarget: female.dailyCalorieTarget,
            todayCalorieTarget: female.todayCalorieTarget,
            macroTargets: female.macroTargets, hasWeeklyCycling: false,
            freeDaysWeekdays: nil, freeDayExtraCalories: nil
        )
        let femaleRequest = AICoachRequestApiDTO(
            context: makeContext(profile: female), topic: .workout, question: nil
        )
        XCTAssertEqual(femaleRequest.profile.gender, "female")
    }

    /// Un perfil recién creado tiene 0 en edad y peso. El backend valida
    /// `age >= 10` y `weight_kg > 0`, así que esos campos deben viajar ausentes.
    func testEmptyProfileOmitsOutOfRangeFieldsInsteadOfSendingZeros() throws {
        let empty = AIProfileSnapshot(
            name: "", age: 0, gender: "", heightCm: 0, weightKg: 0,
            activityLevel: "", fitnessGoal: nil,
            dailyCalorieTarget: 0, todayCalorieTarget: 0,
            macroTargets: nutrition(0), hasWeeklyCycling: false,
            freeDaysWeekdays: nil, freeDayExtraCalories: nil
        )
        let request = AICoachRequestApiDTO(
            context: makeContext(profile: empty), topic: .daily, question: nil
        )

        XCTAssertNil(request.profile.age)
        XCTAssertNil(request.profile.weightKg)
        XCTAssertNil(request.profile.heightCm)
        XCTAssertNil(request.profile.name)
        XCTAssertNil(request.profile.calorieTarget)
        XCTAssertNil(request.profile.gender)

        let json = try encode(request)
        let profile = try XCTUnwrap(json["profile"] as? [String: Any])
        XCTAssertEqual(Set(profile.keys), ["language"], "solo `language` es obligatorio")
    }

    func testProfileIsPresentEvenWithoutLocalProfile() throws {
        let request = AICoachRequestApiDTO(
            context: makeContext(), topic: .daily, question: nil
        )
        XCTAssertEqual(request.profile.language, "es_ES")
    }

    // MARK: - Claves del contrato

    func testPayloadUsesSnakeCaseKeysExpectedByBackend() throws {
        let json = try encode(
            AICoachRequestApiDTO(
                context: makeContext(profile: fullProfile()),
                topic: .nutrition,
                question: "¿voy bien?",
                conversation: [AIChatTurn(role: .user, content: "hola")]
            )
        )

        XCTAssertEqual(
            Set(json.keys),
            [
                "date", "topic", "profile", "today", "history", "plan",
                "nutrition_history", "messages", "user_question"
            ]
        )
        XCTAssertEqual(json["topic"] as? String, "nutrition")
        XCTAssertEqual(json["user_question"] as? String, "¿voy bien?")

        let profile = try XCTUnwrap(json["profile"] as? [String: Any])
        XCTAssertNotNil(profile["height_cm"])
        XCTAssertNotNil(profile["weight_kg"])
        XCTAssertNotNil(profile["activity_level"])
        XCTAssertNotNil(profile["calorie_target"])

        let messages = try XCTUnwrap(json["messages"] as? [[String: Any]])
        XCTAssertEqual(messages.first?["role"] as? String, "user")
    }

    /// `date` debe ir en `yyyy-MM-dd`: Pydantic lo parsea como `date`.
    func testDateIsPlainCalendarDay() throws {
        let json = try encode(
            AICoachRequestApiDTO(context: makeContext(), topic: .daily, question: nil)
        )
        let date = try XCTUnwrap(json["date"] as? String)
        XCTAssertEqual(date.count, 10)
        XCTAssertNotNil(
            try? Regex("^\\d{4}-\\d{2}-\\d{2}$").firstMatch(in: date).flatMap { $0 }
        )
    }

    // MARK: - Hoy vs histórico

    func testTodaySessionGoesToTodayAndOlderOnesToHistory() throws {
        let today = Calendar.current.startOfDay(for: Date()).addingTimeInterval(9 * 3600)
        let lastWeek = today.addingTimeInterval(-7 * 86_400)

        let set = AILoggedSetSnapshot(weightKg: 80, reps: 6, rir: 1)
        let exercise = AILoggedExerciseSnapshot(name: "Press banca", notes: nil, sets: [set])
        let makeLog: (Date) -> AIWorkoutLogSnapshot = { date in
            AIWorkoutLogSnapshot(
                id: UUID().uuidString, sessionId: nil, sessionName: "Empuje",
                startedAt: date, endedAt: date.addingTimeInterval(3600),
                durationSeconds: 3600, linkedHealthWorkoutId: nil,
                exercises: [exercise]
            )
        }

        let request = AICoachRequestApiDTO(
            context: makeContext(logs: [makeLog(lastWeek), makeLog(today)]),
            topic: .workout,
            question: nil,
            now: today
        )

        XCTAssertEqual(request.today.workouts.count, 1)
        XCTAssertEqual(request.today.workouts.first?.name, "Empuje")
        XCTAssertEqual(request.history.count, 1)
        XCTAssertEqual(request.history.first?.topSets, ["Press banca: 80kg×6 RIR1"])
        XCTAssertEqual(request.history.first?.totalVolumeKg, 480)
    }

    func testPlanCarriesAdherenceFromLogs() throws {
        let sessionId = UUID().uuidString
        let now = Date()
        let log = AIWorkoutLogSnapshot(
            id: UUID().uuidString, sessionId: sessionId, sessionName: "Empuje",
            startedAt: now.addingTimeInterval(-3 * 86_400), endedAt: nil,
            durationSeconds: nil, linkedHealthWorkoutId: nil, exercises: []
        )
        let session = AIWorkoutSessionSnapshot(
            id: sessionId, name: "Empuje", exercises: ["Press banca", "Militar"],
            createdAt: now, updatedAt: now
        )

        let request = AICoachRequestApiDTO(
            context: makeContext(logs: [log], sessions: [session]),
            topic: .plan,
            question: nil,
            now: now
        )

        XCTAssertEqual(request.plan.count, 1)
        XCTAssertEqual(request.plan.first?.timesPerformed, 1)
        XCTAssertNotNil(request.plan.first?.lastPerformed)
        XCTAssertEqual(request.plan.first?.exercises, ["Press banca", "Militar"])
    }

    func testNutritionHistoryExcludesTodayAndAggregatesPerDay() throws {
        let today = Calendar.current.startOfDay(for: Date()).addingTimeInterval(12 * 3600)
        let yesterday = today.addingTimeInterval(-86_400)

        let meal: (Date, Double) -> AIMealSnapshot = { date, kcal in
            AIMealSnapshot(
                id: UUID().uuidString, type: "lunch", timestamp: date, myMealName: nil,
                totalNutrition: self.nutrition(kcal, protein: 30),
                items: [AIFoodItemSnapshot(name: "Pollo", quantityG: 200, nutrition: self.nutrition(kcal))]
            )
        }

        let request = AICoachRequestApiDTO(
            context: makeContext(
                profile: fullProfile(),
                meals: [meal(today, 600), meal(yesterday, 500), meal(yesterday, 700)]
            ),
            topic: .nutrition,
            question: nil,
            now: today
        )

        XCTAssertEqual(request.today.meals.count, 1)
        XCTAssertEqual(request.nutritionHistory.count, 1)
        XCTAssertEqual(request.nutritionHistory.first?.calories, 1_200)
        XCTAssertEqual(request.nutritionHistory.first?.targetCalories, 2_600)
    }

    // MARK: - Límites

    func testHistoryIsCappedAtBackendLimitKeepingTheMostRecent() throws {
        let now = Date()
        let logs = (1...60).map { index -> AIWorkoutLogSnapshot in
            AIWorkoutLogSnapshot(
                id: UUID().uuidString, sessionId: nil, sessionName: "S\(index)",
                startedAt: now.addingTimeInterval(-Double(index) * 86_400),
                endedAt: nil, durationSeconds: nil, linkedHealthWorkoutId: nil,
                exercises: []
            )
        }

        let request = AICoachRequestApiDTO(
            context: makeContext(logs: logs), topic: .workout, question: nil, now: now
        )

        XCTAssertEqual(request.history.count, 40, "el backend rechaza más de 40")
        // Se conservan las más recientes y se envían de más antigua a más nueva.
        XCTAssertEqual(request.history.last?.sessionName, "S1")
    }

    func testConversationIsCappedAtThirtyTurns() throws {
        let turns = (1...50).map { AIChatTurn(role: .user, content: "turno \($0)") }
        let request = AICoachRequestApiDTO(
            context: makeContext(), topic: .free, question: "y ahora?", conversation: turns
        )

        XCTAssertEqual(request.messages.count, 30)
        XCTAssertEqual(request.messages.last?.content, "turno 50")
    }

    func testQuestionIsTruncatedToBackendMaximum() throws {
        let long = String(repeating: "a", count: 900)
        let request = AICoachRequestApiDTO(
            context: makeContext(), topic: .free, question: long
        )
        XCTAssertEqual(request.userQuestion?.count, 500)
    }

    /// Deja en el log el JSON completo, que es el que se pega contra el validador
    /// del backend cuando se toca el contrato por cualquiera de los dos lados.
    func testPayloadShapeIsStable() throws {
        let now = Date()
        let request = AICoachRequestApiDTO(
            context: makeContext(
                profile: fullProfile(),
                logs: [
                    AIWorkoutLogSnapshot(
                        id: UUID().uuidString, sessionId: nil, sessionName: "Empuje",
                        startedAt: now, endedAt: nil, durationSeconds: 3_000,
                        linkedHealthWorkoutId: nil,
                        exercises: [
                            AILoggedExerciseSnapshot(
                                name: "Press banca", notes: "buena técnica",
                                sets: [AILoggedSetSnapshot(weightKg: 80, reps: 6, rir: 1)]
                            )
                        ]
                    )
                ],
                sessions: [
                    AIWorkoutSessionSnapshot(
                        id: UUID().uuidString, name: "Empuje",
                        exercises: ["Press banca"], createdAt: now, updatedAt: now
                    )
                ],
                meals: [
                    AIMealSnapshot(
                        id: UUID().uuidString, type: "breakfast", timestamp: now,
                        myMealName: nil, totalNutrition: nutrition(450, protein: 30),
                        items: [AIFoodItemSnapshot(name: "Avena", quantityG: 80, nutrition: nutrition(300))]
                    )
                ],
                healthDays: [
                    AIHealthDaySnapshot(date: now, steps: 8_200, minutesOfExercise: 40, minutesStanding: 8)
                ]
            ),
            topic: .daily,
            question: "¿cómo voy hoy?",
            now: now
        )

        let data = try JSONEncoder().encode(request)
        let pretty = try JSONSerialization.data(
            withJSONObject: JSONSerialization.jsonObject(with: data),
            options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        )
        print("PAYLOAD_INICIO\n" + (String(data: pretty, encoding: .utf8) ?? "") + "\nPAYLOAD_FIN")

        let json = try encode(request)
        XCTAssertNotNil(json["nutrition_history"])
        let today = try XCTUnwrap(json["today"] as? [String: Any])
        let health = try XCTUnwrap(today["health"] as? [String: Any])
        XCTAssertEqual(health["steps"] as? Int, 8_200)
    }
}

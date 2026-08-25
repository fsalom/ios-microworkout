import XCTest
import TripleA
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
        manualEntries: [AIWorkoutEntrySnapshot] = [],
        weeklyPlan: [AIPlannedDaySnapshot] = []
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
            healthWorkouts: healthWorkouts,
            weeklyPlan: weeklyPlan
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
            todayMacroTargets: nutrition(2600, protein: 160),
            hasWeeklyCycling: false,
            freeDaysWeekdays: nil,
            freeDayExtraCalories: nil,
            strictDayCalorieTarget: 2600,
            freeDayCalorieTarget: 3100
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
            macroTargets: female.macroTargets,
            todayMacroTargets: female.todayMacroTargets, hasWeeklyCycling: false,
            freeDaysWeekdays: nil, freeDayExtraCalories: nil,
            strictDayCalorieTarget: female.strictDayCalorieTarget,
            freeDayCalorieTarget: female.freeDayCalorieTarget
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
            macroTargets: nutrition(0),
            // Todo a cero de verdad: el helper `nutrition` fija carbos y grasas, y con
            // ellos este perfil "vacío" mandaría objetivos de macros inventados.
            todayMacroTargets: AINutritionSnapshot(
                calories: 0, carbohydratesG: 0, proteinsG: 0, fatsG: 0, fiberG: nil
            ),
            hasWeeklyCycling: false,
            freeDaysWeekdays: nil, freeDayExtraCalories: nil,
            strictDayCalorieTarget: 0, freeDayCalorieTarget: 0
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
        XCTAssertEqual(request.profile.language, AICoachRequestApiDTO.appLanguage)
    }

    /// El idioma que se manda es el de LA APP, no el del dispositivo. Con el móvil
    /// en inglés el coach contestaba en inglés dentro de una app en español, y
    /// además el backend buscaba los prompts del admin con `language="en"`, así que
    /// los guardados como "es" no se aplicaban nunca.
    func testLanguageIsTheAppsNotTheDevices() throws {
        // El contexto trae un locale inglés, como un móvil configurado en inglés.
        let context = AIContext(
            generatedAt: Date(), locale: "en_US", profile: fullProfile(),
            workoutSessions: [], workoutLogs: [], manualEntries: [],
            meals: [], healthDays: [], healthWorkouts: []
        )
        let request = AICoachRequestApiDTO(context: context, topic: .daily, question: nil)

        XCTAssertEqual(request.profile.language, "es")
        XCTAssertFalse(
            request.profile.language.hasPrefix("en"),
            "el backend resolvería inglés y se saltaría los prompts guardados en español"
        )
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
                "date", "now", "topic", "profile", "today", "history", "plan",
                "weekly_plan", "nutrition_history", "messages", "user_question"
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

    // MARK: - Plan semanal

    /// El calendario viaja con las claves que espera el backend (`weekly_plan`,
    /// `session_name`) y el descanso viaja como ausencia de sesión, no como "".
    /// Este payload está acoplado a Pydantic con `extra="forbid"`: si esto cambia,
    /// el DTO del backend cambia con él.
    func testWeeklyPlanTravelsWithBackendKeys() throws {
        let request = AICoachRequestApiDTO(
            context: makeContext(weeklyPlan: [
                AIPlannedDaySnapshot(weekday: 2, sessionName: "Empuje"),
                AIPlannedDaySnapshot(weekday: 3, sessionName: nil, note: "paseo"),
                AIPlannedDaySnapshot(weekday: 9, sessionName: "Rota")  // fuera de rango
            ]),
            topic: .daily, question: nil, now: Date()
        )

        let json = try encode(request)
        let days = try XCTUnwrap(json["weekly_plan"] as? [[String: Any]])
        // El día 9 no puede llegar al backend: `ge=1, le=7` + `extra="forbid"`
        // convierten un día inválido en un 422 de toda la petición.
        XCTAssertEqual(days.count, 2)
        XCTAssertEqual(days[0]["weekday"] as? Int, 2)
        XCTAssertEqual(days[0]["session_name"] as? String, "Empuje")
        XCTAssertNil(days[1]["session_name"], "descanso = sin clave, no cadena vacía")
        XCTAssertEqual(days[1]["note"] as? String, "paseo")
    }

    func testWithoutWeeklyPlanTheKeyIsAnEmptyList() throws {
        let request = AICoachRequestApiDTO(
            context: makeContext(), topic: .daily, question: nil, now: Date()
        )
        let json = try encode(request)
        // Lista vacía, no ausencia: el campo existe en el modelo Pydantic con
        // default, y mandarlo vacío es lo que un cliente antiguo parece desde el
        // backend. Así los dos casos recorren el mismo camino.
        XCTAssertNotNil(json["weekly_plan"] as? [[String: Any]])
    }

    // MARK: - Detalle por alimento, fibra y distancia

    private func food(
        _ name: String, grams: Double, kcal: Double,
        protein: Double = 0, carbs: Double = 0, fat: Double = 0, fiber: Double? = nil
    ) -> AIFoodItemSnapshot {
        // `nutrition` es lo YA consumido de ese alimento (`actualNutrition` en el
        // dominio), no por 100 g.
        AIFoodItemSnapshot(
            name: name,
            quantityG: grams,
            nutrition: AINutritionSnapshot(
                calories: kcal, carbohydratesG: carbs, proteinsG: protein,
                fatsG: fat, fiberG: fiber
            )
        )
    }

    private func mealWith(
        _ items: [AIFoodItemSnapshot], at date: Date, fiber: Double? = nil
    ) -> AIMealSnapshot {
        let total = items.reduce(into: (kcal: 0.0, p: 0.0, c: 0.0, f: 0.0)) {
            $0.kcal += $1.nutrition.calories
            $0.p += $1.nutrition.proteinsG
            $0.c += $1.nutrition.carbohydratesG
            $0.f += $1.nutrition.fatsG
        }
        return AIMealSnapshot(
            id: UUID().uuidString, type: "Desayuno", timestamp: date, myMealName: nil,
            totalNutrition: AINutritionSnapshot(
                calories: total.kcal, carbohydratesG: total.c, proteinsG: total.p,
                fatsG: total.f, fiberG: fiber
            ),
            items: items
        )
    }

    /// Lo que faltaba para poder decir "las barritas son 138 kcal y el sándwich 108:
    /// entre los dos, 246". Antes de cada alimento solo viajaba el NOMBRE, así que el
    /// coach solo podía hablar del agregado del día.
    func testEachFoodTravelsWithItsGramsAndMacros() throws {
        let now = date("2026-08-12 12:00")
        let breakfast = mealWith([
            food("Yogur Proteínas Natural 0%", grams: 240, kcal: 124, protein: 24, carbs: 7, fat: 1),
            food("Barritas de trigo y arroz", grams: 40, kcal: 138, protein: 2, carbs: 21, fat: 3),
        ], at: date("2026-08-12 09:27"))

        let request = AICoachRequestApiDTO(
            context: makeContext(profile: fullProfile(), meals: [breakfast]),
            topic: .nutrition, question: nil, now: now
        )

        let items = try XCTUnwrap(request.today.meals.first?.items)
        XCTAssertEqual(items.map(\.name), [
            "Yogur Proteínas Natural 0%", "Barritas de trigo y arroz",
        ])
        let bar = try XCTUnwrap(items.last)
        XCTAssertEqual(bar.grams, 40)
        XCTAssertEqual(bar.calories, 138, "el coach puede nombrar la cifra del alimento")
        XCTAssertEqual(bar.carbsG, 21)

        // Y en snake_case, que es lo que valida Pydantic.
        let json = try encode(request)
        let today = try XCTUnwrap(json["today"] as? [String: Any])
        let meals = try XCTUnwrap(today["meals"] as? [[String: Any]])
        let sent = try XCTUnwrap((meals.first?["items"] as? [[String: Any]])?.last)
        XCTAssertEqual(sent["calories"] as? Double, 138)
        XCTAssertEqual(sent["carbs_g"] as? Double, 21)
        XCTAssertEqual(sent["grams"] as? Double, 40)
    }

    /// Los totales los suma el móvil. El modelo los sumaba él y se los inventaba:
    /// una tarjeta dijo "415 kcal" y "114 g de proteína" —imposible, 114 g son 456
    /// kcal— con 484 y 48 en la cabecera de la propia pantalla.
    func testTodayCarriesTotalsAlreadyAddedUp() throws {
        let now = date("2026-08-13 10:44")
        let breakfast = mealWith([
            food("Divertidas", grams: 16, kcal: 78, carbs: 4, fat: 1),
            food("Yogur Proteínas 0%", grams: 240, kcal: 124, protein: 24, carbs: 7, fat: 1),
            food("Shot jengibre", grams: 120, kcal: 51, carbs: 12),
        ], at: date("2026-08-13 08:59"))

        let request = AICoachRequestApiDTO(
            context: makeContext(profile: fullProfile(), meals: [breakfast]),
            topic: .nutrition, question: nil, now: now
        )

        let totals = try XCTUnwrap(request.today.totals)
        XCTAssertEqual(totals.calories, 253, "78 + 124 + 51")
        XCTAssertEqual(totals.proteinG, 24)
        XCTAssertEqual(totals.carbsG, 23, "4 + 7 + 12")

        // Y lo que queda, también restado aquí: 2600 de objetivo menos 253.
        let remaining = try XCTUnwrap(request.today.remaining)
        XCTAssertEqual(remaining.calories, 2_347)
        XCTAssertEqual(remaining.proteinG, 136, "160 de objetivo menos 24")
    }

    func testWithoutMealsThereAreNoTotalsToQuote() throws {
        let request = AICoachRequestApiDTO(
            context: makeContext(profile: fullProfile()), topic: .nutrition,
            question: nil, now: date("2026-08-13 10:44")
        )
        XCTAssertNil(request.today.totals, "un día sin comidas no tiene totales que citar")
        XCTAssertNil(request.today.remaining)
    }

    /// Pasarse del objetivo es información: el restante puede ser negativo.
    func testGoingOverTheTargetGivesANegativeRemainder() throws {
        let now = date("2026-08-13 22:00")
        let huge = mealWith(
            [food("Pizza", grams: 800, kcal: 3_000, protein: 100, carbs: 300, fat: 120)],
            at: date("2026-08-13 21:00")
        )
        let request = AICoachRequestApiDTO(
            context: makeContext(profile: fullProfile(), meals: [huge]),
            topic: .nutrition, question: nil, now: now
        )

        let remaining = try XCTUnwrap(request.today.remaining)
        XCTAssertEqual(remaining.calories, -400, "2.600 de objetivo menos 3.000")
    }

    func testFiberTravelsWithTheMealMacros() throws {
        let now = date("2026-08-12 12:00")
        let breakfast = mealWith(
            [food("Avena", grams: 60, kcal: 220, carbs: 40, fiber: 6)],
            at: date("2026-08-12 09:00"), fiber: 6
        )
        let request = AICoachRequestApiDTO(
            context: makeContext(profile: fullProfile(), meals: [breakfast]),
            topic: .nutrition, question: nil, now: now
        )

        XCTAssertEqual(request.today.meals.first?.macros.fiberG, 6)
    }

    /// Sin la distancia, una carrera llegaba como "Carrera, 40 min" y no se podía
    /// valorar si los carbohidratos del día sostienen esa tirada.
    func testARunCarriesItsDistanceInKilometres() throws {
        let now = date("2026-08-12 12:00")
        let context = AIContext(
            generatedAt: now, locale: "es_ES", profile: fullProfile(),
            workoutSessions: [], workoutLogs: [], manualEntries: [], meals: [],
            healthDays: [],
            healthWorkouts: [
                AIHealthWorkoutSnapshot(
                    id: UUID().uuidString, activityType: "Carrera",
                    startDate: date("2026-08-12 08:00"), endDate: date("2026-08-12 08:45"),
                    durationSeconds: 2_700, totalCalories: 620,
                    totalDistanceMeters: 7_920, averageHeartRate: 158,
                    linkedTrainingId: nil, linkedEntryDate: nil
                )
            ]
        )

        let request = AICoachRequestApiDTO(context: context, topic: .daily, question: nil, now: now)

        let run = try XCTUnwrap(request.today.workouts.first)
        XCTAssertEqual(run.name, "Carrera")
        XCTAssertEqual(run.distanceKm, 7.9, "7.920 m son 7,9 km")
    }

    /// Un entreno de fuerza no tiene distancia: mandar 0 sería ruido.
    func testAStrengthWorkoutSendsNoDistance() throws {
        let now = date("2026-08-12 20:00")
        let context = AIContext(
            generatedAt: now, locale: "es_ES", profile: fullProfile(),
            workoutSessions: [],
            workoutLogs: [
                AIWorkoutLogSnapshot(
                    id: UUID().uuidString, sessionId: nil, sessionName: "Empuje",
                    startedAt: date("2026-08-12 19:00"), endedAt: nil,
                    durationSeconds: 3_600, linkedHealthWorkoutId: nil, exercises: []
                )
            ],
            manualEntries: [], meals: [], healthDays: [], healthWorkouts: []
        )

        let request = AICoachRequestApiDTO(context: context, topic: .workout, question: nil, now: now)
        XCTAssertNil(request.today.workouts.first?.distanceKm)
    }

    // MARK: - El reloj: la hora actual y la de cada comida

    /// El coach solo recibía el DÍA, así que no podía razonar sobre "a estas alturas":
    /// ni qué queda por entrenar, ni si lo comido hasta ahora encaja, ni cuánto ha
    /// pasado desde el entreno. No era un problema del prompt: el dato no salía.
    func testTheCurrentTimeTravelsInThePayload() throws {
        let now = date("2026-08-10 19:10")
        let request = AICoachRequestApiDTO(
            context: makeContext(profile: fullProfile()), topic: .workout,
            question: nil, now: now
        )

        let sent = try XCTUnwrap(request.now)
        XCTAssertTrue(sent.hasPrefix("2026-08-10T19:10"), "la hora local, no el día a secas: \(sent)")
    }

    /// Con la hora en UTC (el defecto de `ISO8601DateFormatter`) un entreno de las
    /// 19:10 de verano llegaba como "17:10Z", y el modelo no sabe en qué zona vive el
    /// usuario: razonaría con dos horas de desfase.
    func testTimesCarryTheUsersOwnOffsetNotUTC() throws {
        let now = date("2026-08-10 19:10")
        let request = AICoachRequestApiDTO(
            context: makeContext(profile: fullProfile()), topic: .workout,
            question: nil, now: now
        )

        let sent = try XCTUnwrap(request.now)
        XCTAssertFalse(sent.hasSuffix("Z"), "no se manda en UTC: \(sent)")
        let expectedOffset = TimeZone.current.secondsFromGMT(for: now) / 3600
        XCTAssertTrue(
            sent.contains(String(format: "%+03d:", expectedOffset)),
            "debe llevar el offset del usuario: \(sent)"
        )
    }

    func testEachMealCarriesTheTimeItWasEaten() throws {
        let now = date("2026-08-10 22:00")
        let lunch = meal(on: date("2026-08-10 14:15"), kcal: 800)
        let dinner = meal(on: date("2026-08-10 21:30"), kcal: 600)
        let request = AICoachRequestApiDTO(
            context: makeContext(profile: fullProfile(), meals: [dinner, lunch]),
            topic: .nutrition, question: nil, now: now
        )

        let times = request.today.meals.compactMap(\.at)
        XCTAssertEqual(times.count, 2)
        XCTAssertTrue(times[0].contains("14:15"), "en orden, y con su hora: \(times)")
        XCTAssertTrue(times[1].contains("21:30"))
    }

    /// Los entrenos llegaban agrupados por procedencia (logs, luego los del reloj,
    /// luego los sueltos). Ahora que las comidas llevan hora, el día tiene que poder
    /// leerse como una secuencia sin que el modelo la recomponga.
    func testTodaysWorkoutsComeOutInChronologicalOrder() throws {
        let now = date("2026-08-10 22:00")
        let context = AIContext(
            generatedAt: now, locale: "es_ES", profile: fullProfile(),
            workoutSessions: [],
            // El log es de la tarde; el workout del reloj, de la mañana.
            workoutLogs: [
                AIWorkoutLogSnapshot(
                    id: UUID().uuidString, sessionId: nil, sessionName: "Empuje",
                    startedAt: date("2026-08-10 19:00"), endedAt: nil,
                    durationSeconds: 3_600, linkedHealthWorkoutId: nil, exercises: []
                )
            ],
            manualEntries: [], meals: [],
            healthDays: [],
            healthWorkouts: [
                AIHealthWorkoutSnapshot(
                    id: UUID().uuidString, activityType: "Carrera",
                    startDate: date("2026-08-10 08:00"), endDate: date("2026-08-10 08:40"),
                    durationSeconds: 2_400, totalCalories: 400,
                    totalDistanceMeters: nil, averageHeartRate: 150,
                    linkedTrainingId: nil, linkedEntryDate: nil
                )
            ]
        )

        let request = AICoachRequestApiDTO(context: context, topic: .daily, question: nil, now: now)

        let names = request.today.workouts.map(\.name)
        XCTAssertEqual(names, ["Carrera", "Empuje"], "primero el de la mañana")
    }

    // MARK: - Ciclado semanal de calorías

    /// Un perfil que cicla: sábado libre a 3.100, resto estrictos a 2.500.
    private func cyclingProfile() -> AIProfileSnapshot {
        AIProfileSnapshot(
            name: "Fer", age: 38, gender: "Hombre",
            heightCm: 178, weightKg: 78.4,
            activityLevel: "Moderadamente activo", fitnessGoal: "Ganar musculo",
            dailyCalorieTarget: 2600, todayCalorieTarget: 2500,
            macroTargets: nutrition(2600, protein: 160),
            // Día estricto: 2.500 kcal con 165 g de proteína.
            todayMacroTargets: nutrition(2500, protein: 165),
            hasWeeklyCycling: true,
            freeDaysWeekdays: [7],              // sábado
            freeDayExtraCalories: 500,
            strictDayCalorieTarget: 2500,
            freeDayCalorieTarget: 3100
        )
    }

    private func meal(on date: Date, kcal: Double) -> AIMealSnapshot {
        AIMealSnapshot(
            id: UUID().uuidString, type: "Comida", timestamp: date, myMealName: nil,
            totalNutrition: nutrition(kcal, protein: 40), items: []
        )
    }

    /// Una fecha concreta cuyo día de la semana conocemos, para no depender de
    /// cuándo se ejecuten los tests.
    private func date(_ iso: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: iso)!
    }

    /// El objetivo del histórico era el MISMO para todos los días: la media
    /// semanal. Un sábado libre a 3.000 kcal llegaba comparado contra 2.500 y el
    /// modelo lo leía como pasarse 500, cuando estaba justo en plan.
    func testEachPastDayCarriesItsOwnCalorieTarget() throws {
        let saturday = date("2026-08-01 13:00")   // sábado
        let monday = date("2026-08-03 13:00")     // lunes
        let request = AICoachRequestApiDTO(
            context: makeContext(
                profile: cyclingProfile(),
                meals: [meal(on: saturday, kcal: 3_050), meal(on: monday, kcal: 2_480)]
            ),
            topic: .nutrition,
            question: nil
        )

        let days = request.nutritionHistory
        let saturdayEntry = try XCTUnwrap(days.first { $0.date == "2026-08-01" })
        let mondayEntry = try XCTUnwrap(days.first { $0.date == "2026-08-03" })

        XCTAssertEqual(saturdayEntry.targetCalories, 3_100, "el sábado es día libre")
        XCTAssertEqual(mondayEntry.targetCalories, 2_500, "el lunes es estricto")
    }

    func testWithoutCyclingEveryDayKeepsTheAverageTarget() throws {
        let request = AICoachRequestApiDTO(
            context: makeContext(
                profile: fullProfile(),
                meals: [meal(on: date("2026-08-01 13:00"), kcal: 2_400)]
            ),
            topic: .nutrition,
            question: nil
        )

        XCTAssertEqual(request.nutritionHistory.first?.targetCalories, 2_600)
    }

    /// Sin esto el coach ve el objetivo de hoy pero no sabe que el sábado es libre,
    /// así que no puede nombrar el patrón ni explicar por qué ese día sube.
    func testTheWeeklyCycleTravelsInTheProfile() throws {
        let request = AICoachRequestApiDTO(
            context: makeContext(profile: cyclingProfile()), topic: .nutrition, question: nil
        )

        XCTAssertEqual(request.profile.freeDays, [7])
        XCTAssertEqual(request.profile.freeDayExtraCalories, 500)
        // Los macros que se mandan son los del día ciclado, no los de la media: si no,
        // el objetivo de proteína no cuadraría con las kcal de al lado.
        XCTAssertEqual(request.profile.calorieTarget, 2_500)
        XCTAssertEqual(request.profile.proteinTargetG, 165, "los de hoy, no los de la media")

        let json = try encode(request)
        let profile = try XCTUnwrap(json["profile"] as? [String: Any])
        XCTAssertEqual(profile["free_days"] as? [Int], [7], "snake_case, como el resto")
        XCTAssertEqual(profile["free_day_extra_calories"] as? Int, 500)
    }

    func testAProfileWithoutCyclingSendsNoFreeDays() throws {
        let request = AICoachRequestApiDTO(
            context: makeContext(profile: fullProfile()), topic: .nutrition, question: nil
        )

        XCTAssertNil(request.profile.freeDays, "ausente, no lista vacía")
        XCTAssertNil(request.profile.freeDayExtraCalories)
    }

    // MARK: - La petición HTTP

    /// El idioma también viaja en la cabecera, y tenía que decir lo mismo que el
    /// body. Iba `Locale.current`, así que con el móvil en inglés el payload pedía
    /// "es" y la cabecera "en_US": bastaba con que el backend mirara la cabecera
    /// para que volviera el bug de contestar en inglés dentro de una app española.
    func testTheStreamAsksForTheAppLanguageNotTheDeviceOne() async throws {
        RequestSpy.reset()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RequestSpy.self]

        let dataSource = AICoachRemoteDataSource(
            network: Network(),
            authenticator: FakeAuthenticator(),
            baseURL: "https://example.invalid/",
            session: URLSession(configuration: configuration)
        )

        // Lo que se comprueba es la petición que sale; que el stub responda con un
        // `[DONE]` inmediato solo sirve para que el stream termine.
        for try await _ in dataSource.streamCoach(
            AICoachRequestApiDTO(context: makeContext(), topic: .daily, question: "¿qué tal?")
        ) {}

        let sent = try XCTUnwrap(RequestSpy.lastRequest)
        XCTAssertEqual(
            sent.value(forHTTPHeaderField: "Accept-Language"),
            AICoachRequestApiDTO.appLanguage,
            "cabecera y body deben pedir el mismo idioma"
        )
    }

    // MARK: - Dobles de red

    private struct FakeAuthenticator: AuthenticatorProtocol {
        func isLogged() async -> Bool { true }
        func getCurrentToken() async throws -> String { "token-de-prueba" }
        func getNewToken(with parameters: [String: Any], endpoint: Endpoint?) async throws {}
        func logout() async throws {}
        func get(token type: TokenType) async throws -> Token? { nil }
        func set(token: Token, for type: TokenType) async throws {}
    }

    /// Intercepta la petición antes de que salga a la red y contesta un SSE mínimo.
    private final class RequestSpy: URLProtocol {
        private static let lock = NSLock()
        private static var captured: URLRequest?

        static func reset() {
            lock.lock(); captured = nil; lock.unlock()
        }

        static var lastRequest: URLRequest? {
            lock.lock(); defer { lock.unlock() }
            return captured
        }

        override class func canInit(with request: URLRequest) -> Bool {
            lock.lock(); captured = request; lock.unlock()
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

        override func startLoading() {
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: nil,
                headerFields: ["Content-Type": "text/event-stream"]
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data("data: [DONE]\n\n".utf8))
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }
}

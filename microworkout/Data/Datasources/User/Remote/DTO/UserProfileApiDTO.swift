import Foundation

/// Shape exchanged with `/v1/profile`. Backend uses English keys; iOS entity
/// uses Spanish display strings as raw values, so we map both sides here.
struct UserProfileApiDTO: Codable {
    let name: String
    let height: Double
    let weight: Double
    let age: Int
    let gender: String
    let activityLevel: String
    let fitnessGoal: String?
    let macroProfile: String?
    let freeDays: [Int]
    let freeDayExtraCalories: Double?
    let coachTone: String?
    let coachDetail: String?
    let coachAvoidWeightTalk: Bool?

    enum CodingKeys: String, CodingKey {
        case name
        case height
        case weight
        case age
        case gender
        case activityLevel = "activity_level"
        case fitnessGoal = "fitness_goal"
        case macroProfile = "macro_profile"
        case freeDays = "free_days"
        case freeDayExtraCalories = "free_day_extra_calories"
        case coachTone = "coach_tone"
        case coachDetail = "coach_detail"
        case coachAvoidWeightTalk = "coach_avoid_weight_talk"
    }
}

// MARK: - Mapping
// iOS `UserProfile` enums use Spanish strings ("Hombre", "Sedentario", ...) as
// raw values because they're persisted directly in UserDefaults. The backend
// uses neutral English keys, so we translate on the boundary.

extension UserProfileApiDTO {
    static func from(domain profile: UserProfile) -> UserProfileApiDTO {
        UserProfileApiDTO(
            name: profile.name,
            height: profile.height,
            weight: profile.weight,
            age: profile.age,
            gender: UserProfileApiCoding.encode(gender: profile.gender),
            activityLevel: UserProfileApiCoding.encode(activity: profile.activityLevel),
            fitnessGoal: profile.fitnessGoal.map { UserProfileApiCoding.encode(goal: $0) },
            macroProfile: profile.macroProfile.map { UserProfileApiCoding.encode(macro: $0) },
            freeDays: profile.freeDays ?? [],
            freeDayExtraCalories: profile.freeDayExtraCalories,
            coachTone: profile.coachTone.map { UserProfileApiCoding.encode(tone: $0) },
            coachDetail: profile.coachDetail.map { UserProfileApiCoding.encode(detail: $0) },
            // El `?? false` es DELIBERADO y no se puede quitar: en el backend
            // `coach_tone` y `coach_detail` son `Optional[...] = None`, pero
            // `coach_avoid_weight_talk` es `bool = False` — no acepta null, y con
            // `extra="forbid"` mandarlo sería un 422. Tampoco tiene dónde guardar
            // "sin elegir": la columna es `BooleanField(default=False)`.
            //
            // El `Bool?` del dominio existe solo para leer perfiles guardados en el
            // dispositivo antes de que el campo existiera; nadie distingue "sin
            // elegir" de "false", así que colapsarlo aquí no pierde nada.
            coachAvoidWeightTalk: profile.coachAvoidWeightTalk ?? false
        )
    }

    func toDomain() -> UserProfile? {
        guard let gender = UserProfileApiCoding.decodeGender(gender),
              let activity = UserProfileApiCoding.decodeActivity(activityLevel)
        else { return nil }
        return UserProfile(
            name: name,
            height: height,
            weight: weight,
            age: age,
            gender: gender,
            activityLevel: activity,
            fitnessGoal: fitnessGoal.flatMap { UserProfileApiCoding.decodeGoal($0) },
            macroProfile: macroProfile.flatMap { UserProfileApiCoding.decodeMacro($0) },
            freeDays: freeDays.isEmpty ? nil : freeDays,
            freeDayExtraCalories: freeDayExtraCalories,
            coachTone: coachTone.flatMap { UserProfileApiCoding.decodeTone($0) },
            coachDetail: coachDetail.flatMap { UserProfileApiCoding.decodeDetail($0) },
            coachAvoidWeightTalk: coachAvoidWeightTalk
        )
    }
}

enum UserProfileApiCoding {
    // Las claves del backend son neutras; los raw values de iOS son el texto que
    // se pinta en pantalla. Se traduce en la frontera, como el resto.
    static func encode(tone: UserProfile.CoachTone) -> String {
        switch tone {
        case .close: return "close"
        case .direct: return "direct"
        case .technical: return "technical"
        }
    }

    static func decodeTone(_ raw: String) -> UserProfile.CoachTone? {
        switch raw {
        case "close": return .close
        case "direct": return .direct
        case "technical": return .technical
        default: return nil
        }
    }

    static func encode(detail: UserProfile.CoachDetail) -> String {
        switch detail {
        case .brief: return "brief"
        case .normal: return "normal"
        case .detailed: return "detailed"
        }
    }

    static func decodeDetail(_ raw: String) -> UserProfile.CoachDetail? {
        switch raw {
        case "brief": return .brief
        case "normal": return .normal
        case "detailed": return .detailed
        default: return nil
        }
    }

    static func encode(gender: UserProfile.Gender) -> String {
        switch gender {
        case .male: return "male"
        case .female: return "female"
        }
    }

    static func decodeGender(_ raw: String) -> UserProfile.Gender? {
        switch raw {
        case "male": return .male
        case "female": return .female
        default: return nil
        }
    }

    static func encode(activity: UserProfile.ActivityLevel) -> String {
        switch activity {
        case .sedentary: return "sedentary"
        case .light: return "light"
        case .moderate: return "moderate"
        case .active: return "active"
        case .veryActive: return "very_active"
        }
    }

    static func decodeActivity(_ raw: String) -> UserProfile.ActivityLevel? {
        switch raw {
        case "sedentary": return .sedentary
        case "light": return .light
        case "moderate": return .moderate
        case "active": return .active
        case "very_active": return .veryActive
        default: return nil
        }
    }

    static func encode(goal: UserProfile.FitnessGoal) -> String {
        switch goal {
        case .loseWeight: return "lose_weight"
        case .maintain: return "maintain"
        case .gainMuscle: return "gain_muscle"
        }
    }

    static func decodeGoal(_ raw: String) -> UserProfile.FitnessGoal? {
        switch raw {
        case "lose_weight": return .loseWeight
        case "maintain": return .maintain
        case "gain_muscle": return .gainMuscle
        default: return nil
        }
    }

    static func encode(macro: UserProfile.MacroProfile) -> String {
        switch macro {
        case .balanced: return "balanced"
        case .lowCarb: return "low_carb"
        }
    }

    static func decodeMacro(_ raw: String) -> UserProfile.MacroProfile? {
        switch raw {
        case "balanced": return .balanced
        case "low_carb": return .lowCarb
        default: return nil
        }
    }
}

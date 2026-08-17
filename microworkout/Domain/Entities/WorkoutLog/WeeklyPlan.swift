import Foundation

/// Un día de la semana con la sesión que le toca.
///
/// Apunta a una `WorkoutSession` por id en vez de llevar sus ejercicios: si los
/// duplicara, editar la sesión no cambiaría el plan y habría dos sitios donde
/// arreglar lo mismo.
struct PlannedDay: Identifiable, Equatable, Codable {
    /// Índice de `Calendar`: 1=domingo … 7=sábado. Misma convención que
    /// `UserProfile.freeDays`, para no tener dos numeraciones de días en la app.
    let weekday: Int
    /// `nil` = descanso. Un día de descanso planificado es información: le dice al
    /// coach que hoy NO tocaba entrenar, que es distinto de que se te haya olvidado.
    var sessionId: UUID?
    var note: String?

    var id: Int { weekday }

    init(weekday: Int, sessionId: UUID? = nil, note: String? = nil) {
        self.weekday = weekday
        self.sessionId = sessionId
        self.note = note
    }

    var isRest: Bool { sessionId == nil }
}

/// Lo que el usuario tiene previsto entrenar cada día de la semana.
///
/// Hasta ahora la app sabía qué habías hecho pero no qué te tocaba: sin eso, "qué
/// me falta esta semana" no tiene respuesta posible y el coach solo puede describir
/// el pasado.
///
/// Es una semana FIJA de lunes a domingo, no un ciclo rodante de N días: cubre el
/// caso normal y evita tener que decidir qué pasa cuando te saltas un día.
struct WeeklyPlan: Equatable, Codable {
    var name: String
    var days: [PlannedDay]

    init(name: String = "", days: [PlannedDay] = []) {
        self.name = name
        self.days = days
    }

    static let empty = WeeklyPlan()

    /// Sin nombre y sin ningún día con sesión: no hay plan que contar ni que subir.
    var isEmpty: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !days.contains { $0.sessionId != nil }
    }

    func day(_ weekday: Int) -> PlannedDay? {
        days.first { $0.weekday == weekday }
    }

    /// Lo planificado para una fecha concreta.
    func day(on date: Date, calendar: Calendar = .current) -> PlannedDay? {
        day(calendar.component(.weekday, from: date))
    }

    var trainingDayCount: Int {
        days.filter { $0.sessionId != nil }.count
    }

    /// La semana ordenada para leerla, empezando en lunes.
    ///
    /// El orden de `days` es el de `weekday` (1=domingo), que sirve para indexar
    /// pero no para mostrar: nadie planifica una semana que empieza en domingo.
    var orderedFromMonday: [PlannedDay] {
        Self.weekdaysFromMonday.compactMap { day($0) }
    }

    static let weekdaysFromMonday = [2, 3, 4, 5, 6, 7, 1]

    /// Nombre del día en el idioma del dispositivo, a partir del índice de `Calendar`.
    static func weekdayName(_ weekday: Int, calendar: Calendar = .current) -> String {
        let symbols = calendar.standaloneWeekdaySymbols
        guard (1...symbols.count).contains(weekday) else { return "" }
        return symbols[weekday - 1].capitalized
    }
}

import Foundation

/// Aritmética de la hora de las comidas.
///
/// Está aparte de los ViewModels porque es lo único de esta función que se puede
/// equivocar en silencio: un cambio de hora que mueve la comida a otro día la hace
/// desaparecer de la pantalla, y eso no se ve revisando el código. Aquí es pura y
/// se puede fijar con tests, sin routers ni casos de uso de por medio.
enum MealTime {

    /// El día de una fecha en `yyyy-MM-dd`, **en la zona del usuario**.
    ///
    /// Es lo que se le manda al servidor para pedirle "las comidas de este día".
    /// Iba en UTC, y con cualquier zona por delante de Greenwich —España todo el
    /// año— la medianoche local cae en el día UTC ANTERIOR: pidiendo hoy llegaba la
    /// fecha de ayer, el servidor contestaba con las comidas de ayer y se sumaban a
    /// las de hoy. El backend filtra en `Europe/Madrid`, así que lo que espera es
    /// justamente la fecha local.
    static func daySlug(_ date: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    /// La hora elegida, llevada al día que se está registrando.
    ///
    /// Los selectores solo muestran hora y minuto, así que la fecha que traen es la
    /// de hoy por defecto. Usarla tal cual movería a hoy una comida que se está
    /// registrando en otro día.
    static func time(_ picked: Date, onDay day: Date, calendar: Calendar = .current) -> Date {
        let components = calendar.dateComponents([.hour, .minute], from: picked)
        return calendar.date(
            bySettingHour: components.hour ?? 12,
            minute: components.minute ?? 0,
            second: 0,
            of: day
        ) ?? picked
    }

    /// Cómo quedan las horas de una sección al fijar la primera comida en `newTime`.
    ///
    /// Se DESPLAZAN todas por igual en vez de igualarlas: cada alimento añadido crea
    /// su propio registro, así que una sección son varias horas a segundos de
    /// distancia, y aplanarlas perdería el orden en que se comieron las cosas.
    ///
    /// El resultado se recorta al día: un desplazamiento grande sobre una sección
    /// que abarca horas podría cruzar la medianoche, y una comida que se va a otro
    /// día desaparece de la pantalla sin que nada lo explique.
    ///
    /// - Returns: las horas nuevas, en el mismo orden que `timestamps`. Vacío si no
    ///   había nada que mover.
    static func shifted(
        _ timestamps: [Date],
        anchoringEarliestAt newTime: Date,
        within day: Date,
        calendar: Calendar = .current
    ) -> [Date] {
        guard let earliest = timestamps.min() else { return [] }

        let anchor = time(newTime, onDay: day, calendar: calendar)
        let delta = anchor.timeIntervalSince(earliest)

        let dayStart = calendar.startOfDay(for: day)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)?
            .addingTimeInterval(-1) ?? dayStart

        return timestamps.map { timestamp in
            min(max(timestamp.addingTimeInterval(delta), dayStart), dayEnd)
        }
    }

    /// `true` si mover la sección a `newTime` cambiaría realmente algo.
    ///
    /// Se compara **al minuto**, no por diferencia absoluta. Los registros llevan los
    /// segundos del reloj (09:00:42) y el selector solo sabe de horas y minutos, así
    /// que al aparecer emite 09:00 y esos 42 s parecerían una edición: cada render
    /// reescribiría —y resubiría— todas las comidas de la sección. Comparar al minuto
    /// los ignora sin perder una edición de verdad de un solo minuto.
    static func changes(
        _ timestamps: [Date],
        movingEarliestTo newTime: Date,
        within day: Date,
        calendar: Calendar = .current
    ) -> Bool {
        guard let earliest = timestamps.min() else { return false }
        let anchor = time(newTime, onDay: day, calendar: calendar)
        let earliestAtMinute = time(earliest, onDay: day, calendar: calendar)
        return earliestAtMinute != anchor
    }
}

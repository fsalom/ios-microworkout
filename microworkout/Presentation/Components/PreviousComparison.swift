import SwiftUI

/// Tarjeta con la "top set" de la sesión anterior, mostrada solo si TODAS las series
/// al peso máximo del entreno anterior comparten las mismas reps. Formato: "peso × reps × series".
/// Si las reps al peso máximo varían, no hay un top set bien definido y la card no se renderiza.
struct PreviousTopSetCard: View {
    let current: LoggedExercise
    let previous: LoggedExercise
    let previousDate: Date

    var body: some View {
        if let line = Self.formatTopSet(for: previous) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text("Top set anterior")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                    Spacer()
                    Text(formatDate(previousDate))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(line)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)

                    if let delta {
                        Text(delta.label)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(delta.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(delta.color.opacity(0.15)))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.tertiarySystemGroupedBackground))
            )
        }
    }

    private var delta: (label: String, color: Color)? {
        guard let previousMax = Self.maxWeight(in: previous),
              let currentMax = Self.maxWeight(in: current) else { return nil }
        let diff = currentMax - previousMax
        if abs(diff) < 0.01 { return ("=", .secondary) }

        let arrow = diff > 0 ? "▲" : "▼"
        let color: Color = diff > 0 ? .green : .red

        // Avoid divide-by-zero (e.g. bodyweight pull-ups with 0 kg load).
        if previousMax < 0.01 {
            return (
                "\(arrow) \(PreviousComparisonFormatting.short(abs(diff))) kg",
                color
            )
        }
        let percent = (diff / previousMax) * 100
        return (
            "\(arrow) \(PreviousComparisonFormatting.short(abs(percent)))% peso máx.",
            color
        )
    }

    /// Returns the top-set summary. Picks the heaviest weight; among sets at that weight,
    /// the highest rep count; then counts how many sets match that exact (weight, reps) pair.
    /// Format: "<weight> kg × <reps> × <count>". Returns nil if there's no set with weight+reps.
    static func formatTopSet(for exercise: LoggedExercise) -> String? {
        let sets = exercise.sets.filter { $0.weight != nil && $0.reps != nil }
        guard !sets.isEmpty else { return nil }
        guard let maxWeight = sets.map({ $0.weight! }).max() else { return nil }

        let atMaxWeight = sets.filter { abs($0.weight! - maxWeight) < 0.01 }
        guard let bestReps = atMaxWeight.compactMap({ $0.reps }).max() else { return nil }

        let count = atMaxWeight.filter { $0.reps == bestReps }.count
        let weightStr = PreviousComparisonFormatting.short(maxWeight)
        return "\(weightStr) kg × \(bestReps) × \(count)"
    }

    private static func maxWeight(in exercise: LoggedExercise) -> Double? {
        exercise.sets.compactMap { $0.weight }.max()
    }

    private func formatDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Hoy" }
        if cal.isDateInYesterday(date) { return "Ayer" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}

enum PreviousComparisonFormatting {
    static func short(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}

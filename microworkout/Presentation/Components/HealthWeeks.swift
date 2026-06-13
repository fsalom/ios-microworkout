import SwiftUI

struct HealthWeeksView: View {
    @Binding var weeks: [[HealthDay]]
    var selectedDate: Date? = nil
    let daysOfWeek = ["L", "M", "X", "J", "V", "S", "D"]
    var onDayTap: ((HealthDay) -> Void)? = nil

    var maxMinutes: Int {
        weeks.flatMap { $0.map { $0.minutesOfExercise } }.max() ?? 1
    }

    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter
    }()

    var body: some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 5) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 40, height: 40)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)

            ForEach(weeks.indices, id: \.self) { weekIndex in
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 5) {
                    ForEach(weeks[weekIndex].indices, id: \.self) { dayIndex in
                        let healthDay = weeks[weekIndex][dayIndex]
                        DayCell(
                            healthDay: healthDay,
                            maxMinutes: maxMinutes,
                            isSelected: isSelected(healthDay.date),
                            isToday: Calendar.current.isDate(healthDay.date, inSameDayAs: Date())
                        )
                        .onTapGesture { onDayTap?(healthDay) }
                    }
                }
            }
        }
    }

    private func isSelected(_ date: Date) -> Bool {
        guard let selectedDate else { return false }
        return Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }
}

private struct DayCell: View {
    let healthDay: HealthDay
    let maxMinutes: Int
    let isSelected: Bool
    let isToday: Bool

    private var heatmapOpacity: Double {
        maxMinutes > 0 ? Double(healthDay.minutesOfExercise) / Double(maxMinutes) : 0.2
    }

    var body: some View {
        // Usamos `.green` (color principal de la app) en vez de `Color.accentColor`
        // porque éste se resolvía a un fondo casi negro en modo oscuro cuando el
        // asset de accent del proyecto no está definido.
        let highlight = Color.green
        Text("\(healthDay.date, formatter: HealthWeeksView.dayFormatter)")
            .font(.caption)
            .fontWeight(isSelected ? .bold : (isToday ? .bold : .thin))
            .foregroundColor(isSelected ? .white : .primary)
            .frame(width: 40, height: 40)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.green.opacity(heatmapOpacity))
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(highlight)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(
                        isSelected
                            ? highlight
                            : (isToday ? Color.primary : .clear),
                        lineWidth: isSelected ? 2.5 : (isToday ? 2 : 0)
                    )
            )
            .scaleEffect(isSelected ? 1.08 : 1)
            .shadow(
                color: isSelected ? highlight.opacity(0.45) : .clear,
                radius: 6, x: 0, y: 2
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
    }
}

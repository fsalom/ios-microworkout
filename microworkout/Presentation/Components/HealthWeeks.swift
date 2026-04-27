import SwiftUI

struct HealthWeeksView: View {
    @Binding var weeks: [[HealthDay]]
    let daysOfWeek = ["L", "M", "X", "J", "V", "S", "D"]
    var onDayTap: ((HealthDay) -> Void)? = nil

    var maxMinutes: Int {
        weeks.flatMap { $0.map { $0.minutesOfExercise } }.max() ?? 1
    }

    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter
    }()

    var body: some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 5) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text("\(day)")
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
                        let opacity = maxMinutes > 0 ? Double(healthDay.minutesOfExercise) / Double(maxMinutes) : 0.2

                        let isToday = Calendar.current.isDate(healthDay.date, inSameDayAs: Date())
                        Text("\(healthDay.date, formatter: dateFormatter)")
                            .font(.caption)
                            .fontWeight(isToday ? .bold : .thin)
                            .frame(width: 40, height: 40)
                            .background(Color.green.opacity(opacity))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.primary, lineWidth: isToday ? 2 : 0)
                            )
                            .onTapGesture {
                                onDayTap?(healthDay)
                            }
                    }
                }
            }
        }
    }
}

#Preview {
    HealthWeeksView(weeks: .constant([[]]))
}

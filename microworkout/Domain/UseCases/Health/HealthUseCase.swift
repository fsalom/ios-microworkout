import Foundation

enum ErrorHealth: Error {
    case notAuthorized
    case emptyData
}

class HealthUseCase: HealthUseCaseProtocol {
    private var repository: HealthRepositoryProtocol

    init(repository: HealthRepositoryProtocol) {
        self.repository = repository
    }

    func requestAuthorization() async throws -> Bool {
        try await self.repository.requestAuthorization()
    }

    func fetchExerciseTimeToday() async throws -> Double? {
        try await self.repository.fetchExerciseTimeToday()
    }

    func fetchExerciseTime(startDate: Date, endDate: Date) async throws -> [Date : Double] {
        let data = try await self.repository.fetchExerciseTime(startDate: startDate,
                                                               endDate: endDate)
        guard let data = data else {
            throw ErrorHealth.emptyData
        }
        return data
    }

    func getDaysPerWeeksWithHealthInfo(for numberOfWeeks: Int) async throws -> [[HealthDay]] {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date().addingTimeInterval(-42 * 24 * 60 * 60))
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!

        let data = try await fetchExerciseTime(startDate: startDate, endDate: endOfDay)
        let weeks = self.getWeeksHealthDays(for: 4)
        let healthWeeks = self.getUpdated(weeks: weeks, with: data)
        return healthWeeks
    }

    private func getUpdated(weeks: [[HealthDay]], with exerciseData: [Date: Double]) -> [[HealthDay]]{
        let calendar = Calendar.current
        var weeksBackup = weeks
        for weekIndex in weeksBackup.indices {
            for dayIndex in weeksBackup[weekIndex].indices {
                let healthDay = weeksBackup[weekIndex][dayIndex]
                if let minutes = exerciseData[calendar.startOfDay(for: healthDay.date)] {
                    weeksBackup[weekIndex][dayIndex].minutesOfExercise = Int(minutes) // Actualizar minutos
                }
            }
        }
        return weeksBackup
    }

    private func getWeeksHealthDays(for numberOfWeeks: Int) -> [[HealthDay]] {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = (weekday == 1) ? 6 : weekday - 2  // Monday first day
        let currentWeekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: today)!
        var weeksArray: [[HealthDay]] = []

        for week in (0..<numberOfWeeks).reversed() {
            var weekDates: [HealthDay] = []
            let startOfWeek = calendar.date(byAdding: .weekOfYear, value: -week, to: currentWeekStart)!

            for day in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: day, to: startOfWeek) {
                    weekDates.append(HealthDay(date: date))
                }
            }
            weeksArray.append(weekDates)
        }
        return weeksArray
    }
}

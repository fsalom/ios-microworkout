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

    var isHealthDataAvailable: Bool {
        repository.isHealthDataAvailable
    }

    var authorizationStatus: HealthAuthorizationStatus {
        repository.authorizationStatus
    }

    func requestAuthorization() async throws -> Bool {
        try await self.repository.requestAuthorization()
    }

    func getDaysPerWeeksWithHealthInfo(for numberOfWeeks: Int) async throws -> [[HealthDay]] {
        let success = try await requestAuthorization()
        if success {
            let calendar = Calendar.current
            let startDate = calendar.startOfDay(for: Date().addingTimeInterval(-42 * 24 * 60 * 60))
            let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!

            let exerciseData = try await fetchExerciseTime(startDate: startDate, endDate: endOfDay)
            let standingData = try await fetchStandingTime(startDate: startDate, endDate: endOfDay)
            let stepsData = try await fetchStepsCount(startDate: startDate, endDate: endOfDay)

            let weeks = self.getWeeksHealthDays(for: 4)
            let healthWeeks = self.getUpdated(weeks: weeks,
                                              exerciseData: exerciseData,
                                              standingData: standingData,
                                              stepsData: stepsData)
            return healthWeeks
        } else {
            throw ErrorHealth.notAuthorized
        }
    }

    func getHealthInfoForToday() async throws -> HealthDay {
        if try await requestAuthorization() {
            let exercise = try? await self.repository.fetchExerciseTimeToday()
            let hoursStandingCount = try? await self.repository.fetchStandingTime()
            let steps = try? await self.repository.fetchStepsCountToday()
            let healthDay = HealthDay(date: Date(),
                                      minutesOfExercise: Int(exercise ?? 0),
                                      steps: Int(steps ?? 0),
                                      minutesStanding: Int(hoursStandingCount ?? 0))
            return healthDay
        } else {
            throw ErrorHealth.notAuthorized
        }
    }

    private func fetchExerciseTime(startDate: Date, endDate: Date) async throws -> [Date : Double] {
        if try await requestAuthorization() {
            let data = try await self.repository.fetchExerciseTime(startDate: startDate,
                                                                   endDate: endDate)
            guard let data = data else {
                throw ErrorHealth.emptyData
            }
            return data
        } else {
            throw ErrorHealth.notAuthorized
        }
    }

    private func fetchStepsCount(startDate: Date, endDate: Date) async throws -> [Date : Double] {
        if try await requestAuthorization() {
            let data = try await self.repository.fetchStepsCount(startDate: startDate, endDate: endDate)
            guard let data = data else {
                throw ErrorHealth.emptyData
            }
            return data
        } else {
            throw ErrorHealth.notAuthorized
        }
    }

    private func fetchStandingTime(startDate: Date, endDate: Date) async throws -> [Date : Double] {
        if try await requestAuthorization() {
            let data = try await self.repository.fetchStandingTime(startDate: startDate, endDate: endDate)
            guard let data = data else {
                throw ErrorHealth.emptyData
            }
            return data
        } else {
            throw ErrorHealth.notAuthorized
        }
    }

    private func getUpdated(weeks: [[HealthDay]],
                            exerciseData: [Date: Double],
                            standingData: [Date: Double],
                            stepsData: [Date: Double]) -> [[HealthDay]]{
        let calendar = Calendar.current
        var weeksBackup = weeks
        for weekIndex in weeksBackup.indices {
            for dayIndex in weeksBackup[weekIndex].indices {
                let healthDay = weeksBackup[weekIndex][dayIndex]
                if let minutes = exerciseData[calendar.startOfDay(for: healthDay.date)] {
                    weeksBackup[weekIndex][dayIndex].minutesOfExercise = Int(minutes) // Actualizar minutos
                }
                if let steps = stepsData[calendar.startOfDay(for: healthDay.date)] {
                    weeksBackup[weekIndex][dayIndex].steps = Int(steps) // Actualizar minutos
                }
                if let standing = standingData[calendar.startOfDay(for: healthDay.date)] {
                    weeksBackup[weekIndex][dayIndex].minutesStanding = Int(standing) // Actualizar minutos
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

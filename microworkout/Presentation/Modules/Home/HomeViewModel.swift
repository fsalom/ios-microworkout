import Foundation
import SwiftUICore

final class HomeViewModel: ObservableObject {
    @Published var trainings: [Training] = []
    @Published var weeks: [[HealthDay]] = [[]]

    private var router: HomeRouter
    private var healthKitManager: HealthKitManager!
    private var isHealthKitAuthorized: Bool = false
    private var currentTraining: Training = Training.mock()
    private var trainingUseCase: TrainingUseCase

    init(router: HomeRouter, trainingUseCase: TrainingUseCase, healthKitManager: HealthKitManager) {
        self.router = router
        self.trainingUseCase = trainingUseCase
        self.healthKitManager = healthKitManager
        self.weeks = self.getLastXWeeksDates(weeks: 4)
        self.loadTrainings()
        self.askForPermissions()
        self.getExerciseTime()
    }

    private func loadTrainings() {
        Task {
            await MainActor.run {
                trainings = trainingUseCase.getTrainings()
            }
        }
    }

    private func askForPermissions() {
        healthKitManager.requestAuthorization { authorization, error in
            self.isHealthKitAuthorized = authorization
        }
    }

    private func getExerciseTime() {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date().addingTimeInterval(-42 * 24 * 60 * 60))
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!


        HealthKitManager.shared.fetchExerciseTime(startDate: startDate, endDate: endOfDay) { data, error in
            if let data = data {
                DispatchQueue.main.async {
                    self.updateWeeks(with: data)
                }
            } else {
                print("Error obteniendo datos: \(error?.localizedDescription ?? "Desconocido")")
            }
        }
    }

    private func updateWeeks(with exerciseData: [Date: Double]) {
        let calendar = Calendar.current
        var weeksBackup = self.weeks
        self.weeks = [[]]
        for weekIndex in weeksBackup.indices {
            for dayIndex in weeksBackup[weekIndex].indices {
                let healthDay = weeksBackup[weekIndex][dayIndex]

                if let minutes = exerciseData[calendar.startOfDay(for: healthDay.date)] {
                    weeksBackup[weekIndex][dayIndex].minutesOfExercise = Int(minutes) // Actualizar minutos
                }
            }
        }
        self.weeks = weeksBackup
    }

    func goToTrainings() {
        router.goToWorkoutList()
    }

    func goToStart(this training: Training, and namespace: Namespace.ID) {
        router.goToStart(this: training, and: namespace)
    }

    func getLastXWeeksDates(weeks: Int) -> [[HealthDay]] {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = (weekday == 1) ? 6 : weekday - 2  // Ajuste para que Lunes sea el primer día
        let currentWeekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: today)!
        var weeksArray: [[HealthDay]] = []

        for week in (0..<weeks).reversed() {
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

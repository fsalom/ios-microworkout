//
//  CurrentSessionViewModel.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 19/7/25.
//


import SwiftUI
import Combine

class CurrentSessionViewModel: ObservableObject {
    @Published var searchText: String = "" {
        didSet {
            search(with: self.searchText)
        }
    }
    @Published var loggedExercises: [LoggedExercise] = []
    @Published var exercises: [Exercise] = []
    @Published var isRunning: Bool = false
    @Published var startTime: Date? = nil
    @Published var now: Date = Date()
    @Published var activeForm: ActiveExerciseForm?

    private var exerciseUseCase: ExerciseUseCaseProtocol
    private var loggedExerciseUseCase: LoggedExerciseUseCaseProtocol

    init(exerciseUseCase: ExerciseUseCaseProtocol, loggedExerciseUseCase: LoggedExerciseUseCaseProtocol) {
        self.exerciseUseCase = exerciseUseCase
        self.loggedExerciseUseCase = loggedExerciseUseCase
    }

    enum ActiveExerciseForm: Identifiable {
        case new(Exercise)
        case edit(LoggedExercise)

        var id: String {
            switch self {
            case .new(let exercise): return exercise.id
            case .edit(let logged): return logged.id
            }
        }
    }

    func search(with text: String) {
        Task { @MainActor in
            self.exercises = try! await self.exerciseUseCase.getExercises(contains: self.searchText)
        }
    }

    func startSession() {
        startTime = Date()
        isRunning = true
    }

    func stopSession() {
        startTime = nil
        isRunning = false
    }

    func updateNow(to date: Date) {
        now = date
    }

    func addLoggedExercise(_ new: LoggedExercise) {
        loggedExercises.append(new)
    }

    func updateLoggedExercise(_ updated: LoggedExercise) {
        if let index = loggedExercises.firstIndex(where: { $0.id == updated.id }) {
            loggedExercises[index] = updated
        }
    }

    func deleteExercises(with ids: [String]) {
        loggedExercises.removeAll { ids.contains($0.id) }
    }

    func toggleCompletion(for exerciseId: String) {
        if let index = loggedExercises.firstIndex(where: { $0.id == exerciseId }) {
            loggedExercises[index].isCompleted.toggle()
        }
    }

    func groupedByExercise() -> [Exercise: [LoggedExercise]] {
        self.loggedExerciseUseCase.groupByExercise(these: self.loggedExercises)
    }

    func orderedExercises() -> [Exercise] {
        self.loggedExerciseUseCase.order(these: self.loggedExercises)
    }
}

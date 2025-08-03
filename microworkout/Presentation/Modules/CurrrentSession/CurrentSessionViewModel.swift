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
            self.exercises = try! await self.exerciseUseCase.getAll(contains: self.searchText)
        }
    }

    func startSession() {
        startTime = Date()
        isRunning = true
    }

    func secondsBetween(_ start: Date, _ end: Date) -> Int {
        return Int(end.timeIntervalSince(start))
    }

    func stopSession() {
        Task { @MainActor in
            do {
                try await self.loggedExerciseUseCase.save(these: loggedExercises, with: secondsBetween(startTime!, Date()))
                startTime = nil
                isRunning = false
            } catch {
                isRunning = true
            }
        }
    }

    func updateNow(to date: Date) {
        now = date
    }

    func addExercise(with name: String) {
        Task { @MainActor in
            let exercise = try await self.exerciseUseCase.create(with: name)
            searchText = ""
            activeForm = .new(exercise)
        }
    }

    func addLoggedExercise(_ new: LoggedExercise) {
        Task { @MainActor in
            loggedExercises = try await self.loggedExerciseUseCase.add(new: new)
            activeForm = nil
        }
    }

    func updateLoggedExercise(_ updated: LoggedExercise) {
        Task { @MainActor in
            loggedExercises = try await self.loggedExerciseUseCase.update(this: updated)
            activeForm = nil
        }
    }

    func deleteExercises(with ids: [String]) {
        Task { @MainActor in
            for id in ids {
                loggedExercises = try await self.loggedExerciseUseCase.delete(this: id)
            }
        }
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

    func action(for grouped: [Exercise: [LoggedExercise]], and exercise: Exercise){
        if let last = grouped[exercise]?.last {
            let new = LoggedExercise(
                id: UUID().uuidString,
                exercise: last.exercise,
                reps: last.reps,
                weight: last.weight
            )
            activeForm = .new(new.exercise)
        } else {
            let new = LoggedExercise(
                id: UUID().uuidString,
                exercise: exercise,
                reps: 0,
                weight: 0
            )
            activeForm = .edit(new)
        }
    }
}

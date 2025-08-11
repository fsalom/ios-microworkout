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
    @Published var isSaved: Bool = false
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
                loggedExercises.removeAll()
                isSaved = true
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
            let loggedExercises = try await self.loggedExerciseUseCase.add(new: new)
            self.loggedExercises = reorder(loggedExercises)
            activeForm = nil
        }
    }

    func updateLoggedExercise(_ updated: LoggedExercise) {
        Task { @MainActor in
            let loggedExercises = try await self.loggedExerciseUseCase.update(this: updated)
            self.loggedExercises = reorder(loggedExercises)
            activeForm = nil
        }
    }

    func deleteExercises(with ids: [String]) {
        Task { @MainActor in
            for id in ids {
                let loggedExercises = try await self.loggedExerciseUseCase.delete(this: id)
                self.loggedExercises = reorder(loggedExercises)
            }
        }
    }

    func createLoggedExercise(from last: LoggedExercise) -> LoggedExercise {
        LoggedExercise(id: UUID().uuidString, exercise: last.exercise, reps: last.reps, weight: last.weight)
    }

    func getLast(for exercise: Exercise) -> LoggedExercise {
        let last = loggedExercises.last(where: { $0.exercise == exercise })
        return createLoggedExercise(from: last!)
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
            let new = createLoggedExercise(from: last)
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

    func reorder(_ loggedExercises: [LoggedExercise]) -> [LoggedExercise] {
        loggedExercises.sorted {
            let d0 = $0.date
            let d1 = $1.date
            return d0 > d1
        }
    }
}

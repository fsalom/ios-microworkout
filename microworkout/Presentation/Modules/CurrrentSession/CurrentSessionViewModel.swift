//
//  CurrentSessionViewModel.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 19/7/25.
//


import SwiftUI
import Combine

class CurrentSessionViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var loggedExercises: [LoggedExercise] = []
    @Published var isRunning: Bool = false
    @Published var startTime: Date? = nil
    @Published var now: Date = Date()
    @Published var activeForm: ActiveExerciseForm?
    private var exerciseUseCase: ExerciseUseCaseProtocol
    private var loggedExerciseUseCase: LoggedExerciseUseCaseProtocol

    init(exerciseUseCase: ExerciseUseCase, loggedExerciseUseCase: LoggedExerciseUseCaseProtocol) {
        self.exerciseUseCase = exerciseUseCase
        self.loggedExerciseUseCase = loggedExerciseUseCase
    }

    enum ActiveExerciseForm: Identifiable {
        case new(Exercise)
        case edit(LoggedExercise)

        var id: UUID {
            switch self {
            case .new(let exercise): return exercise.id
            case .edit(let logged): return logged.id
            }
        }
    }

    let exercises: [Exercise] = [
        Exercise(name: "Press de banca"),
        Exercise(name: "Sentadilla"),
        Exercise(name: "Peso muerto"),
        Exercise(name: "Dominadas"),
        Exercise(name: "Press militar"),
        Exercise(name: "Curl de bíceps"),
        Exercise(name: "Remo con barra")
    ]

    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return []
        } else {
            return exercises.filter { $0.name.lowercased().contains(searchText.lowercased()) }
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

    func deleteExercises(with ids: [UUID]) {
        loggedExercises.removeAll { ids.contains($0.id) }
    }

    func toggleCompletion(for exerciseId: UUID) {
        if let index = loggedExercises.firstIndex(where: { $0.id == exerciseId }) {
            loggedExercises[index].isCompleted.toggle()
        }
    }

    func groupedByExercise() -> [Exercise: [LoggedExercise]] {
        Dictionary(grouping: loggedExercises, by: { $0.exercise })
    }

    func orderedExercises() -> [Exercise] {
        loggedExercises.map { $0.exercise }.uniqued()
    }
}

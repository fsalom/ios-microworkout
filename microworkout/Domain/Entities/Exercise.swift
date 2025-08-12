//
//  Exercise.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 7/6/23.
//

import Foundation

public enum ExerciseType: String, CaseIterable, Identifiable, Codable {
    case distance
    case weight
    case kcal
    case reps
    case none

    public var id: Self { self }
}

/// Modelo principal de un ejercicio en el dominio.
public struct Exercise: Identifiable, Hashable, Codable {
    public let id: UUID
    public var name: String
    public var type: ExerciseType

    public init(
        id: UUID = UUID(),
        name: String,
        type: ExerciseType = .weight
    ) {
        self.id = id
        self.name = name
        self.type = type
    }
}

extension Exercise {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Exercise, rhs: Exercise) -> Bool {
        lhs.id == rhs.id
    }
}

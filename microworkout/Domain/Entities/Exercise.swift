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

/// Origen de un ejercicio en modo autenticado: `.synced` está en el servidor,
/// `.local` solo en el dispositivo (aún sin subir). Es un flag de UI, no se
/// persiste ni se envía al backend (excluido de Codable).
public enum ExerciseSource: Equatable {
    case synced
    case local
}

/// Modelo principal de un ejercicio en el dominio.
public struct Exercise: Identifiable, Hashable, Codable {
    public let id: UUID
    public var name: String
    public var type: ExerciseType
    public var source: ExerciseSource = .synced

    public init(
        id: UUID = UUID(),
        name: String,
        type: ExerciseType = .weight,
        source: ExerciseSource = .synced
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.source = source
    }

    // `source` es estado de UI: fuera de la (de)serialización.
    private enum CodingKeys: String, CodingKey {
        case id, name, type
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

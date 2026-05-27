import Foundation

/// Espejo on-disk de `SetMedia`. Mantiene los mismos nombres de campo que la
/// entidad de Domain (el JSON guardado por usuarios existentes se decodifica
/// igual). `SetMediaType` se serializa como `String` para desacoplar el
/// formato del enum.
struct SetMediaDTO: Codable, Equatable {
    let id: UUID
    let setId: UUID
    let type: String
    let filename: String
    let createdAt: Date
    let durationSeconds: Double?
    var thumbnailFilename: String?
}

extension SetMediaDTO {
    func toDomain() -> SetMedia {
        SetMedia(
            id: id,
            setId: setId,
            type: SetMediaType(rawValue: type) ?? .photo,
            filename: filename,
            createdAt: createdAt,
            durationSeconds: durationSeconds,
            thumbnailFilename: thumbnailFilename
        )
    }
}

extension SetMedia {
    func toDTO() -> SetMediaDTO {
        SetMediaDTO(
            id: id,
            setId: setId,
            type: type.rawValue,
            filename: filename,
            createdAt: createdAt,
            durationSeconds: durationSeconds,
            thumbnailFilename: thumbnailFilename
        )
    }
}

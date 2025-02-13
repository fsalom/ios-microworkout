import Foundation

enum TrainingType {
    case cardio
    case strength
}

struct Training: Identifiable {
    var id: UUID = UUID()
    var name: String
    var image: String
    var type: TrainingType
    var numberOfSets: Int
    var numberOfReps: Int
}

import Foundation

struct TrainingDTO: Codable {
    var id: UUID = UUID()
    var name: String
    var image: String
    var type: TrainingType
    var startedAt: Date?
    var completedAt: Date?
    var sets: [Date] = []
    var numberOfSetsCompleted: Int = 0
    var numberOfSets: Double
    var numberOfReps: Double
    var numberOfMinutesPerSet: Double
}

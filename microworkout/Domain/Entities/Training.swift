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
    var numberOfSetsForSlider: CGFloat {
        get { CGFloat(numberOfSets) }
        set { numberOfSets = Int(newValue) }
    }
    var numberOfReps: Int
    var numberOfRepsForSlider: Double {
        get { Double(numberOfReps) }
        set { numberOfReps = Int(newValue) }
    }
}

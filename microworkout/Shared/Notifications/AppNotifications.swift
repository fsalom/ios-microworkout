import Foundation

extension Notification.Name {
    static let mealsChanged = Notification.Name("app.mealsChanged")
    static let workoutLogsChanged = Notification.Name("app.workoutLogsChanged")
    /// Posted when set media is added/removed. `object` is the affected set UUID.
    static let setMediaChanged = Notification.Name("app.setMediaChanged")
}

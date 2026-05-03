import Foundation

class WorkoutLogLocalDataSource: WorkoutLogLocalDataSourceProtocol {
    private let localStorage: UserDefaultsManagerProtocol

    private enum Key: String {
        case sessions = "workoutLog.sessions"
        case logs = "workoutLog.logs"
    }

    init(localStorage: UserDefaultsManagerProtocol) {
        self.localStorage = localStorage
    }

    func getAllSessions() -> [WorkoutSessionDTO] {
        localStorage.get(forKey: Key.sessions.rawValue) ?? []
    }

    func saveSession(_ session: WorkoutSessionDTO) {
        var all: [WorkoutSessionDTO] = localStorage.get(forKey: Key.sessions.rawValue) ?? []
        if let idx = all.firstIndex(where: { $0.id == session.id }) {
            all[idx] = session
        } else {
            all.append(session)
        }
        localStorage.save(all, forKey: Key.sessions.rawValue)
    }

    func deleteSession(id: String) {
        var all: [WorkoutSessionDTO] = localStorage.get(forKey: Key.sessions.rawValue) ?? []
        all.removeAll { $0.id.uuidString == id }
        localStorage.save(all, forKey: Key.sessions.rawValue)
    }

    func getAllLogs() -> [WorkoutLogDTO] {
        localStorage.get(forKey: Key.logs.rawValue) ?? []
    }

    func saveLog(_ log: WorkoutLogDTO) {
        var all: [WorkoutLogDTO] = localStorage.get(forKey: Key.logs.rawValue) ?? []
        if let idx = all.firstIndex(where: { $0.id == log.id }) {
            all[idx] = log
        } else {
            all.append(log)
        }
        localStorage.save(all, forKey: Key.logs.rawValue)
    }

    func deleteLog(id: String) {
        var all: [WorkoutLogDTO] = localStorage.get(forKey: Key.logs.rawValue) ?? []
        all.removeAll { $0.id.uuidString == id }
        localStorage.save(all, forKey: Key.logs.rawValue)
    }
}

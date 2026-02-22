import Foundation
import WatchConnectivity

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var trainings: [Training] = []

    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func activate() {
        loadFromReceivedContext()
    }

    private func loadFromReceivedContext() {
        guard WCSession.isSupported() else { return }
        let context = WCSession.default.receivedApplicationContext
        decodeTrainings(from: context)
    }

    private func decodeTrainings(from context: [String: Any]) {
        guard let data = context["trainings"] as? Data else { return }
        do {
            let decoded = try JSONDecoder().decode([Training].self, from: data)
            DispatchQueue.main.async {
                self.trainings = decoded
            }
        } catch {
            print("[WatchConnectivity] Error decoding trainings: \(error)")
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("[WatchConnectivity] Activation error: \(error)")
        }
        loadFromReceivedContext()
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        decodeTrainings(from: applicationContext)
    }
}

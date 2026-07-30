import WatchConnectivity
import SwiftUI

class PhoneConnectivity: NSObject, ObservableObject {
    static let shared = PhoneConnectivity()
    @Published var receivedHabits: [WatchHabit] = []

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
}

extension PhoneConnectivity: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let data = message["habits"] as? Data,
           let habits = try? JSONDecoder().decode([WatchHabit].self, from: data) {
            DispatchQueue.main.async {
                self.receivedHabits = habits
                NotificationCenter.default.post(name: .init("WatchHabitsUpdated"), object: nil)
            }
        }
    }
}
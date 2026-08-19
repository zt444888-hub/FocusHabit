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

    private func handleHabitsData(_ data: Data) {
        guard let habits = try? JSONDecoder().decode([WatchHabit].self, from: data) else { return }
        DispatchQueue.main.async {
            self.receivedHabits = habits
            NotificationCenter.default.post(name: .init("WatchHabitsUpdated"), object: nil)
        }
    }
}

extension PhoneConnectivity: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    // 兼容：手机端升级后走 applicationContext（系统缓存、后台可达）
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let data = applicationContext["habits"] as? Data {
            handleHabitsData(data)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let data = message["habits"] as? Data {
            handleHabitsData(data)
        }
    }
}

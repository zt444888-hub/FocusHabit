import WatchConnectivity
import SwiftData

struct WatchHabit: Codable, Identifiable {
    let id: String
    let name: String
    let isCompleted: Bool
    let streak: Int
}

@MainActor
final class WatchSessionManager: NSObject {
    static let shared = WatchSessionManager()

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func sendHabits(_ habits: [Habit]) {
        guard WCSession.default.activationState == .activated else { return }
        let watchHabits = habits.filter { !$0.isArchived }.map { h in
            WatchHabit(id: h.id, name: h.name, isCompleted: h.isCompletedToday, streak: h.currentStreak)
        }
        if let data = try? JSONEncoder().encode(watchHabits) {
            WCSession.default.sendMessage(["habits": data], replyHandler: nil)
        }
    }
}

extension WatchSessionManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) { session.activate() }
}
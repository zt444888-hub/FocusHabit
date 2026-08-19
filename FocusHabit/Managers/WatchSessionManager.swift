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
        guard let data = try? JSONEncoder().encode(watchHabits) else { return }
        // 用 applicationContext 而非 sendMessage：sendMessage 要求 Watch App 在前台，
        // 失败即丢；applicationContext 由系统缓存，Watch 端下次可达时自动送达，可靠得多。
        do {
            try WCSession.default.updateApplicationContext(["habits": data])
        } catch {
            // Watch 未激活时静默失败，下次 sendHabits 会重试
        }
    }
}

extension WatchSessionManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) { session.activate() }
}

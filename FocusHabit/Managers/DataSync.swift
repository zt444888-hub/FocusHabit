import Foundation
import SwiftData

/// 数据变更后的统一同步门面：Widget + Watch 一次到位，
/// 避免各调用点散落 WidgetDataWriter / WatchSessionManager 调用。
@MainActor
enum DataSync {
    static func refreshAll(habits: [Habit]) {
        WidgetDataWriter.updateWidgetData(for: habits)
        WatchSessionManager.shared.sendHabits(habits)
    }
}

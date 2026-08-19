@preconcurrency import Foundation
import SwiftData
import WidgetKit

struct WidgetDataWriter {
    private static let defaults = UserDefaults(suiteName: "group.com.a1111.FocusHabit")
    private static let key = "todayHabits"
    /// 数据快照归属日期（startOfDay），供 Widget 判断跨天后展示"未完成"态
    private static let dateKey = "todayHabitsDate"

    static func updateWidgetData(for habits: [Habit]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let widgetHabits = habits.filter { !$0.isArchived }.map { h in
            WidgetHabit(
                id: h.id,
                name: h.name,
                isCompleted: h.completions.contains { c in
                    calendar.isDate(c.date, inSameDayAs: today)
                },
                streak: h.currentStreak,
                weeklyRate: h.weeklyCompletionRate
            )
        }

        if let data = try? JSONEncoder().encode(widgetHabits) {
            defaults?.set(data, forKey: key)
            defaults?.set(today, forKey: dateKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    static func loadWidgetHabits() -> [WidgetHabit] {
        guard let data = defaults?.data(forKey: key),
              let habits = try? JSONDecoder().decode([WidgetHabit].self, from: data) else {
            return []
        }
        return habits
    }

    /// 供 Widget Provider 判断快照是否已过期（跨天）
    static func snapshotDate() -> Date? {
        defaults?.object(forKey: dateKey) as? Date
    }
}

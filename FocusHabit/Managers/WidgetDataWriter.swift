import Foundation
import SwiftData

// Shared struct — must be identical to the one in FocusHabitWidget target
struct WidgetHabit: Codable, Identifiable {
    let id: String
    let name: String
    let isCompleted: Bool
    let streak: Int
}

struct WidgetDataWriter {
    private static let defaults = UserDefaults(suiteName: "group.com.yourapp.FocusHabit")
    private static let key = "todayHabits"

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
                streak: h.currentStreak
            )
        }

        if let data = try? JSONEncoder().encode(widgetHabits) {
            defaults?.set(data, forKey: key)
        }
    }

    static func loadWidgetHabits() -> [WidgetHabit] {
        guard let data = defaults?.data(forKey: key),
              let habits = try? JSONDecoder().decode([WidgetHabit].self, from: data) else {
            return []
        }
        return habits
    }
}

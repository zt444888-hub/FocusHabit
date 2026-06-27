import SwiftData
import Foundation

@Model
final class Habit {
    var id: String = UUID().uuidString
    var name: String
    var createdAt: Date
    var frequency: Frequency
    var reminderTime: Date?
    var isArchived: Bool
    var sortOrder: Int

    @Relationship(deleteRule: .cascade)
    var completions: [HabitCompletion] = []

    init(name: String, frequency: Frequency = .daily, reminderTime: Date? = nil, sortOrder: Int = 0) {
        self.name = name
        self.createdAt = Date()
        self.frequency = frequency
        self.reminderTime = reminderTime
        self.isArchived = false
        self.sortOrder = sortOrder
    }

    var currentStreak: Int {
        let calendar = Calendar.current
        let sortedDates = completions
            .filter(\.isCompleted)
            .map { calendar.startOfDay(for: $0.date) }
            .sorted(by: >)
        guard !sortedDates.isEmpty else { return 0 }
        var streak = 0
        let today = calendar.startOfDay(for: Date())
        var checkDate = today
        if !sortedDates.contains(today) {
            checkDate = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        }
        while sortedDates.contains(checkDate) {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        return streak
    }

    var isCompletedToday: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return completions.contains { Calendar.current.startOfDay(for: $0.date) == today && $0.isCompleted }
    }

    /// Rate of completion over the last frequency period (e.g. 7 days for daily, 1 for weekly)
    var weeklyCompletionRate: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lookbackDays: Int = {
            switch frequency {
            case .daily: return 7
            case .weekly: return 7 // Weekly habits are rated on a 7-day window
            case .weekday: return 5
            case .weekend: return 2
            }
        }()
        let startDate = calendar.date(byAdding: .day, value: -lookbackDays, to: today) ?? today
        let completed = completions.filter { $0.isCompleted && $0.date >= startDate && $0.date <= today }.count
        return min(Double(completed) / Double(lookbackDays), 1.0)
    }

    var totalCompletions: Int {
        completions.filter(\.isCompleted).count
    }
}

@Model
final class HabitCompletion {
    var date: Date
    var isCompleted: Bool
    var completedAt: Date?
    init(date: Date, isCompleted: Bool = true, completedAt: Date? = nil) {
        self.date = date
        self.isCompleted = isCompleted
        self.completedAt = completedAt ?? Date()
    }
}

enum Frequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case weekday = "Weekdays"
    case weekend = "Weekends"
    var systemImage: String {
        switch self {
        case .daily: return "calendar.day.timeline.left"
        case .weekly: return "calendar.badge.clock"
        case .weekday: return "briefcase"
        case .weekend: return "party.popper"
        }
    }
}

struct TimerPreset: Identifiable, Codable {
    var id = UUID()
    var focusDuration: TimeInterval
    var breakDuration: TimeInterval
    var name: String
    static let pomodoro = TimerPreset(focusDuration: 1500, breakDuration: 300, name: "Pomodoro")
    static let short = TimerPreset(focusDuration: 600, breakDuration: 180, name: "Quick")
    static let deep = TimerPreset(focusDuration: 2700, breakDuration: 600, name: "Deep Work")
    static let `default` = pomodoro
}

enum TimerState: Equatable {
    case idle
    case running
    case paused
    case finished(sessionType: SessionType)
}

enum SessionType: Equatable {
    case focus
    case `break`
}


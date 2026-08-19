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
    var targetDaysPerWeek: Int
    var colorName: String
    var iconName: String
    var canRepeatDaily: Bool
    var focusMinutes: Int = 25
    var lastFreezeDate: Date?
    var freezeBalance: Int
    var freezeResetMonth: Int?

    @Relationship(deleteRule: .cascade)
    var completions: [HabitCompletion] = []

    init(name: String, frequency: Frequency = .daily, reminderTime: Date? = nil, sortOrder: Int = 0, targetDaysPerWeek: Int = 7, colorName: String = "brand", iconName: String = "checklist", canRepeatDaily: Bool = false, focusMinutes: Int = 25) {
        self.name = name
        self.createdAt = Date()
        self.frequency = frequency
        self.reminderTime = reminderTime
        self.isArchived = false
        self.sortOrder = sortOrder
        self.targetDaysPerWeek = targetDaysPerWeek
        self.colorName = colorName
        self.iconName = iconName
        self.canRepeatDaily = canRepeatDaily
        self.focusMinutes = focusMinutes
        self.lastFreezeDate = nil
        self.freezeBalance = 3
        self.freezeResetMonth = nil
    }

    private var currentMonthKey: Int {
        let calendar = Calendar.current
        return calendar.component(.year, from: Date()) * 12
            + calendar.component(.month, from: Date())
    }

    /// 跨月后把冻结卡额度重置为每月上限。
    /// 由于 UI 直接读取 freezeBalance，需在展示时（onAppear）也调用一次以保持正确。
    func refreshFreezeBalanceIfNeeded() {
        if freezeResetMonth != currentMonthKey {
            freezeBalance = 3
            freezeResetMonth = currentMonthKey
        }
    }

    func freezeToday() {
        refreshFreezeBalanceIfNeeded()
        if let d = lastFreezeDate, Calendar.current.isDateInToday(d) { return }
        guard freezeBalance > 0 else { return }
        lastFreezeDate = Date()
        freezeBalance -= 1
    }

    var currentStreak: Int {
        let calendar = Calendar.current
        // 用 Set 去重：同一天多次打卡只算 1 天，连续次数按天累计
        let completedDays = Set(completions
            .filter(\.isCompleted)
            .map { calendar.startOfDay(for: $0.date) })
        guard !completedDays.isEmpty else { return 0 }
        var streak = 0
        let today = calendar.startOfDay(for: Date())
        var checkDate = today
        if !completedDays.contains(today) {
            checkDate = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        }
        while completedDays.contains(checkDate) {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        return streak
    }

    var isCompletedToday: Bool {
        todayCompletionCount > 0
    }

    var todayCompletionCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return completions.filter { Calendar.current.startOfDay(for: $0.date) == today && $0.isCompleted }.count
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
        // 用 Set 按天去重：同一天多次打卡只算 1 天；
        // 日期统一到 startOfDay 再比较，避免"今天"的完成记录（带时间分量）被边界排除
        let completedDays = Set(completions
            .filter(\.isCompleted)
            .map { calendar.startOfDay(for: $0.date) }
            .filter { $0 >= startDate && $0 <= today })
        // 新习惯（创建不足 lookbackDays）分母按创建以来的天数，避免前 7 天完成率恒被稀释
        let createdStart = calendar.startOfDay(for: createdAt)
        let daysSinceCreated = max(1, calendar.dateComponents([.day], from: createdStart, to: today).day ?? 0)
        let denominator = min(lookbackDays, daysSinceCreated)
        return min(Double(completedDays.count) / Double(denominator), 1.0)
    }

    var totalCompletions: Int {
        completions.filter(\.isCompleted).count
    }

    // MARK: - 打卡（统一入口，三处调用：卡片 / 深链 / AppIntent）

    /// 今天未完成时追加一次完成记录；返回是否新增。
    @discardableResult
    func checkInToday(context: ModelContext) -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        guard !completions.contains(where: {
            Calendar.current.isDate($0.date, inSameDayAs: today) && $0.isCompleted
        }) else { return false }
        completions.append(HabitCompletion(date: today))
        try? context.save()
        return true
    }

    /// 无条件追加一次今天的完成记录（用于允许每日多次打卡的习惯）。
    @discardableResult
    func addCompletionToday(context: ModelContext) -> Bool {
        completions.append(HabitCompletion(date: Calendar.current.startOfDay(for: Date())))
        try? context.save()
        return true
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

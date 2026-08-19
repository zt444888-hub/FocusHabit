import AppIntents
import SwiftData

/// Siri / 快捷指令：「开始 25 分钟专注」等
struct StartFocusIntent: AppIntent {
    static var title: LocalizedStringResource = "Start a focus session"
    static var description = IntentDescription("Starts the pomodoro focus timer.")

    @Parameter(title: "Focus minutes", default: 25, requestValueDialog: "How many minutes?")
    var minutes: Int

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let clamped = min(max(minutes, 1), 180)
        try await MainActor.run {
            let preset = TimerPreset(
                focusDuration: TimeInterval(clamped * 60),
                breakDuration: TimerManager.shared.currentPreset.breakDuration,
                name: T("Quick Focus")
            )
            TimerManager.shared.selectPreset(preset)
            TimerManager.shared.startNextFocus()
        }
        return .result(dialog: IntentDialog(stringLiteral: String(format: T("Focus started. %d minutes."), clamped)))
    }
}

/// Siri / 快捷指令：「打卡 [习惯]」
struct CheckInHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Check in a habit"
    static var description = IntentDescription("Logs today's check-in for a habit.")

    @Parameter(title: "Habit name", requestValueDialog: "Which habit did you complete?")
    var habitName: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let dialog = await MainActor.run { () -> String in
            guard let context = AppModelStore.mainContext else {
                return T("App is not ready.")
            }
            let habits = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
            let habit = habits.first {
                $0.name.localizedCaseInsensitiveCompare(habitName) == .orderedSame
            } ?? habits.first {
                $0.name.localizedCaseInsensitiveContains(habitName)
            }
            guard let habit else {
                return String(format: T("No habit named %@."), habitName)
            }
            if habit.checkInToday(context: context) {
                DataSync.refreshAll(habits: habits)
                return String(format: T("Checked in %@!"), habit.name)
            }
            return String(format: T("%@ is already checked in today."), habit.name)
        }
        return .result(dialog: IntentDialog(stringLiteral: dialog))
    }
}

/// 向「快捷指令」App 注册的可发现的 App Shortcut。
/// SwiftUI App 会自动发现此 provider，无需 @main（避免与 App 的 @main 冲突）。
struct FocusHabitShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartFocusIntent(),
            phrases: ["Start \(.applicationName) focus", "Begin \(.applicationName) pomodoro"],
            shortTitle: LocalizedStringResource("Start Focus", comment: ""),
            systemImageName: "timer"
        )
        AppShortcut(
            intent: CheckInHabitIntent(),
            phrases: ["Log \(.applicationName) habit", "Check in \(.applicationName)"],
            shortTitle: LocalizedStringResource("Check In", comment: ""),
            systemImageName: "checklist"
        )
    }
}
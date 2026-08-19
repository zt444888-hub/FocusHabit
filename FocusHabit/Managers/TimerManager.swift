import Foundation
import AudioToolbox
import UIKit
import SwiftData

@Observable
@MainActor
final class TimerManager {
    static let shared = TimerManager()
    var state: TimerState = .idle
    var timeRemaining: TimeInterval = 1500
    var currentPreset: TimerPreset = .pomodoro
    var totalTime: TimeInterval = 1500
    /// 本轮专注关联的习惯（由 FocusTimerView 在"完成 → 关联习惯"时设置，用于写入 FocusSession.relatedHabit）
    var currentHabit: Habit?
    var completedPomodorosToday: Int {
        didSet {
            // Persist across app restarts（含日期维度，跨天自动归零）
            Self.pomodorosDefaults.set(completedPomodorosToday, forKey: Self.pomodoroCountKey)
            Self.pomodorosDefaults.set(Calendar.current.startOfDay(for: Date()), forKey: Self.pomodoroDateKey)
        }
    }

    private var timer: Timer?
    private var backgroundTime: Date?
    private var timeAtBackground: TimeInterval = 0
    /// 本次连续运行段的起始时刻与起始剩余。tick 用真实经过时间重算，
    /// 避免后台抑制/前台卡顿导致 `timeRemaining -= 1` 失准。
    private var runningSince: Date?
    private var remainingAtRunStart: TimeInterval = 0
    /// 番茄计数归属的"今天"，用于进程存活跨午夜时自动归零
    private var pomodoroDay = Calendar.current.startOfDay(for: Date())
    private static let pomodorosDefaults = UserDefaults(suiteName: "group.com.a1111.FocusHabit") ?? .standard
    private static let pomodoroCountKey = "completedPomodorosToday"
    private static let pomodoroDateKey = "completedPomodorosDate"

    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return 1.0 - (timeRemaining / totalTime)
    }

    var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    init() {
        // 读取时校验日期：非今天则归零，避免昨天/更早的计数残留
        if let date = Self.pomodorosDefaults.object(forKey: Self.pomodoroDateKey) as? Date,
           Calendar.current.isDateInToday(date) {
            completedPomodorosToday = Self.pomodorosDefaults.integer(forKey: Self.pomodoroCountKey)
        } else {
            completedPomodorosToday = 0
        }
    }

    func selectPreset(_ preset: TimerPreset) {
        // 空闲或一轮结束（休息/准备下一轮）时允许切换预设
        switch state {
        case .idle, .finished:
            currentPreset = preset
            timeRemaining = preset.focusDuration
            totalTime = preset.focusDuration
        case .running, .paused:
            break
        }
    }

    func start() {
        guard state == .idle || state == .paused else { return }
        resetPomodoroCountIfDayChanged()
        runningSince = Date()
        remainingAtRunStart = timeRemaining
        state = .running
        UIApplication.shared.isIdleTimerDisabled = true
        // Live Activity：首次启动 request，暂停恢复时 update（门面内自动区分）
        LiveActivityManager.shared.sync(
            isRunning: true,
            isPaused: false,
            endDate: Date().addingTimeInterval(timeRemaining),
            remaining: timeRemaining,
            isBreak: totalTime == currentPreset.breakDuration,
            presetName: currentPreset.name
        )
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func pause() {
        guard state == .running else { return }
        runningSince = nil
        state = .paused
        UIApplication.shared.isIdleTimerDisabled = false
        timer?.invalidate()
        timer = nil
        // Live Activity：切到暂停态（UI 显示静态剩余时间）
        LiveActivityManager.shared.sync(
            isRunning: false,
            isPaused: true,
            endDate: Date(),
            remaining: timeRemaining,
            isBreak: totalTime == currentPreset.breakDuration,
            presetName: currentPreset.name
        )
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        runningSince = nil
        currentHabit = nil
        UIApplication.shared.isIdleTimerDisabled = false
        state = .idle
        timeRemaining = currentPreset.focusDuration
        totalTime = currentPreset.focusDuration
        LiveActivityManager.shared.endCurrent()
    }

    func skipBreak() {
        timer?.invalidate()
        timer = nil
        runningSince = nil
        currentHabit = nil
        UIApplication.shared.isIdleTimerDisabled = false
        timeRemaining = currentPreset.focusDuration
        totalTime = currentPreset.focusDuration
        state = .idle
        LiveActivityManager.shared.endCurrent()
    }

    /// Called from SwiftUI environment(\.scenePhase) when app enters background
    func handleAppBackground() {
        guard state == .running else { return }
        timer?.invalidate()
        timer = nil
        backgroundTime = Date()
        timeAtBackground = timeRemaining
    }

    func handleAppForeground() {
        guard let bgTime = backgroundTime, state == .running else { return }
        let elapsed = Date().timeIntervalSince(bgTime)
        timeRemaining = max(0, timeAtBackground - elapsed)
        backgroundTime = nil
        if timeRemaining <= 0 {
            completeCurrentSession()
        } else {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.tick()
                }
            }
        }
    }

    private func tick() {
        guard let since = runningSince else { return }
        resetPomodoroCountIfDayChanged()
        // 用真实经过时间重算剩余，而非计数递减；
        // 即使定时器被系统推迟，也能立刻校正回来。
        timeRemaining = max(0, remainingAtRunStart - Date().timeIntervalSince(since))
        if timeRemaining <= 0 {
            timer?.invalidate()
            timer = nil
            completeCurrentSession()
        }
    }

    private func completeCurrentSession() {
        // Live Activity：本轮结束，立即收起
        LiveActivityManager.shared.endCurrent()
        // 先取本轮起始时间，再清状态（否则 startTime 丢失）
        let sessionStart = runningSince ?? Date().addingTimeInterval(-totalTime)
        runningSince = nil
        UIApplication.shared.isIdleTimerDisabled = false
        let wasFocus = totalTime == currentPreset.focusDuration
        if wasFocus {
            completedPomodorosToday += 1
            scheduleCompletionNotification()
            persistFocusSession(startTime: sessionStart)
            state = .finished(sessionType: .focus)
            timeRemaining = currentPreset.breakDuration
            totalTime = currentPreset.breakDuration
        } else {
            state = .finished(sessionType: .break)
            timeRemaining = currentPreset.focusDuration
            totalTime = currentPreset.focusDuration
        }
        playSound()
    }

    /// 写 FocusSession 记录，供 Weekly Report 的专注时长统计使用（此前从未写入，报表恒为 0）
    private func persistFocusSession(startTime: Date) {
        guard let context = AppModelStore.mainContext else { return }
        let session = FocusSession(
            startTime: startTime,
            duration: totalTime,
            presetName: currentPreset.name
        )
        session.relatedHabit = currentHabit
        currentHabit = nil
        context.insert(session)
        try? context.save()
    }

    /// 进程存活跨过午夜时把今日番茄计数归零
    private func resetPomodoroCountIfDayChanged() {
        let today = Calendar.current.startOfDay(for: Date())
        guard pomodoroDay != today else { return }
        pomodoroDay = today
        completedPomodorosToday = 0
    }

    func startNextFocus() {
        timer?.invalidate()
        timer = nil
        currentHabit = nil
        state = .idle
        timeRemaining = currentPreset.focusDuration
        totalTime = currentPreset.focusDuration
        UIApplication.shared.isIdleTimerDisabled = true
        start()
    }

    private func scheduleCompletionNotification() {
        let content = UNMutableNotificationContent()
        content.title = T("Focus Session Complete!")
        content.body = T("Great job! Time for a break.")
        content.sound = .default
        let request = UNNotificationRequest(identifier: "focus-complete", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func playSound() {
        AudioServicesPlaySystemSound(1005)
    }
}

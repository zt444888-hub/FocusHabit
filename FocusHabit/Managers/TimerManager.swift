import Foundation
import AudioToolbox
import UIKit

@Observable
@MainActor
final class TimerManager {
    static let shared = TimerManager()
    var state: TimerState = .idle
    var timeRemaining: TimeInterval = 1500
    var currentPreset: TimerPreset = .pomodoro
    var totalTime: TimeInterval = 1500
    var completedPomodorosToday: Int {
        didSet {
            // Persist across app restarts
            Self.pomodorosDefaults.set(completedPomodorosToday, forKey: "completedPomodorosToday")
        }
    }

    private var timer: Timer?
    private var backgroundTime: Date?
    private var timeAtBackground: TimeInterval = 0
    private static let pomodorosDefaults = UserDefaults(suiteName: "group.com.a1111.FocusHabit") ?? .standard

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
        completedPomodorosToday = Self.pomodorosDefaults.integer(forKey: "completedPomodorosToday")
    }

    func selectPreset(_ preset: TimerPreset) {
        guard state == .idle else { return }
        currentPreset = preset
        timeRemaining = preset.focusDuration
        totalTime = preset.focusDuration
    }

    func start() {
        guard state == .idle || state == .paused else { return }
        state = .running
        UIApplication.shared.isIdleTimerDisabled = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func pause() {
        guard state == .running else { return }
        state = .paused
        UIApplication.shared.isIdleTimerDisabled = false
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        UIApplication.shared.isIdleTimerDisabled = false
        state = .idle
        timeRemaining = currentPreset.focusDuration
        totalTime = currentPreset.focusDuration
    }

    func skipBreak() {
        timer?.invalidate()
        timer = nil
        UIApplication.shared.isIdleTimerDisabled = false
        timeRemaining = currentPreset.focusDuration
        totalTime = currentPreset.focusDuration
        state = .idle
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
        guard timeRemaining > 0 else {
            timer?.invalidate()
            timer = nil
            completeCurrentSession()
            return
        }
        timeRemaining -= 1
    }

    private func completeCurrentSession() {
        UIApplication.shared.isIdleTimerDisabled = false
        let wasFocus = totalTime == currentPreset.focusDuration
        if wasFocus {
            completedPomodorosToday += 1
            scheduleCompletionNotification()
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

    func startNextFocus() {
        timer?.invalidate()
        timer = nil
        state = .idle
        timeRemaining = currentPreset.focusDuration
        totalTime = currentPreset.focusDuration
        UIApplication.shared.isIdleTimerDisabled = true
        start()
    }

    private func scheduleCompletionNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Focus Session Complete!"
        content.body = "Great job! Time for a break."
        content.sound = .default
        let request = UNNotificationRequest(identifier: "focus-complete", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func playSound() {
        AudioServicesPlaySystemSound(1005)
    }
}


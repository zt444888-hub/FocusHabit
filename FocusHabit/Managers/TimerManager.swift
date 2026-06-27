import Foundation
import UIKit

@Observable
@MainActor
final class TimerManager {
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
    private static let pomodorosDefaults = UserDefaults(suiteName: "group.com.yourapp.FocusHabit") ?? .standard

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
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func pause() {
        guard state == .running else { return }
        state = .paused
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        state = .idle
        timeRemaining = currentPreset.focusDuration
        totalTime = currentPreset.focusDuration
    }

    func skipBreak() {
        timer?.invalidate()
        timer = nil
        timeRemaining = currentPreset.focusDuration
        totalTime = currentPreset.focusDuration
        state = .idle
    }

    /// Called from SwiftUI environment(\.scenePhase) when app enters background
    func handleAppBackground() {
        // Pause the timer when the user leaves the app — prevents cheating and saves state
        if state == .running {
            pause()
        }
    }

    private func tick() {
        guard timeRemaining > 0 else {
            timer?.invalidate()
            timer = nil
            let wasFocus = totalTime == currentPreset.focusDuration
            if wasFocus {
                completedPomodorosToday += 1
                state = .finished(sessionType: .focus)
                timeRemaining = currentPreset.breakDuration
                totalTime = currentPreset.breakDuration
            } else {
                state = .finished(sessionType: .break)
                timeRemaining = currentPreset.focusDuration
                totalTime = currentPreset.focusDuration
            }
            playSound()
            return
        }
        timeRemaining -= 1
    }

    func startNextFocus() {
        timer?.invalidate()
        timer = nil
        state = .idle
        timeRemaining = currentPreset.focusDuration
        totalTime = currentPreset.focusDuration
        start()
    }

    private func playSound() {
        AudioServicesPlaySystemSound(1005)
    }
}


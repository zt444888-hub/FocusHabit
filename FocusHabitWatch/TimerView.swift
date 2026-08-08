import SwiftUI
import WatchKit

struct TimerView: View {
    @State private var timeRemaining: TimeInterval = 1500
    @State private var totalTime: TimeInterval = 1500
    @State private var isRunning = false
    @State private var timer: Timer?

    private let presets: [(name: String, duration: TimeInterval)] = [
        ("Pomodoro", 1500), ("Quick", 600), ("Deep", 2700)
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text(formattedTime)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()
                .padding(.top, 20)

            HStack(spacing: 8) {
                Button(isRunning ? "Pause" : "Start") {
                    if isRunning { pause() } else { start() }
                }
                .tint(.green)
                Button("Reset") { reset() }
                    .tint(.red)
                    .disabled(timeRemaining == totalTime && !isRunning)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(presets, id: \.name) { preset in
                        Button(preset.name) {
                            selectPreset(preset.duration)
                        }
                        .tint(.blue)
                        .disabled(isRunning)
                    }
                }
            }
        }
        .padding()
    }

    private var formattedTime: String {
        let m = Int(timeRemaining) / 60
        let s = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func start() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 { timeRemaining -= 1 }
            else {
                timer?.invalidate()
                timer = nil
                isRunning = false
                WKInterfaceDevice.current().play(.success)
            }
        }
    }

    private func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func reset() {
        pause()
        timeRemaining = totalTime
    }

    private func selectPreset(_ duration: TimeInterval) {
        totalTime = duration
        timeRemaining = duration
    }
}

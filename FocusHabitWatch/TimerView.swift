import SwiftUI
import WatchKit

struct TimerView: View {
    @State private var totalTime: TimeInterval = 1500
    @State private var timeRemaining: TimeInterval = 1500
    @State private var isRunning = false
    @State private var endDate: Date?

    private let presets: [(name: String, duration: TimeInterval)] = [
        ("Pomodoro", 1500), ("Quick", 600), ("Deep", 2700)
    ]
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 16) {
            Text(formattedTime)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()
                .padding(.top, 20)

            HStack(spacing: 8) {
                Button(isRunning ? WT("Pause") : WT("Start")) {
                    if isRunning { pause() } else { start() }
                }
                .tint(.green)
                Button(WT("Reset")) { reset() }
                    .tint(.red)
                    .disabled(timeRemaining == totalTime && !isRunning)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(presets, id: \.name) { preset in
                        Button(WT(preset.name)) { selectPreset(preset.duration) }
                            .tint(.blue)
                            .disabled(isRunning)
                    }
                }
            }
        }
        .padding()
        .onReceive(tick) { now in
            guard let end = endDate else { return }
            timeRemaining = max(0, end.timeIntervalSince(now))
            if timeRemaining <= 0 && isRunning {
                isRunning = false
                endDate = nil
                timeRemaining = totalTime
                WKInterfaceDevice.current().play(.success)
            }
        }
    }

    private var formattedTime: String {
        let m = Int(timeRemaining) / 60
        let s = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func start() {
        endDate = Date().addingTimeInterval(timeRemaining)
        isRunning = true
    }

    private func pause() {
        isRunning = false
        endDate = nil
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
import SwiftUI
import SwiftData

struct FocusTimerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query(filter: #Predicate<Habit> { !$0.isArchived })
    private var habits: [Habit]

    @State private var timer = TimerManager()
    @State private var selectedHabitForTimer: Habit?
    @State private var showCompletionAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                timerCircle

                timerControls

                Spacer()

                presetSelector

                todayStats
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Focus")
            .alert("Session Complete!", isPresented: $showCompletionAlert) {
                if !habits.isEmpty {
                    ForEach(habits) { habit in
                        Button(habit.name) {
                            markHabitForTimer(habit)
                        }
                    }
                }
                Button("Skip", role: .cancel) {
                    timer.startNextFocus()
                }
            } message: {
                Text("Great focus! Did you work on a habit?")
            }
            .onChange(of: timer.state) { _, newValue in
                if case .finished(.focus) = newValue {
                    showCompletionAlert = true
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background || newPhase == .inactive {
                    timer.handleAppBackground()
                }
            }
        }
    }

    private var timerCircle: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 8)
                .frame(width: 220, height: 220)

            Circle()
                .trim(from: 0, to: timer.progress)
                .stroke(
                    AngularGradient(
                        colors: [.orange, .orange.opacity(0.6)],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: timer.progress)

            VStack(spacing: 8) {
                Text(timer.formattedTime)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Text(timer.state == .idle ? "Ready" :
                     timer.state == .paused ? "Paused" :
                     timer.state == .running ? "Focusing..." : "")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.bottom, 32)
    }

    private var timerControls: some View {
        HStack(spacing: 24) {
            if timer.state == .idle || timer.state == .paused {
                Button {
                    timer.start()
                } label: {
                    Image(systemName: "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 64, height: 64)
                        .background(.orange, in: Circle())
                        .shadow(color: .orange.opacity(0.3), radius: 12, y: 4)
                }
            }

            if timer.state == .running {
                Button {
                    timer.pause()
                } label: {
                    Image(systemName: "pause.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 64, height: 64)
                        .background(.orange, in: Circle())
                        .shadow(color: .orange.opacity(0.3), radius: 12, y: 4)
                }
            }

            if timer.state != .idle {
                Button {
                    timer.reset()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .frame(width: 48, height: 48)
                        .background(Color(.systemGray5), in: Circle())
                }
            }
        }
        .padding(.bottom, 32)
    }

    private var presetSelector: some View {
        HStack(spacing: 12) {
            presetButton(.pomodoro)
            presetButton(.short)
            presetButton(.deep)
        }
        .padding(.bottom, 16)
    }

    private func presetButton(_ preset: TimerPreset) -> some View {
        let isSelected = timer.currentPreset.name == preset.name
        return Button {
            timer.selectPreset(preset)
        } label: {
            VStack(spacing: 4) {
                Text(preset.name)
                    .font(.caption.weight(.semibold))
                Text("\(Int(preset.focusDuration / 60))m")
                    .font(.caption2)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                isSelected ? Color.orange : Color(.systemGray6),
                in: Capsule()
            )
        }
        .disabled(timer.state == .running || timer.state == .paused)
    }

    private var todayStats: some View {
        HStack(spacing: 32) {
            VStack(spacing: 4) {
                Text("\(timer.completedPomodorosToday)")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.orange)
                Text("Pomodoros")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()
                .frame(height: 30)

            VStack(spacing: 4) {
                Text("\(habits.filter(\.isCompletedToday).count)")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.orange)
                Text("Habits Done")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
        )
    }

    private func markHabitForTimer(_ habit: Habit) {
        let today = Calendar.current.startOfDay(for: Date())
        if !habit.completions.contains(where: {
            Calendar.current.startOfDay(for: $0.date) == today
        }) {
            let completion = HabitCompletion(date: today)
            habit.completions.append(completion)
        }
        timer.startNextFocus()
    }
}

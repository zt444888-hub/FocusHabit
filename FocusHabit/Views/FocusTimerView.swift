import SwiftUI
import SwiftData

struct FocusTimerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query(filter: #Predicate<Habit> { !$0.isArchived })
    private var habits: [Habit]

    private let timer = TimerManager.shared
    @State private var selectedHabitForTimer: Habit?
    @State private var showCompletionAlert = false
    @State private var customPresets: [TimerPreset] = CustomPresetsManager.load()
    private let audioManager = AudioManager.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                timerCircle

                timerControls

                Spacer()

                presetSelector

                todayStats

                ambientSoundSelector
                    .padding(.top, 16)
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle(T("Focus"))
            .alert(T("Session Complete!"), isPresented: $showCompletionAlert) {
                if !habits.isEmpty {
                    ForEach(habits) { habit in
                        Button(habit.name) {
                            markHabitForTimer(habit)
                        }
                    }
                }
                Button(T("Skip"), role: .cancel) {
                    timer.startNextFocus()
                }
            } message: {
                Text(verbatim: T("Great focus! Did you work on a habit?"))
            }
            .onAppear {
                customPresets = CustomPresetsManager.load()
            }
            .onReceive(NotificationCenter.default.publisher(for: .init("CustomPresetsChanged"))) { _ in
                customPresets = CustomPresetsManager.load()
            }
            .onChange(of: timer.state) { _, newValue in
                if case .finished(.focus) = newValue {
                    showCompletionAlert = true
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    timer.handleAppForeground()
                } else if newPhase == .background || newPhase == .inactive {
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
                        colors: [.brand, .brand.opacity(0.6)],
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

                Text(timer.state == .idle ? T("Ready") :
                     timer.state == .paused ? T("Paused") :
                     timer.state == .running ? T("Focusing...") : "")
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
                        .background(.brand, in: Circle())
                        .shadow(color: .brand.opacity(0.3), radius: 12, y: 4)
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
                        .background(.brand, in: Circle())
                        .shadow(color: .brand.opacity(0.3), radius: 12, y: 4)
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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                presetButton(.pomodoro)
                presetButton(.short)
                presetButton(.deep)
                if StoreManager.shared.canCustomPresets {
                    ForEach(customPresets) { preset in
                        presetButton(preset)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 16)
    }

    private func presetButton(_ preset: TimerPreset) -> some View {
        let isSelected = timer.currentPreset.name == preset.name
        return Button {
            timer.selectPreset(preset)
        } label: {
            VStack(spacing: 4) {
                Text(verbatim: T(preset.name))
                    .font(.caption.weight(.semibold))
                Text(verbatim: "\(Int(preset.focusDuration / 60))\(T("min"))")
                    .font(.caption2)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                isSelected ? Color.brand : Color(.systemGray6),
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
                    .foregroundColor(.brand)
                Text(verbatim: T("Pomodoros"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()
                .frame(height: 30)

            VStack(spacing: 4) {
                Text("\(habits.filter(\.isCompletedToday).count)")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.brand)
                Text(verbatim: T("Habits Done"))
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

    private var ambientSoundSelector: some View {
        VStack(spacing: 8) {
            Text(verbatim: T("Ambient"))
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                ForEach(AudioManager.AmbientSound.allCases) { sound in
                    Button {
                        audioManager.toggle(sound)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: sound.icon)
                                .font(.title3)
                            Text(sound.displayName)
                                .font(.caption2)
                        }
                        .foregroundColor(audioManager.currentSound == sound && audioManager.isPlaying ? .brand : .secondary)
                        .frame(minWidth: 64)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 10)
                        .background(
                            audioManager.currentSound == sound && audioManager.isPlaying ?
                            Color.brand.opacity(0.12) : Color(.systemGray6),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                    }
                }
            }
        }
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

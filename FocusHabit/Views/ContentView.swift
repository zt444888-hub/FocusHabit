import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    @AppStorage("appLanguage") private var appLanguage = ""
    @AppStorage("darkMode") private var darkMode = false
    @Environment(\.modelContext) private var context
    @Query private var habits: [Habit]

    var body: some View {
        TabView(selection: $selectedTab) {
            HabitListView()
                .tabItem {
                    Label(T("Habits"), systemImage: "checklist")
                }
                .tag(0)

            FocusTimerView()
                .tabItem {
                    Label(T("Focus"), systemImage: "timer")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label(T("Settings"), systemImage: "gear")
                }
                .tag(2)
        }
        .onOpenURL(perform: handleURL)
        .onAppear {
            // 自动化/调试钩子：SIMCTL_CHILD_FH_AUTOSTART_FOCUS=1 启动即自动开始专注
            if ProcessInfo.processInfo.environment["FH_AUTOSTART_FOCUS"] == "1" {
                TimerManager.shared.start()
            }
            consumeSharedIfNeeded()
        }
        .onChange(of: selectedTab) { _, _ in consumeSharedIfNeeded() }
        .tint(.brand)
        .preferredColorScheme(darkMode ? .dark : .light)
        .id(appLanguage)
    }

    /// 处理小组件 / 灵动岛 / 快捷指令发来的深链：
    /// - focushabit://check/<id>  打卡指定习惯
    /// - focushabit://start      直接开始一轮专注（快捷指令/自动化可用）
    /// - focushabit://timer      打开专注计时页
    /// - focushabit://           打开习惯列表
    private func handleURL(_ url: URL) {
        guard url.scheme == "focushabit" else { return }
        switch url.host {
        case "timer":
            selectedTab = 1
        case "start":
            selectedTab = 1
            TimerManager.shared.start()
        case "check":
            let id = url.lastPathComponent
            if let habit = habits.first(where: { $0.id == id }) {
                checkIn(habit)
            }
        default:
            selectedTab = 0
        }
    }

    private func checkIn(_ habit: Habit) {
        if habit.checkInToday(context: context) {
            DataSync.refreshAll(habits: habits)
        }
    }

    /// 消费分享扩展写入的待导入习惯
    private func consumeSharedIfNeeded() {
        guard let name = ShareImport.consumePending() else { return }
        let habit = Habit(name: name, frequency: .daily, colorName: "brand", iconName: "checklist")
        habit.completions.append(HabitCompletion(date: Calendar.current.startOfDay(for: Date())))
        context.insert(habit)
        try? context.save()
        DataSync.refreshAll(habits: habits + [habit])
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Habit.self, inMemory: true)
}
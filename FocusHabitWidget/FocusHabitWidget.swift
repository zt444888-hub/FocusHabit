import WidgetKit
import SwiftUI

struct HabitEntry: TimelineEntry {
    let date: Date
    let habits: [WidgetHabit]
}

struct Provider: TimelineProvider {
    private let defaults = UserDefaults(suiteName: "group.com.a1111.FocusHabit")
    private let dateKey = "todayHabitsDate"

    func placeholder(in context: Context) -> HabitEntry {
        HabitEntry(date: Date(), habits: [
            WidgetHabit(id: UUID().uuidString, name: "Read 30 min", isCompleted: false, streak: 5, weeklyRate: 0.71),
            WidgetHabit(id: UUID().uuidString, name: "Exercise", isCompleted: true, streak: 12, weeklyRate: 0.86),
            WidgetHabit(id: UUID().uuidString, name: "Meditate", isCompleted: false, streak: 3, weeklyRate: 0.43),
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitEntry) -> Void) {
        completion(HabitEntry(date: Date(), habits: loadHabits()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitEntry>) -> Void) {
        let entry = HabitEntry(date: Date(), habits: loadHabits())
        // 常规 15 分钟刷新，并保证跨天时在本地午夜强制刷新，
        // 避免 Widget 一直展示昨天的打卡状态。
        let now = Date()
        let calendar = Calendar.current
        let midnight = calendar.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(3600)
        let nextRefresh = min(midnight, now.addingTimeInterval(15 * 60))
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func loadHabits() -> [WidgetHabit] {
        guard let data = defaults?.data(forKey: "todayHabits"),
              let habits = try? JSONDecoder().decode([WidgetHabit].self, from: data) else {
            return []
        }
        // 快照跨天：昨天的 isCompleted/streak 不再适用，展示为未完成
        let snapshotDate = defaults?.object(forKey: dateKey) as? Date
        guard let snapshotDate, Calendar.current.isDateInToday(snapshotDate) else {
            return habits.map {
                WidgetHabit(id: $0.id, name: $0.name, isCompleted: false, streak: 0, weeklyRate: 0)
            }
        }
        return habits
    }
}

struct FocusHabitWidgetEntryView: View {
    var entry: HabitEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall, .systemMedium:
            homeContent
        case .accessoryInline:
            accessoryInlineContent
        default:
            accessoryRectangularContent
        }
    }

    // MARK: 主屏组件：每行可点直达打卡
    private var homeContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checklist")
                    .font(.caption)
                    .foregroundColor(.brand)
                Text(WT("Today's Habits"))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary)
                Spacer()
                let done = entry.habits.filter(\.isCompleted).count
                Text("\(done)/\(entry.habits.count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if entry.habits.isEmpty {
                Spacer()
                Text(WT("No habits yet"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                let maxItems = family == .systemSmall ? 3 : 5
                ForEach(Array(entry.habits.prefix(maxItems)), id: \.id) { habit in
                    Link(destination: checkURL(habit.id)) {
                        HStack(spacing: 8) {
                            Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.caption)
                                .foregroundColor(habit.isCompleted ? .brand : .secondary)
                            Text(habit.name)
                                .font(.caption)
                                .strikethrough(habit.isCompleted)
                                .foregroundColor(habit.isCompleted ? .secondary : .primary)
                            Spacer()
                            if habit.streak > 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: "flame.fill")
                                        .font(.caption2)
                                        .foregroundColor(.brand)
                                    Text("\(habit.streak)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .containerBackground(.background, for: .widget)
    }

    // MARK: 锁屏 · 单行文本
    private var accessoryInlineContent: some View {
        let done = entry.habits.filter(\.isCompleted).count
        return Text("\(done)/\(entry.habits.count) \(WT("Today"))")
            .widgetURL(URL(string: "focushabit://")!)
    }

    // MARK: 锁屏 · 宫格
    private var accessoryRectangularContent: some View {
        let habits = entry.habits.prefix(3)
        let done = entry.habits.filter(\.isCompleted).count
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "checklist").font(.caption)
                Text("\(done)/\(entry.habits.count)")
                Spacer()
                Image(systemName: "timer").font(.caption)
            }
            if habits.isEmpty {
                Text(WT("No habits yet")).font(.caption)
            } else {
                ForEach(Array(habits), id: \.id) { h in
                    HStack(spacing: 6) {
                        Image(systemName: h.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.caption)
                        Text(h.name)
                            .font(.caption2)
                            .strikethrough(h.isCompleted)
                        Spacer()
                    }
                }
            }
        }
        .widgetURL(URL(string: "focushabit://")!)
    }

    private func checkURL(_ id: String) -> URL {
        URL(string: "focushabit://check/\(id)") ?? URL(string: "focushabit://")!
    }
}

struct FocusHabitWidget: Widget {
    let kind: String = "FocusHabitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FocusHabitWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(WT("Today's Habits (Widget)"))
        .description(WT("See and track your daily habits."))
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryInline,
            .accessoryRectangular,
        ])
    }
}

@main
struct FocusHabitWidgetBundle: WidgetBundle {
    var body: some Widget {
        FocusHabitWidget()
        FocusLiveActivity()
    }
}
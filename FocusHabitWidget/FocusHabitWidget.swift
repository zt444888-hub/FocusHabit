 import WidgetKit
 import SwiftUI
 
 struct HabitEntry: TimelineEntry {
     let date: Date
     let habits: [WidgetHabit]
 }
 
 struct WidgetHabit: Codable, Identifiable {
     let id: String
     let name: String
     let isCompleted: Bool
     let streak: Int
 }
 
 struct Provider: TimelineProvider {
     let defaults = UserDefaults(suiteName: "group.com.yourapp.FocusHabit")
     
     func placeholder(in context: Context) -> HabitEntry {
         HabitEntry(date: Date(), habits: [
             WidgetHabit(id: "1", name: "Read 30 min", isCompleted: false, streak: 5),
             WidgetHabit(id: "2", name: "Exercise", isCompleted: true, streak: 12),
             WidgetHabit(id: "3", name: "Meditate", isCompleted: false, streak: 3),
         ])
     }
     
     func getSnapshot(in context: Context, completion: @escaping (HabitEntry) -> Void) {
         let entry = HabitEntry(date: Date(), habits: loadHabits())
         completion(entry)
     }
     
     func getTimeline(in context: Context, completion: @escaping (Timeline<HabitEntry>) -> Void) {
         let entry = HabitEntry(date: Date(), habits: loadHabits())
         let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
         let timeline = Timeline(entries: [entry], policy: .after(refresh))
         completion(timeline)
     }
     
     private func loadHabits() -> [WidgetHabit] {
         guard let data = defaults?.data(forKey: "todayHabits"),
               let habits = try? JSONDecoder().decode([WidgetHabit].self, from: data) else {
             return []
         }
         return habits
     }
 }
 
 struct FocusHabitWidgetEntryView: View {
     var entry: HabitEntry
     @Environment(\.widgetFamily) var family
     
     var body: some View {
         VStack(alignment: .leading, spacing: 8) {
             HStack {
                 Image(systemName: "checklist")
                     .font(.caption)
                     .foregroundColor(.orange)
                 Text("Today's Habits")
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
                 Text("No habits yet")
                     .font(.caption)
                     .foregroundColor(.secondary)
                 Spacer()
             } else {
                 let maxItems = family == .systemSmall ? 3 : 5
                 ForEach(entry.habits.prefix(maxItems)) { habit in
                     HStack(spacing: 8) {
                         Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                             .font(.caption)
                             .foregroundColor(habit.isCompleted ? .orange : .secondary)
                         Text(habit.name)
                             .font(.caption)
                             .strikethrough(habit.isCompleted)
                             .foregroundColor(habit.isCompleted ? .secondary : .primary)
                         Spacer()
                         if habit.streak > 0 {
                             HStack(spacing: 2) {
                                 Image(systemName: "flame.fill")
                                     .font(.caption2)
                                     .foregroundColor(.orange)
                                 Text("\(habit.streak)")
                                     .font(.caption2)
                                     .foregroundColor(.secondary)
                             }
                         }
                     }
                 }
             }
         }
         .containerBackground(.background, for: .widget)
     }
 }
 
 struct FocusHabitWidget: Widget {
     let kind: String = "FocusHabitWidget"
     
     var body: some WidgetConfiguration {
         StaticConfiguration(kind: kind, provider: Provider()) { entry in
             FocusHabitWidgetEntryView(entry: entry)
         }
         .configurationDisplayName("Today's Habits")
         .description("See and track your daily habits.")
         .supportedFamilies([.systemSmall, .systemMedium])
     }
 }
 
 struct FocusHabitWidgetBundle: WidgetBundle {
     var body: some Widget {
         FocusHabitWidget()
     }
 }

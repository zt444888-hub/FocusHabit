import SwiftUI
import SwiftData

struct ReminderListView: View {
    @Query(filter: #Predicate<Habit> { !$0.isArchived && $0.reminderTime != nil }, sort: \.reminderTime)
    private var habits: [Habit]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if habits.isEmpty {
                    ContentUnavailableView(T("No Reminders"), systemImage: "bell.slash", description: Text(verbatim: T("Add a reminder when creating or editing a habit.")))
                }
                ForEach(habits) { habit in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(habit.name).font(.headline)
                            if let t = habit.reminderTime {
                                Text(t, style: .time).font(.caption).foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Button(habit.reminderTime != nil ? "Remove" : "Add") {
                            if habit.reminderTime != nil {
                                NotificationManager.removeHabitReminder(for: habit)
                                habit.reminderTime = nil
                                try? context.save()
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.brand)
                    }
                }
            }
            .navigationTitle(T("Reminders"))
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(T("Done")) { dismiss() } } }
        }
    }
}
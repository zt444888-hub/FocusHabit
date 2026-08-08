import SwiftUI
import SwiftData

struct ArchivedHabitsView: View {
    @Query(filter: #Predicate<Habit> { $0.isArchived }, sort: \.sortOrder)
    private var habits: [Habit]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var selectedHabit: Habit?

    var body: some View {
        NavigationStack {
            List {
                if habits.isEmpty {
                    ContentUnavailableView(T("No Archived Habits"), systemImage: "archivebox", description: Text(verbatim: T("Archive a habit to see it here.")))
                }
                ForEach(habits) { habit in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(habit.name)
                                .font(.headline)
                            Text(String(format: T("%d completions"), habit.totalCompletions))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(T("Unarchive")) {
                            habit.isArchived = false
                            try? context.save()
                        }
                        .font(.caption)
                        .foregroundColor(.brand)
                        .buttonStyle(.borderless)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedHabit = habit
                    }
                }
                .onDelete { indexSet in
                    for i in indexSet {
                        let habit = habits[i]
                        if let sessions = try? context.fetch(FetchDescriptor<FocusSession>()) {
                            for session in sessions where session.relatedHabit?.persistentModelID == habit.persistentModelID {
                                session.relatedHabit = nil
                            }
                        }
                        context.delete(habit)
                    }
                    try? context.save()
                }
            }
            .navigationTitle(T("Archived Habits"))
            .navigationDestination(item: $selectedHabit) { habit in
                HabitDetailView(habit: habit)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(T("Close")) { dismiss() }
                }
            }
        }
    }
}

import SwiftUI
import SwiftData

struct ArchivedHabitsView: View {
    @Query(filter: #Predicate<Habit> { $0.isArchived }, sort: \.sortOrder)
    private var habits: [Habit]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

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
                            Text("\(habit.totalCompletions) completions")
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
                    }
                }
                .onDelete { indexSet in
                    for i in indexSet {
                        context.delete(habits[i])
                    }
                    try? context.save()
                }
            }
            .navigationTitle(T("Archived Habits"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(T("Close")) { dismiss() }
                }
            }
        }
    }
}

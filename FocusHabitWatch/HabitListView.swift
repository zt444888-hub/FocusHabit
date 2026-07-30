import SwiftUI

struct HabitListView: View {
    @State private var habits: [WatchHabit] = []
    @State private var session = PhoneConnectivity.shared

    var body: some View {
        List {
            if habits.isEmpty {
                ContentUnavailableView("No Habits", systemImage: "checklist", description: Text("Open the iPhone app to add habits."))
            }
            ForEach(habits) { habit in
                HStack {
                    Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(habit.isCompleted ? .green : .gray)
                    Text(habit.name)
                        .strikethrough(habit.isCompleted)
                    Spacer()
                    if habit.streak > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                            Text("\(habit.streak)")
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                    }
                }
            }
        }
        .navigationTitle("Today")
        .onAppear {
            habits = session.receivedHabits
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("WatchHabitsUpdated"))) { _ in
            habits = session.receivedHabits
        }
    }
}

struct WatchHabit: Identifiable, Codable {
    let id: String
    let name: String
    let isCompleted: Bool
    let streak: Int
}
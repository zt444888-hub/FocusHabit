import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var allHabits: [Habit]
    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "checklist")
                            .font(.system(size: 40))
                            .foregroundStyle(.orange)
                        Text("FocusHabit")
                            .font(.title2.weight(.bold))
                        Text("Build habits that stick.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                Section("Your Stats") {
                    let totalHabits = allHabits.count
                    let activeHabits = allHabits.filter { !$0.isArchived }.count
                    let totalCompletions = allHabits.reduce(0) { $0 + $1.totalCompletions }

                    StatRow(icon: "circle.grid.3x3.fill", label: "Total Habits", value: "\(totalHabits)")
                    StatRow(icon: "checkmark.circle", label: "Active Habits", value: "\(activeHabits)")
                    StatRow(icon: "star.fill", label: "Total Completions", value: "\(totalCompletions)")
                }

                Section("Data") {
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("Delete All Data", systemImage: "trash")
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://apps.apple.com/app/idXXXXXXXXX?action=write-review")!) {
                        HStack {
                            Label("Rate on App Store", systemImage: "star")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Reset All Data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("This will permanently delete all your habits and history.")
            }
        }
    }

    private func deleteAllData() {
        for habit in allHabits {
            context.delete(habit)
        }
        try? context.save()
    }
}

private struct StatRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.orange)
        }
    }
}


import SwiftUI
import SwiftData

struct HabitDetailView: View {
    let habit: Habit
    @Environment(\.modelContext) private var context
    @State private var showEditSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                statsHeader
                freezeCard
                monthGrid
                recentRecords
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEditSheet = true }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            AddHabitView(habit: habit)
        }
    }

    // MARK: - Focus Time

    private var totalFocusSeconds: Double {
        let habitID = habit.persistentModelID
        let predicate = #Predicate<FocusSession> { session in
            session.relatedHabit?.persistentModelID == habitID
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        guard let sessions = try? context.fetch(descriptor) else { return 0 }
        return sessions.reduce(0) { $0 + $1.duration }
    }

    private var formattedFocusTime: String {
        let hours = Int(totalFocusSeconds) / 3600
        let minutes = (Int(totalFocusSeconds) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        HStack(spacing: 12) {
            // Streak
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundStyle(.brand)
                    Text("\(habit.currentStreak)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                Text(verbatim: T("day streak"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            // Weekly rate ring
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 5)
                        .frame(width: 52, height: 52)
                    Circle()
                        .trim(from: 0, to: habit.weeklyCompletionRate)
                        .stroke(Color.brand, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: 52, height: 52)
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(habit.weeklyCompletionRate * 100))%")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.brand)
                }
                Text(verbatim: T("weekly"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            // Total completions
            VStack(spacing: 6) {
                Text("\(habit.totalCompletions)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(verbatim: T("total"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            // Focus time
            VStack(spacing: 6) {
                Text(formattedFocusTime)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(verbatim: T("focus"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        )
    }

    // MARK: - Freeze Card

    private var freezeCard: some View {
        HStack {
            Image(systemName: "snowflake")
                .font(.title3)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 2) {
                if let d = habit.lastFreezeDate, Calendar.current.isDateInToday(d) {
                    Text(verbatim: T("Today frozen"))
                        .font(.subheadline.weight(.medium))
                    Text(verbatim: T("Streak protected"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if habit.freezeBalance > 0 {
                    Text(verbatim: T("Use a freeze"))
                        .font(.subheadline.weight(.medium))
                    Text("\(habit.freezeBalance) remaining this month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text(verbatim: T("No freezes left"))
                        .font(.subheadline.weight(.medium))
                    Text(verbatim: T("Resets next month"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if (habit.lastFreezeDate.map { !Calendar.current.isDateInToday($0) } ?? true) && habit.freezeBalance > 0 {
                Button("Freeze") {
                    habit.freezeToday()
                    try? context.save()
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .controlSize(.small)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.blue.opacity(0.08))
        )
    }

    // MARK: - 30-Day Grid

    private var monthGrid: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days: [Date] = (0..<35).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }.reversed()

        return VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: T("Last 35 Days"))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)

            HStack(spacing: 6) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption2.weight(.medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                    let isCompleted = habit.completions.contains { c in
                        calendar.isDate(c.date, inSameDayAs: date) && c.isCompleted
                    }
                    let isToday = calendar.isDateInToday(date)
                    let isFuture = date > today

                    Circle()
                        .fill(
                            isCompleted ? Color.brand
                            : isFuture ? Color(.systemGray6)
                            : Color(.systemGray5)
                        )
                        .frame(width: 14, height: 14)
                        .overlay(
                            isToday ?
                                Circle().stroke(Color.brand, lineWidth: 1.5)
                                : nil
                        )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        )
    }

    // MARK: - Recent Records

    private var sortedCompletions: [HabitCompletion] {
        habit.completions
            .filter(\.isCompleted)
            .sorted { $0.date > $1.date }
    }

    private var recentRecords: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: T("Recent Records"))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.bottom, 12)

            if sortedCompletions.isEmpty {
                HStack {
                    Spacer()
                    Text(verbatim: T("No records yet"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(sortedCompletions.prefix(20).enumerated()), id: \.offset) { _, completion in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.brand)
                            Text(completion.date, style: .date)
                                .font(.subheadline)
                            Spacer()
                            Text(completion.date, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)

                        if completion.date != sortedCompletions.prefix(20).last?.date {
                            Divider()
                                .padding(.leading, 24)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        )
    }
}

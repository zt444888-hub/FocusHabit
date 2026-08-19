import SwiftUI
import SwiftData

struct HabitDetailView: View {
    let habit: Habit
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
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
        .onAppear {
            habit.refreshFreezeBalanceIfNeeded()
            try? context.save()
        }
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(T("Edit")) { showEditSheet = true }
                Button {
                    NotificationManager.removeHabitReminder(for: habit)
                    habit.isArchived = true
                    try? context.save()
                    dismiss()
                } label: {
                    Image(systemName: "archivebox")
                }
                .accessibilityLabel(T("Archive"))
            }
        }
        .sheet(isPresented: $showEditSheet) {
            AddHabitView(habit: habit)
        }
    }

    // MARK: - Focus Time

    private var formattedFocusTime: String {
        let minutes = habit.focusMinutes
        if minutes >= 60 {
            let hours = minutes / 60
            let remaining = minutes % 60
            return remaining > 0 ? "\(hours)h \(remaining)m" : "\(hours)h"
        }
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
                    Text(String(format: T("%d remaining this month"), habit.freezeBalance))
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
                Button(T("Freeze")) {
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
        // 让 5 行 x 7 列网格的首列对齐 Calendar.firstWeekday，避免与星期表头错位
        let firstWeekday = calendar.firstWeekday
        let todayWeekday = calendar.component(.weekday, from: today)
        let daysOffset = (todayWeekday - firstWeekday + 7) % 7
        let weekStart = calendar.date(byAdding: .day, value: -daysOffset, to: today) ?? today
        let gridStart = calendar.date(byAdding: .day, value: -34, to: weekStart) ?? weekStart
        let days = (0..<35).compactMap { calendar.date(byAdding: .day, value: $0, to: gridStart) }
        // veryShortWeekdaySymbols 按 weekday-1 索引，旋转使 firstWeekday 置于首列
        let symbols = calendar.veryShortWeekdaySymbols
        let headers = (0..<7).map { symbols[(firstWeekday - 1 + $0) % 7] }

        return VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: T("Last 35 Days"))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)

            HStack(spacing: 6) {
                ForEach(headers, id: \.self) { day in
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

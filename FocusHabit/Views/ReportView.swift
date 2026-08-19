import SwiftUI
import SwiftData



struct ReportView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var allHabits: [Habit]
    @Query private var allSessions: [FocusSession]
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    premiumBanner
                    thisWeekCard
                    fourWeekChart
                    recentActivity
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(T("Weekly Report"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(T("Done")) { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Premium Banner

    @ViewBuilder
    private var premiumBanner: some View {
        if !StoreManager.shared.isPremium {
            Button {
                showPaywall = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: T("Upgrade to Premium"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        Text(verbatim: T("Unlock weekly reports & analytics"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.orange.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Data

    private var activeHabits: [Habit] {
        allHabits.filter { !$0.isArchived }
    }

    private var thisWeekRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let firstWeekday = calendar.firstWeekday
        let daysOffset = (weekday - firstWeekday + 7) % 7
        let weekStart = calendar.date(byAdding: .day, value: -daysOffset, to: today) ?? today
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? today
        return weekStart...weekEnd
    }

    private func weekRanges() -> [(label: String, range: ClosedRange<Date>)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let fmt = DateFormatter()
        fmt.dateFormat = "M/d"
        let firstWeekday = calendar.firstWeekday
        let weekday = calendar.component(.weekday, from: today)
        let daysOffset = (weekday - firstWeekday + 7) % 7

        return (0..<4).map { weekOffset in
            let daysFromStart = weekOffset * 7
            let weekStart = calendar.date(byAdding: .day, value: -(daysOffset + 7 + daysFromStart), to: today) ?? today
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? today
            let label = "\(fmt.string(from: weekStart))"
            return (label, weekStart...weekEnd)
        }.reversed()
    }

    private func completionRate(in range: ClosedRange<Date>) -> Double {
        var expected = 0, actual = 0
        for habit in activeHabits {
            let perWeek: Int = {
                switch habit.frequency {
                case .daily: return 7; case .weekly: return 1
                case .weekday: return 5; case .weekend: return 2
                }
            }()
            expected += perWeek
            let done = habit.completions.filter { $0.isCompleted && range.contains($0.date) }.count
            actual += min(done, perWeek)
        }
        guard expected > 0 else { return 0 }
        return Double(actual) / Double(expected)
    }

    private func focusSeconds(in range: ClosedRange<Date>) -> Double {
        allSessions.filter { range.contains($0.date) }.reduce(0) { $0 + $1.duration }
    }

    private var bestStreak: Int {
        activeHabits.map(\.currentStreak).max() ?? 0
    }

    // MARK: - This Week Card

    private var thisWeekCard: some View {
        let rate = completionRate(in: thisWeekRange)
        let focus = focusSeconds(in: thisWeekRange)
        let focusHours = Int(focus) / 3600
        let focusMin = (Int(focus) % 3600) / 60

        return VStack(spacing: 16) {
            HStack(spacing: 24) {
                StatItem(value: "\(Int(rate * 100))%", label: T("This Week"), color: .brand)
                StatItem(value: "\(bestStreak)", label: T("Best Streak"), color: .brand)
                StatItem(value: focusHours > 0 ? "\(focusHours)h \(focusMin)m" : "\(focusMin)m", label: T("Focus Time"), color: .brand)
            }

            if rate < 0.5 {
                Text(verbatim: T("Keep going! Try to complete more habits this week."))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        )
    }

    // MARK: - 4-Week Chart

    private var fourWeekChart: some View {
        let weeks = weekRanges()
        let rates = weeks.map { completionRate(in: $0.range) }
        let maxRate = max(rates.max() ?? 1, 0.01)
        let focusTimes = weeks.map { focusSeconds(in: $0.range) }

        return VStack(alignment: .leading, spacing: 16) {
            Text(verbatim: T("Last 4 Weeks"))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)

            // Bar chart
            HStack(alignment: .bottom, spacing: 16) {
                ForEach(0..<4, id: \.self) { i in
                    VStack(spacing: 6) {
                        Text("\(Int(rates[i] * 100))%")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.secondary)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(rates[i] >= 0.7 ? Color.brand : rates[i] >= 0.4 ? Color.brand.opacity(0.6) : Color.brand.opacity(0.3))
                            .frame(width: 32, height: max(8, CGFloat(rates[i] / maxRate) * 100))

                        Text(weeks[i].label)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)

            // Focus time mini chart
            if focusTimes.contains(where: { $0 > 0 }) {
                VStack(spacing: 8) {
                    Text(verbatim: T("Focus Time (min)"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    HStack(alignment: .bottom, spacing: 16) {
                        ForEach(0..<4, id: \.self) { i in
                            let mins = Int(focusTimes[i]) / 60
                            let maxMins = max(focusTimes.map { Int($0) / 60 }.max() ?? 1, 1)
                            VStack(spacing: 4) {
                                Text("\(mins)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.brand.opacity(0.5))
                                    .frame(width: 32, height: max(4, CGFloat(mins) / CGFloat(maxMins) * 60))
                            }
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

    // MARK: - Recent Activity

    private var recentActivity: some View {
        let allCompletions = activeHabits.flatMap { habit in
            habit.completions.filter(\.isCompleted).map { (habit.name, $0.date) }
        }.sorted { $0.1 > $1.1 }.prefix(10)

        return VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: T("Recent Activity"))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.bottom, 12)

            if allCompletions.isEmpty {
                Text(verbatim: T("No activity yet"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(Array(allCompletions.enumerated()), id: \.offset) { index, element in
                    HStack {
                        Circle().fill(Color.brand).frame(width: 8, height: 8)
                        Text(element.0)
                            .font(.subheadline)
                        Spacer()
                        Text(element.1, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 6)
                    if index < allCompletions.count - 1 {
                        Divider().padding(.leading, 16)
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

// MARK: - Stat Item

private struct StatItem: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(.primary)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}


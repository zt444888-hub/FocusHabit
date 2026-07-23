import XCTest
import SwiftData
@testable import FocusHabit

final class HabitModelTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() {
        super.setUp()
        let schema = Schema([Habit.self, HabitCompletion.self, FocusSession.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: schema, configurations: config)
        context = ModelContext(container)
    }

    override func tearDown() {
        context = nil
        container = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeHabit(name: String = "Test", frequency: Frequency = .daily, createdAt: Date? = nil) -> Habit {
        let habit = Habit(name: name, frequency: frequency)
        if let createdAt {
            habit.createdAt = createdAt
        }
        context.insert(habit)
        return habit
    }

    private func addCompletion(for habit: Habit, daysAgo: Int) {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        let completion = HabitCompletion(date: date)
        habit.completions.append(completion)
        try! context.save()
    }

    // MARK: - Live Streak Tests

    func testEmptyCompletionsReturnsZero() {
        let habit = makeHabit()
        XCTAssertEqual(habit.currentStreak, 0)
    }

    func testSingleCompletionTodayReturnsStreakOfOne() {
        let habit = makeHabit()
        addCompletion(for: habit, daysAgo: 0)
        XCTAssertEqual(habit.currentStreak, 1)
    }

    func testConsecutiveDaysReturnsCorrectStreak() {
        let habit = makeHabit()
        addCompletion(for: habit, daysAgo: 0)  // today
        addCompletion(for: habit, daysAgo: 1)  // yesterday
        addCompletion(for: habit, daysAgo: 2)  // day before
        XCTAssertEqual(habit.currentStreak, 3)
    }

    func testLiveStreakWhenTodayNotCompletedButYesterdayWas() {
        let habit = makeHabit()
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        guard let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart) else {
            XCTFail("Could not calculate yesterday's date")
            return
        }
        let completion = HabitCompletion(date: yesterdayStart)
        habit.completions.append(completion)
        try! context.save()
        // Live streak: yesterday completed, today not → should count 1
        XCTAssertEqual(habit.currentStreak, 1)
    }

    func testGapInMiddleBreaksStreak() {
        let habit = makeHabit()
        addCompletion(for: habit, daysAgo: 0)  // today
        addCompletion(for: habit, daysAgo: 1)  // yesterday
        addCompletion(for: habit, daysAgo: 3)  // 3 days ago (gap at day 2)
        addCompletion(for: habit, daysAgo: 4)  // 4 days ago
        // Streak should be 2 (today + yesterday), gap at day 2 breaks older streak
        XCTAssertEqual(habit.currentStreak, 2)
    }

    func testNoCompletionsForSeveralDaysReturnsZero() {
        let habit = makeHabit()
        addCompletion(for: habit, daysAgo: 5)  // only 5 days ago
        XCTAssertEqual(habit.currentStreak, 0)
    }

    func testStreakCountsOnlyConsecutiveDaysFromYesterdayOrToday() {
        let habit = makeHabit()
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        guard let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart),
              let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: todayStart),
              let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: todayStart) else {
            XCTFail("Could not calculate dates")
            return
        }
        habit.completions.append(HabitCompletion(date: yesterdayStart))
        habit.completions.append(HabitCompletion(date: twoDaysAgo))
        habit.completions.append(HabitCompletion(date: threeDaysAgo))
        try! context.save()
        // All consecutive from yesterday backwards: streak = 3
        XCTAssertEqual(habit.currentStreak, 3)
    }

    // MARK: - Weekly Completion Rate Tests

    func testWeeklyCompletionRateForNewHabit() {
        let habit = makeHabit(createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date())!)
        addCompletion(for: habit, daysAgo: 0)
        addCompletion(for: habit, daysAgo: 1)
        addCompletion(for: habit, daysAgo: 2)
        // Created 3 days ago, denominator = min(7, 3) = 3, 3/3 = 100%
        XCTAssertEqual(habit.weeklyCompletionRate, 1.0, accuracy: 0.001)
    }

    func testWeeklyCompletionRateForEstablishedHabit() {
        let habit = makeHabit(createdAt: Calendar.current.date(byAdding: .day, value: -60, to: Date())!)
        // Complete 3 of the last 7 days
        addCompletion(for: habit, daysAgo: 0)
        addCompletion(for: habit, daysAgo: 2)
        addCompletion(for: habit, daysAgo: 5)
        XCTAssertEqual(habit.weeklyCompletionRate, 3.0 / 7.0, accuracy: 0.001)
    }

    func testWeeklyCompletionRateZeroWhenNoCompletions() {
        let habit = makeHabit()
        XCTAssertEqual(habit.weeklyCompletionRate, 0, accuracy: 0.001)
    }

    // MARK: - Total Completions

    func testTotalCompletionsCountsCompletedOnly() {
        let habit = makeHabit()
        addCompletion(for: habit, daysAgo: 0)
        addCompletion(for: habit, daysAgo: 1)
        // Add an incomplete one
        let date = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let incomplete = HabitCompletion(date: date, isCompleted: true)
        habit.completions.append(incomplete)
        try! context.save()
        XCTAssertEqual(habit.totalCompletions, 3)
    }
}

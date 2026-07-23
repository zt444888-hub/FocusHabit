import XCTest
import SwiftData
@testable import FocusHabit

final class HabitCompletionTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() {
        super.setUp()
        let schema = Schema([Habit.self, HabitCompletion.self])
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

    private func makeHabit() -> Habit {
        let habit = Habit(name: "Test")
        context.insert(habit)
        return habit
    }

    private func todayDate() -> Date {
        Calendar.current.startOfDay(for: Date())
    }

    // MARK: - Create Completion

    func testAddCompletionToHabit() {
        let habit = makeHabit()
        let completion = HabitCompletion(date: todayDate())
        habit.completions.append(completion)
        try! context.save()

        XCTAssertEqual(habit.completions.count, 1)
        XCTAssertTrue(habit.isCompletedToday)
    }

    func testAddMultipleCompletions() {
        let habit = makeHabit()
        for day in 0..<5 {
            let date = Calendar.current.date(byAdding: .day, value: -day, to: Date())!
            let completion = HabitCompletion(date: date)
            habit.completions.append(completion)
        }
        try! context.save()

        XCTAssertEqual(habit.completions.count, 5)
        XCTAssertEqual(habit.totalCompletions, 5)
    }

    func testCompletionDateAccuracy() {
        let habit = makeHabit()
        let specificDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let completion = HabitCompletion(date: specificDate)
        habit.completions.append(completion)
        try! context.save()

        let isMatch = habit.completions.contains { c in
            Calendar.current.isDate(c.date, inSameDayAs: specificDate)
        }
        XCTAssertTrue(isMatch)
    }

    // MARK: - Delete Completion

    func testRemoveCompletionFromHabit() {
        let habit = makeHabit()
        let completion = HabitCompletion(date: todayDate())
        habit.completions.append(completion)
        try! context.save()
        XCTAssertTrue(habit.isCompletedToday)

        // Remove the completion
        if let existing = habit.completions.first(where: {
            Calendar.current.startOfDay(for: $0.date) == todayDate()
        }) {
            habit.completions.removeAll { $0.completedAt == existing.completedAt }
            context.delete(existing)
        }
        try! context.save()

        XCTAssertFalse(habit.isCompletedToday)
        XCTAssertEqual(habit.completions.count, 0)
    }

    func testCascadeDeleteRemovesCompletions() {
        let habit = makeHabit()
        habit.completions.append(HabitCompletion(date: todayDate()))
        habit.completions.append(HabitCompletion(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!))
        try! context.save()
        XCTAssertEqual(habit.completions.count, 2)

        // Delete the habit — cascade should remove completions
        context.delete(habit)
        try! context.save()

        // Verify completions are gone by trying to fetch them
        let descriptor = FetchDescriptor<HabitCompletion>()
        let remaining = try! context.fetch(descriptor)
        XCTAssertTrue(remaining.isEmpty)
    }

    // MARK: - Query Today

    func testIsCompletedTodayWithNoCompletions() {
        let habit = makeHabit()
        XCTAssertFalse(habit.isCompletedToday)
    }

    func testIsCompletedTodayWithTodaysCompletion() {
        let habit = makeHabit()
        habit.completions.append(HabitCompletion(date: todayDate()))
        try! context.save()
        XCTAssertTrue(habit.isCompletedToday)
    }

    func testIsCompletedTodayWithYesterdayOnly() {
        let habit = makeHabit()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        habit.completions.append(HabitCompletion(date: yesterday))
        try! context.save()
        XCTAssertFalse(habit.isCompletedToday)
    }

    // MARK: - Completion Count

    func testTotalCompletionsExcludesIncomplete() {
        let habit = makeHabit()
        habit.completions.append(HabitCompletion(date: todayDate(), isCompleted: true))
        habit.completions.append(HabitCompletion(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, isCompleted: true))
        try! context.save()
        XCTAssertEqual(habit.totalCompletions, 2)
    }

    func testStreakUpdatesAfterAddingCompletions() {
        let habit = makeHabit()
        XCTAssertEqual(habit.currentStreak, 0)

        habit.completions.append(HabitCompletion(date: todayDate()))
        try! context.save()
        XCTAssertEqual(habit.currentStreak, 1)

        habit.completions.append(HabitCompletion(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!))
        try! context.save()
        XCTAssertEqual(habit.currentStreak, 2)
    }
}

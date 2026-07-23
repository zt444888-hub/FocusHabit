import XCTest
import SwiftData
@testable import FocusHabit

final class FocusSessionTests: XCTestCase {
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

    private func makeHabit(name: String = "Test Habit") -> Habit {
        let habit = Habit(name: name)
        context.insert(habit)
        return habit
    }

    // MARK: - Creation

    func testCreateFocusSession() {
        let now = Date()
        let duration: TimeInterval = 1500  // 25 min
        let session = FocusSession(startTime: now, duration: duration, presetName: "Pomodoro")
        context.insert(session)
        try! context.save()

        XCTAssertEqual(session.duration, 1500)
        XCTAssertEqual(session.presetName, "Pomodoro")
        XCTAssertEqual(session.startTime, now)
        XCTAssertEqual(session.endTime, now.addingTimeInterval(1500))
        XCTAssertEqual(session.date, Calendar.current.startOfDay(for: now))
    }

    func testCreateMultipleSessions() {
        let now = Date()
        let sessions = [
            FocusSession(startTime: now, duration: 1500, presetName: "Pomodoro"),
            FocusSession(startTime: now.addingTimeInterval(-3600), duration: 600, presetName: "Quick"),
            FocusSession(startTime: now.addingTimeInterval(-7200), duration: 2700, presetName: "Deep Work"),
        ]
        for s in sessions {
            context.insert(s)
        }
        try! context.save()

        let descriptor = FetchDescriptor<FocusSession>()
        let fetched = try! context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 3)
    }

    // MARK: - Habit Relationship

    func testSessionWithRelatedHabit() {
        let habit = makeHabit(name: "晨间阅读")
        let session = FocusSession(startTime: Date(), duration: 1500, presetName: "Pomodoro")
        session.relatedHabit = habit
        context.insert(session)
        try! context.save()

        XCTAssertNotNil(session.relatedHabit)
        XCTAssertEqual(session.relatedHabit?.name, "晨间阅读")
        XCTAssertEqual(session.relatedHabit?.id, habit.id)
    }

    func testSessionWithoutRelatedHabit() {
        let session = FocusSession(startTime: Date(), duration: 1500, presetName: "Pomodoro")
        context.insert(session)
        try! context.save()

        XCTAssertNil(session.relatedHabit)
    }

    // MARK: - Date Query

    func testFetchSessionsByDate() {
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        let todaySession = FocusSession(startTime: today.addingTimeInterval(3600), duration: 1500, presetName: "Pomodoro")
        let yesterdaySession = FocusSession(startTime: yesterday.addingTimeInterval(7200), duration: 600, presetName: "Quick")
        context.insert(todaySession)
        context.insert(yesterdaySession)
        try! context.save()

        let descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate { session in
                session.date >= yesterday
            }
        )
        let results = try! context.fetch(descriptor)
        XCTAssertEqual(results.count, 2)
    }

    // MARK: - Duration

    func testSessionDurationIsAccurate() {
        let start = Date()
        let duration: TimeInterval = 1500
        let session = FocusSession(startTime: start, duration: duration, presetName: "Pomodoro")
        context.insert(session)
        try! context.save()

        let elapsed = session.endTime.timeIntervalSince(session.startTime)
        XCTAssertEqual(elapsed, duration, accuracy: 0.001)
    }

    func testTotalDurationAcrossSessions() {
        let now = Date()
        let durations: [TimeInterval] = [1500, 600, 2700]
        for d in durations {
            let session = FocusSession(startTime: now, duration: d, presetName: "Test")
            context.insert(session)
        }
        try! context.save()

        let descriptor = FetchDescriptor<FocusSession>()
        let all = try! context.fetch(descriptor)
        let total = all.reduce(0) { $0 + $1.duration }
        XCTAssertEqual(total, 4800)
    }

    // MARK: - Preset Names

    func testSessionPresetNames() {
        let presets: [(String, TimeInterval)] = [
            ("Pomodoro", 1500),
            ("Quick", 600),
            ("Deep Work", 2700),
        ]
        for (name, duration) in presets {
            let session = FocusSession(startTime: Date(), duration: duration, presetName: name)
            context.insert(session)
        }
        try! context.save()

        let descriptor = FetchDescriptor<FocusSession>()
        let all = try! context.fetch(descriptor)
        XCTAssertEqual(Set(all.map(\.presetName)), Set(["Pomodoro", "Quick", "Deep Work"]))
    }
}

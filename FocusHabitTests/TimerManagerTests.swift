import XCTest
@testable import FocusHabit

@MainActor
final class TimerManagerTests: XCTestCase {
    var sut: TimerManager!

    override func setUp() {
        super.setUp()
        sut = TimerManager()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialStateIsIdle() {
        XCTAssertEqual(sut.state, .idle)
        XCTAssertEqual(sut.timeRemaining, 1500)
        XCTAssertEqual(sut.totalTime, 1500)
        XCTAssertEqual(sut.currentPreset.name, "Pomodoro")
    }

    // MARK: - State Transitions

    func testStartTransitionsToRunning() {
        sut.start()
        XCTAssertEqual(sut.state, .running)
    }

    func testPauseTransitionsToPaused() {
        sut.start()
        sut.pause()
        XCTAssertEqual(sut.state, .paused)
    }

    func testResetReturnsToIdle() {
        sut.start()
        sut.reset()
        XCTAssertEqual(sut.state, .idle)
        // Reset should restore focus duration
        XCTAssertEqual(sut.timeRemaining, sut.currentPreset.focusDuration)
    }

    func testCannotStartWhenAlreadyRunning() {
        sut.start()
        sut.start()  // second start should be no-op
        XCTAssertEqual(sut.state, .running)
    }

    func testCannotPauseWhenIdle() {
        sut.pause()
        XCTAssertEqual(sut.state, .idle)
    }

    func testResetAfterPauseWorks() {
        sut.start()
        sut.pause()
        sut.reset()
        XCTAssertEqual(sut.state, .idle)
    }

    // MARK: - Preset Selection

    func testSelectPresetUpdatesDuration() {
        sut.selectPreset(.short)
        XCTAssertEqual(sut.currentPreset.name, "Quick")
        XCTAssertEqual(sut.timeRemaining, 600)
        XCTAssertEqual(sut.totalTime, 600)
    }

    func testCannotSelectPresetWhileRunning() {
        sut.start()
        sut.selectPreset(.deep)
        // Should still be pomodoro since we can't change while running
        XCTAssertEqual(sut.currentPreset.name, "Pomodoro")
    }

    func testCannotSelectPresetWhilePaused() {
        sut.start()
        sut.pause()
        sut.selectPreset(.deep)
        // Still pomodoro — paused counts as not idle
        XCTAssertEqual(sut.currentPreset.name, "Pomodoro")
    }

    // MARK: - Timer Countdown

    func testTimeDecreasesAfterStart() async {
        sut.start()
        let before = sut.timeRemaining
        // Wait for a tick (timer fires every 0.5s)
        try? await Task.sleep(nanoseconds: 800_000_000)  // 0.8s
        let after = sut.timeRemaining
        XCTAssertLessThan(after, before)
    }

    func testTimeStaysSameWhenPaused() async {
        sut.start()
        try? await Task.sleep(nanoseconds: 500_000_000)
        sut.pause()
        let pausedTime = sut.timeRemaining
        try? await Task.sleep(nanoseconds: 500_000_000)
        // Time should not decrease while paused
        XCTAssertEqual(sut.timeRemaining, pausedTime)
    }

    func testProgressUpdates() {
        XCTAssertEqual(sut.progress, 0, accuracy: 0.001)
    }

    // MARK: - Skip Break & Next Focus

    func testSkipBreakReturnsToIdle() {
        sut.start()
        sut.skipBreak()
        XCTAssertEqual(sut.state, .idle)
        XCTAssertEqual(sut.timeRemaining, sut.currentPreset.focusDuration)
    }

    func testStartNextFocusRestartsTimer() {
        sut.start()
        sut.startNextFocus()
        XCTAssertEqual(sut.state, .running)
        XCTAssertEqual(sut.timeRemaining, sut.currentPreset.focusDuration)
    }

    // MARK: - Background Handling

    func testAppBackgroundPausesTimer() {
        sut.start()
        sut.handleAppBackground()
        XCTAssertEqual(sut.state, .paused)
    }

    func testAppBackgroundDoesNothingWhenIdle() {
        sut.handleAppBackground()
        XCTAssertEqual(sut.state, .idle)
    }

    // MARK: - Formatting

    func testFormattedTimeFormat() {
        sut.timeRemaining = 3661  // 1h 1m 1s
        // Only mm:ss is shown
        XCTAssertEqual(sut.formattedTime, "61:01")
    }

    func testFormattedTimeZero() {
        sut.timeRemaining = 0
        XCTAssertEqual(sut.formattedTime, "00:00")
    }
}

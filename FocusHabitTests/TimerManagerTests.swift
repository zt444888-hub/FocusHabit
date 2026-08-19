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

    func testTimeDecreasesAfterStart() {
        sut.start()
        let before = sut.timeRemaining
        // XCTest 默认不驱动主 RunLoop，用 wait(for:) 跑 runloop 让 1s 定时器触发
        let tick = expectation(description: "timer tick")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            tick.fulfill()
        }
        wait(for: [tick], timeout: 3)
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

    func testAppBackgroundKeepsRunningForForegroundCorrection() {
        sut.start()
        sut.handleAppBackground()
        // 后台语义：状态保持 .running（后台继续走时），前台用 backgroundTime 校正剩余时间
        XCTAssertEqual(sut.state, .running)
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

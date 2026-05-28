import Testing
@testable import FocusGlassCore

@Suite
struct FocusTimerEngineTests {
    @Test
    func testPomodoroCountsDownAndCompletesFirstSegment() {
        let engine = FocusTimerEngine(preset: .pomodoro)

        engine.start()
        let event = engine.tick(by: 25 * 60)

        #expect(event == .segmentCompleted(TimerPreset.pomodoro.segments[0]))
        #expect(engine.snapshot.activeSegment.phase == .shortBreak)
        #expect(engine.snapshot.remaining == 5 * 60)
        #expect(engine.snapshot.honestFocusTime == 25 * 60)
    }

    @Test
    func testStopwatchCountsUpWithoutCompleting() {
        let engine = FocusTimerEngine(preset: .stopwatch)

        engine.start()
        let event = engine.tick(by: 90)

        #expect(event == .none)
        #expect(engine.snapshot.status == .running)
        #expect(engine.snapshot.elapsed == 90)
        #expect(engine.snapshot.remaining == 0)
    }

    @Test
    func testCountdownCompletesSingleFocusBlock() {
        let engine = FocusTimerEngine(preset: .countdown30)

        engine.start()
        let event = engine.tick(by: 30 * 60)

        #expect(event == .presetCompleted)
        #expect(engine.snapshot.status == .completed)
        #expect(engine.snapshot.remaining == 0)
        #expect(engine.snapshot.honestFocusTime == 30 * 60)
    }

    @Test
    func testDefaultPresetsExposeAllPlannedModes() {
        let modes = Set(TimerPreset.defaultPresets.map(\.mode))

        #expect(modes == Set(TimerMode.allCases))
    }

    @Test
    func testPausePreventsTickProgress() {
        let engine = FocusTimerEngine(preset: .timebox45)

        engine.start()
        engine.tick(by: 60)
        engine.pause()
        engine.tick(by: 60)

        #expect(engine.snapshot.elapsed == 60)
        #expect(engine.snapshot.remaining == 44 * 60)
        #expect(engine.snapshot.status == .paused)
    }

    @Test
    func testAnalyticsFocusScorePenalizesDistractions() {
        let score = AnalyticsEngine.focusScore(
            honestFocusSeconds: 45 * 60,
            plannedSeconds: 60 * 60,
            distractionCount: 3
        )

        #expect(score == 54)
    }

    @Test
    func testEmptyAnalyticsStartsAtZero() {
        let summary = AnalyticsEngine.summarize([])

        #expect(summary.honestFocusSeconds == 0)
        #expect(summary.plannedSeconds == 0)
        #expect(summary.sessionsCompleted == 0)
        #expect(summary.distractionCount == 0)
        #expect(summary.focusScore == 0)
    }
}

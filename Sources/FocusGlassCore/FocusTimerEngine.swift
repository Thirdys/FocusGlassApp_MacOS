import Foundation

public enum TimerEngineEvent: Equatable, Sendable {
    case none
    case segmentCompleted(TimerSegment)
    case presetCompleted
}

public struct TimerEngineSnapshot: Equatable, Sendable {
    public var preset: TimerPreset
    public var status: TimerStatus
    public var activeSegmentIndex: Int
    public var elapsed: TimeInterval
    public var remaining: TimeInterval
    public var honestFocusTime: TimeInterval
    public var completedFocusTime: TimeInterval

    public var activeSegment: TimerSegment {
        preset.segments[min(activeSegmentIndex, max(0, preset.segments.count - 1))]
    }

    public var progress: Double {
        if preset.mode == .stopwatch {
            return min(1, elapsed / max(1, 90 * 60))
        }

        let duration = max(1, activeSegment.duration)
        return min(1, max(0, (duration - remaining) / duration))
    }
}

public final class FocusTimerEngine {
    public private(set) var preset: TimerPreset
    public private(set) var status: TimerStatus = .idle
    public private(set) var activeSegmentIndex = 0
    public private(set) var elapsed: TimeInterval = 0
    public private(set) var remaining: TimeInterval
    public private(set) var honestFocusTime: TimeInterval = 0
    public private(set) var completedFocusTime: TimeInterval = 0

    public init(preset: TimerPreset = .pomodoro) {
        self.preset = preset
        self.remaining = preset.mode == .stopwatch ? 0 : preset.segments.first?.duration ?? 0
    }

    public var snapshot: TimerEngineSnapshot {
        TimerEngineSnapshot(
            preset: preset,
            status: status,
            activeSegmentIndex: activeSegmentIndex,
            elapsed: elapsed,
            remaining: remaining,
            honestFocusTime: honestFocusTime,
            completedFocusTime: completedFocusTime
        )
    }

    public var activeSegment: TimerSegment {
        snapshot.activeSegment
    }

    public func configure(_ preset: TimerPreset) {
        self.preset = preset
        reset()
    }

    public func start() {
        guard status != .running else { return }
        if status == .completed {
            reset()
        }
        status = .running
    }

    public func pause() {
        guard status == .running else { return }
        status = .paused
    }

    public func resume() {
        guard status == .paused else { return }
        status = .running
    }

    public func reset() {
        status = .idle
        activeSegmentIndex = 0
        elapsed = 0
        honestFocusTime = 0
        completedFocusTime = 0
        remaining = preset.mode == .stopwatch ? 0 : preset.segments.first?.duration ?? 0
    }

    @discardableResult
    public func skipSegment() -> TimerEngineEvent {
        guard preset.mode != .stopwatch else {
            status = .completed
            return .presetCompleted
        }

        let completed = activeSegment
        completedFocusTime += completed.phase == .focus ? max(0, completed.duration - remaining) : 0

        if activeSegmentIndex + 1 < preset.segments.count {
            activeSegmentIndex += 1
            remaining = preset.segments[activeSegmentIndex].duration
            return .segmentCompleted(completed)
        }

        status = .completed
        remaining = 0
        return .presetCompleted
    }

    @discardableResult
    public func tick(by seconds: TimeInterval = 1) -> TimerEngineEvent {
        guard status == .running else { return .none }
        let step = max(0, seconds)
        guard step > 0 else { return .none }

        elapsed += step

        if activeSegment.phase == .focus {
            honestFocusTime += step
        }

        if preset.mode == .stopwatch {
            return .none
        }

        remaining -= step
        if remaining > 0 {
            return .none
        }

        let overflow = abs(min(0, remaining))
        let completed = activeSegment
        completedFocusTime += completed.phase == .focus ? completed.duration : 0

        if activeSegmentIndex + 1 < preset.segments.count {
            activeSegmentIndex += 1
            remaining = max(0, preset.segments[activeSegmentIndex].duration - overflow)
            return .segmentCompleted(completed)
        }

        status = .completed
        remaining = 0
        return .presetCompleted
    }
}

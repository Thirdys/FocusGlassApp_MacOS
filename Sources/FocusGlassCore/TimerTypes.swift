import Foundation

public enum TimerMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case pomodoro
    case countdown
    case stopwatch
    case flow
    case timebox
    case intervals

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .pomodoro: "Pomodoro"
        case .countdown: "Countdown"
        case .stopwatch: "Stopwatch"
        case .flow: "Flow"
        case .timebox: "Timebox"
        case .intervals: "Intervals"
        }
    }

    public var symbolName: String {
        switch self {
        case .pomodoro: "timer"
        case .countdown: "hourglass"
        case .stopwatch: "stopwatch"
        case .flow: "waveform.path.ecg"
        case .timebox: "calendar.badge.clock"
        case .intervals: "repeat"
        }
    }
}

public enum TimerPhase: String, Codable, Sendable {
    case idle
    case warmUp
    case focus
    case shortBreak
    case longBreak
    case coolDown
    case review

    public var displayName: String {
        switch self {
        case .idle: "Idle"
        case .warmUp: "Warm-up"
        case .focus: "Focus"
        case .shortBreak: "Short break"
        case .longBreak: "Long break"
        case .coolDown: "Cool-down"
        case .review: "Review"
        }
    }
}

public enum TimerStatus: String, Codable, Sendable {
    case idle
    case running
    case paused
    case completed
}

public struct TimerSegment: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var duration: TimeInterval
    public var phase: TimerPhase
    public var autoStartNext: Bool

    public init(
        id: UUID = UUID(),
        title: String,
        duration: TimeInterval,
        phase: TimerPhase,
        autoStartNext: Bool = true
    ) {
        self.id = id
        self.title = title
        self.duration = duration
        self.phase = phase
        self.autoStartNext = autoStartNext
    }
}

public struct TimerPreset: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var mode: TimerMode
    public var segments: [TimerSegment]
    public var accentName: String

    public init(
        id: UUID = UUID(),
        name: String,
        mode: TimerMode,
        segments: [TimerSegment],
        accentName: String = "aurora"
    ) {
        self.id = id
        self.name = name
        self.mode = mode
        self.segments = segments
        self.accentName = accentName
    }

    public var totalDuration: TimeInterval {
        segments.reduce(0) { $0 + $1.duration }
    }
}

public extension TimerPreset {
    static let pomodoroID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1")!
    static let countdown30ID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2")!
    static let stopwatchID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3")!
    static let deepWorkID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa4")!
    static let timebox45ID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa5")!
    static let intervalsID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa6")!

    static let pomodoro = TimerPreset(
        id: pomodoroID,
        name: "Pomodoro 25/5",
        mode: .pomodoro,
        segments: [
            TimerSegment(title: "Focus", duration: 25 * 60, phase: .focus),
            TimerSegment(title: "Short break", duration: 5 * 60, phase: .shortBreak)
        ],
        accentName: "aurora"
    )

    static let deepWork = TimerPreset(
        id: deepWorkID,
        name: "Deep Work 90",
        mode: .flow,
        segments: [
            TimerSegment(title: "Warm-up", duration: 5 * 60, phase: .warmUp),
            TimerSegment(title: "Deep focus", duration: 80 * 60, phase: .focus),
            TimerSegment(title: "Cool-down", duration: 5 * 60, phase: .coolDown)
        ],
        accentName: "graphite"
    )

    static let countdown30 = TimerPreset(
        id: countdown30ID,
        name: "Countdown 30",
        mode: .countdown,
        segments: [
            TimerSegment(title: "Focus", duration: 30 * 60, phase: .focus)
        ],
        accentName: "aurora"
    )

    static let stopwatch = TimerPreset(
        id: stopwatchID,
        name: "Stopwatch",
        mode: .stopwatch,
        segments: [
            TimerSegment(title: "Open focus", duration: 0, phase: .focus)
        ],
        accentName: "solar"
    )

    static let timebox45 = TimerPreset(
        id: timebox45ID,
        name: "Timebox 45",
        mode: .timebox,
        segments: [
            TimerSegment(title: "Planned focus", duration: 45 * 60, phase: .focus)
        ],
        accentName: "forest"
    )

    static let intervals = TimerPreset(
        id: intervalsID,
        name: "Intervals 50/10",
        mode: .intervals,
        segments: [
            TimerSegment(title: "Focus 1", duration: 50 * 60, phase: .focus),
            TimerSegment(title: "Break 1", duration: 10 * 60, phase: .shortBreak),
            TimerSegment(title: "Focus 2", duration: 50 * 60, phase: .focus),
            TimerSegment(title: "Review", duration: 5 * 60, phase: .review)
        ],
        accentName: "midnight"
    )

    static let defaultPresets: [TimerPreset] = [
        .pomodoro,
        .countdown30,
        .stopwatch,
        .deepWork,
        .timebox45,
        .intervals,
    ]

    static func defaultPreset(matching preset: TimerPreset) -> TimerPreset? {
        defaultPresets.first { $0.id == preset.id } ?? defaultPresets.first { $0.mode == preset.mode }
    }
}

public extension TimeInterval {
    var focusClock: String {
        let safeValue = max(0, Int(self.rounded()))
        let hours = safeValue / 3600
        let minutes = (safeValue % 3600) / 60
        let seconds = safeValue % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }
}

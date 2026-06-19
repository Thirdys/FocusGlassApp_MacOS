import Foundation

public struct FocusSessionRecord: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var projectID: UUID?
    public var projectName: String
    public var taskID: UUID?
    public var taskTitle: String?
    public var mode: TimerMode
    public var startedAt: Date
    public var endedAt: Date
    public var plannedSeconds: TimeInterval
    public var honestFocusSeconds: TimeInterval
    public var distractionCount: Int

    public init(
        id: UUID = UUID(),
        projectID: UUID? = nil,
        projectName: String,
        taskID: UUID? = nil,
        taskTitle: String? = nil,
        mode: TimerMode,
        startedAt: Date,
        endedAt: Date,
        plannedSeconds: TimeInterval,
        honestFocusSeconds: TimeInterval,
        distractionCount: Int
    ) {
        self.id = id
        self.projectID = projectID
        self.projectName = projectName
        self.taskID = taskID
        self.taskTitle = taskTitle
        self.mode = mode
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.plannedSeconds = plannedSeconds
        self.honestFocusSeconds = honestFocusSeconds
        self.distractionCount = distractionCount
    }
}

public struct DailyFocusSummary: Equatable, Sendable {
    public var honestFocusSeconds: TimeInterval
    public var plannedSeconds: TimeInterval
    public var sessionsCompleted: Int
    public var distractionCount: Int
    public var focusScore: Int
}

public enum AnalyticsEngine {
    public static func summarize(_ records: [FocusSessionRecord]) -> DailyFocusSummary {
        let planned = records.reduce(0) { $0 + $1.plannedSeconds }
        let honest = records.reduce(0) { $0 + $1.honestFocusSeconds }
        let distractions = records.reduce(0) { $0 + $1.distractionCount }

        return DailyFocusSummary(
            honestFocusSeconds: honest,
            plannedSeconds: planned,
            sessionsCompleted: records.count,
            distractionCount: distractions,
            focusScore: focusScore(
                honestFocusSeconds: honest,
                plannedSeconds: planned,
                distractionCount: distractions
            )
        )
    }

    public static func focusScore(
        honestFocusSeconds: TimeInterval,
        plannedSeconds: TimeInterval,
        distractionCount: Int
    ) -> Int {
        guard plannedSeconds > 0 else { return 0 }

        let completionRatio = min(1, max(0, honestFocusSeconds / plannedSeconds))
        let distractionPenalty = min(35, distractionCount * 7)
        let score = Int((completionRatio * 100).rounded()) - distractionPenalty

        return min(100, max(0, score))
    }
}

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

public struct ModeEffectivenessSummary: Identifiable, Equatable, Sendable {
    public var mode: TimerMode
    public var sessionsCompleted: Int
    public var plannedSeconds: TimeInterval
    public var honestFocusSeconds: TimeInterval
    public var distractionCount: Int

    public var id: TimerMode { mode }
    public var effectiveness: Double {
        guard plannedSeconds > 0 else { return 0 }
        return min(1, max(0, honestFocusSeconds / plannedSeconds))
    }
}

public struct ProjectFocusSummary: Identifiable, Equatable, Sendable {
    public var projectID: UUID?
    public var projectName: String
    public var sessionsCompleted: Int
    public var plannedSeconds: TimeInterval
    public var honestFocusSeconds: TimeInterval
    public var distractionCount: Int

    public var id: String { projectID?.uuidString ?? "unassigned" }
    public var effectiveness: Double {
        guard plannedSeconds > 0 else { return 0 }
        return min(1, max(0, honestFocusSeconds / plannedSeconds))
    }
}

public struct TaskFocusSummary: Identifiable, Equatable, Sendable {
    public var taskID: UUID
    public var taskTitle: String
    public var projectID: UUID?
    public var projectName: String
    public var sessionsCompleted: Int
    public var plannedSeconds: TimeInterval
    public var honestFocusSeconds: TimeInterval
    public var distractionCount: Int
    public var lastFocusedAt: Date

    public var id: UUID { taskID }
    public var effectiveness: Double {
        guard plannedSeconds > 0 else { return 0 }
        return min(1, max(0, honestFocusSeconds / plannedSeconds))
    }
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

    public static func summarizeByMode(_ records: [FocusSessionRecord]) -> [ModeEffectivenessSummary] {
        Dictionary(grouping: records, by: \.mode)
            .map { mode, groupedRecords in
                ModeEffectivenessSummary(
                    mode: mode,
                    sessionsCompleted: groupedRecords.count,
                    plannedSeconds: groupedRecords.reduce(0) { $0 + $1.plannedSeconds },
                    honestFocusSeconds: groupedRecords.reduce(0) { $0 + $1.honestFocusSeconds },
                    distractionCount: groupedRecords.reduce(0) { $0 + $1.distractionCount }
                )
            }
            .sorted {
                if $0.honestFocusSeconds == $1.honestFocusSeconds {
                    return $0.mode.rawValue < $1.mode.rawValue
                }
                return $0.honestFocusSeconds > $1.honestFocusSeconds
            }
    }

    public static func summarizeByProject(_ records: [FocusSessionRecord]) -> [ProjectFocusSummary] {
        Dictionary(grouping: records) { $0.projectID?.uuidString ?? "unassigned" }
            .map { _, groupedRecords in
                let first = groupedRecords[0]
                return ProjectFocusSummary(
                    projectID: first.projectID,
                    projectName: first.projectName,
                    sessionsCompleted: groupedRecords.count,
                    plannedSeconds: groupedRecords.reduce(0) { $0 + $1.plannedSeconds },
                    honestFocusSeconds: groupedRecords.reduce(0) { $0 + $1.honestFocusSeconds },
                    distractionCount: groupedRecords.reduce(0) { $0 + $1.distractionCount }
                )
            }
            .sorted {
                if $0.honestFocusSeconds == $1.honestFocusSeconds {
                    return $0.projectName.localizedCaseInsensitiveCompare($1.projectName) == .orderedAscending
                }
                return $0.honestFocusSeconds > $1.honestFocusSeconds
            }
    }

    public static func summarizeByTask(_ records: [FocusSessionRecord]) -> [TaskFocusSummary] {
        let linkedRecords = records.compactMap { record -> (taskID: UUID, record: FocusSessionRecord)? in
            guard let taskID = record.taskID else { return nil }
            return (taskID, record)
        }

        return Dictionary(grouping: linkedRecords, by: \.taskID)
            .compactMap { taskID, entries in
                let groupedRecords = entries.map(\.record)
                guard let latestRecord = groupedRecords.max(by: {
                    if $0.endedAt == $1.endedAt {
                        return $0.startedAt < $1.startedAt
                    }
                    return $0.endedAt < $1.endedAt
                }) else {
                    return nil
                }

                return TaskFocusSummary(
                    taskID: taskID,
                    taskTitle: latestRecord.taskTitle ?? "",
                    projectID: latestRecord.projectID,
                    projectName: latestRecord.projectName,
                    sessionsCompleted: groupedRecords.count,
                    plannedSeconds: groupedRecords.reduce(0) { $0 + $1.plannedSeconds },
                    honestFocusSeconds: groupedRecords.reduce(0) { $0 + $1.honestFocusSeconds },
                    distractionCount: groupedRecords.reduce(0) { $0 + $1.distractionCount },
                    lastFocusedAt: latestRecord.endedAt
                )
            }
            .sorted {
                if $0.honestFocusSeconds == $1.honestFocusSeconds {
                    return $0.taskTitle.localizedCaseInsensitiveCompare($1.taskTitle) == .orderedAscending
                }
                return $0.honestFocusSeconds > $1.honestFocusSeconds
            }
    }
}

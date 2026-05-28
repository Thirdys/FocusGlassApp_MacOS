import Foundation

struct FGProject: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var detail: String
    var accentName: String
    var createdAt: Date
    var isArchived: Bool

    init(
        id: UUID = UUID(),
        name: String,
        detail: String = "",
        accentName: String = "aurora",
        createdAt: Date = .now,
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.detail = detail
        self.accentName = accentName
        self.createdAt = createdAt
        self.isArchived = isArchived
    }
}

struct FGFocusTask: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var projectID: UUID?
    var estimatedSeconds: Double
    var completedSeconds: Double
    var isDone: Bool
    var createdAt: Date
    var completedAt: Date?
}

struct FGFocusSession: Identifiable, Codable, Equatable {
    var id: UUID
    var projectID: UUID?
    var taskID: UUID?
    var modeRawValue: String
    var startedAt: Date
    var endedAt: Date?
    var plannedSeconds: Double
    var honestFocusSeconds: Double
    var distractionCount: Int
    var intention: String
}

struct FGTimerPresetEntity: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var modeRawValue: String
    var encodedSegments: Data
    var accentName: String
    var isBuiltIn: Bool
}

struct FGThemePresetEntity: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var modeRawValue: String
    var isBuiltIn: Bool
}

struct FGDistractionRule: Identifiable, Codable, Equatable {
    var id: UUID
    var label: String
    var bundleIdentifier: String
    var actionRawValue: String
    var isEnabled: Bool
}

struct FGFocusEvent: Identifiable, Codable, Equatable {
    var id: UUID
    var sessionID: UUID?
    var createdAt: Date
    var kind: String
    var message: String
}

struct FGDailyInsight: Identifiable, Codable, Equatable {
    var id: UUID
    var day: Date
    var honestFocusSeconds: Double
    var plannedSeconds: Double
    var focusScore: Int
    var streak: Int
    var note: String
}

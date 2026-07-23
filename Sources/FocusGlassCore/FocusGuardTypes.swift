import Foundation

public enum FocusPermission: String, CaseIterable, Codable, Identifiable, Sendable {
    case notifications
    case accessibility
    case automation
    case launchAtLogin

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .notifications: "Notifications"
        case .accessibility: "Accessibility"
        case .automation: "Automation"
        case .launchAtLogin: "Launch at Login"
        }
    }
}

public enum FocusPermissionStatus: String, Codable, Equatable, Sendable {
    case unknown
    case granted
    case missing
    case unavailable

    public var isGranted: Bool {
        self == .granted
    }

    public var needsUserAction: Bool {
        self == .missing || self == .unavailable
    }
}

public enum DistractionTargetKind: String, CaseIterable, Codable, Identifiable, Sendable {
    case app
    case site

    public var id: String { rawValue }
}

public enum DistractionAction: String, CaseIterable, Codable, Identifiable, Sendable {
    case warn
    case hide
    case pauseSession
    case quitAfterOptIn

    public var id: String { rawValue }
}

public struct DistractionRuleSpec: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var targetKind: DistractionTargetKind
    public var label: String
    public var matchValue: String
    public var bundleIdentifier: String?
    public var sitePattern: String?
    public var action: DistractionAction
    public var isEnabled: Bool
    public var allowsQuitAfterOptIn: Bool

    public init(
        id: UUID = UUID(),
        label: String,
        targetKind: DistractionTargetKind = .app,
        matchValue: String? = nil,
        bundleIdentifier: String? = nil,
        sitePattern: String? = nil,
        action: DistractionAction = .warn,
        isEnabled: Bool = true,
        allowsQuitAfterOptIn: Bool = false
    ) {
        self.id = id
        self.targetKind = targetKind
        self.label = label
        self.matchValue = matchValue ?? bundleIdentifier ?? sitePattern ?? label
        self.bundleIdentifier = bundleIdentifier
        self.sitePattern = sitePattern
        self.action = action
        self.isEnabled = isEnabled
        self.allowsQuitAfterOptIn = allowsQuitAfterOptIn
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case targetKind
        case label
        case matchValue
        case bundleIdentifier
        case sitePattern
        case action
        case isEnabled
        case allowsQuitAfterOptIn
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        targetKind = try container.decodeIfPresent(DistractionTargetKind.self, forKey: .targetKind) ?? .app
        label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
        let legacyBundleIdentifier = try container.decodeIfPresent(String.self, forKey: .bundleIdentifier)
        let decodedSitePattern = try container.decodeIfPresent(String.self, forKey: .sitePattern)
        matchValue = try container.decodeIfPresent(String.self, forKey: .matchValue)
            ?? legacyBundleIdentifier
            ?? decodedSitePattern
            ?? label
        bundleIdentifier = legacyBundleIdentifier ?? (targetKind == .app ? matchValue : nil)
        sitePattern = decodedSitePattern ?? (targetKind == .site ? matchValue : nil)
        action = try container.decodeIfPresent(DistractionAction.self, forKey: .action) ?? .warn
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        allowsQuitAfterOptIn = try container.decodeIfPresent(Bool.self, forKey: .allowsQuitAfterOptIn) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(targetKind, forKey: .targetKind)
        try container.encode(label, forKey: .label)
        try container.encode(matchValue, forKey: .matchValue)
        try container.encodeIfPresent(bundleIdentifier, forKey: .bundleIdentifier)
        try container.encodeIfPresent(sitePattern, forKey: .sitePattern)
        try container.encode(action, forKey: .action)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(allowsQuitAfterOptIn, forKey: .allowsQuitAfterOptIn)
    }

    public var effectiveAction: DistractionAction {
        action == .quitAfterOptIn && !allowsQuitAfterOptIn ? .hide : action
    }

    public var normalizedSitePattern: String? {
        guard targetKind == .site else { return nil }
        let source = (sitePattern?.isEmpty == false ? sitePattern : matchValue) ?? matchValue
        return Self.normalizedSitePattern(source)
    }

    public func matches(bundleIdentifier candidate: String?) -> Bool {
        guard isEnabled, targetKind == .app, let candidate else { return false }
        return candidate == bundleIdentifier || candidate == matchValue
    }

    public func matches(siteURL urlString: String?) -> Bool {
        guard isEnabled, targetKind == .site,
              let pattern = normalizedSitePattern,
              let host = Self.host(from: urlString) else { return false }

        if pattern.hasPrefix("*.") {
            let suffix = String(pattern.dropFirst(2))
            return host == suffix || host.hasSuffix(".\(suffix)")
        }

        return host == pattern || host.hasSuffix(".\(pattern)")
    }

    public static func normalizedSitePattern(_ value: String) -> String? {
        let trimmed = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "www.", with: "")
        let host = trimmed.split(separator: "/").first.map(String.init) ?? trimmed
        let cleaned = host.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        return cleaned.isEmpty ? nil : cleaned
    }

    private static func host(from urlString: String?) -> String? {
        guard let urlString, !urlString.isEmpty else { return nil }
        let candidate = urlString.contains("://") ? urlString : "https://\(urlString)"
        guard let host = URL(string: candidate)?.host(percentEncoded: false) else {
            return normalizedSitePattern(urlString)
        }
        let normalizedHost = host.lowercased()
        return normalizedHost.hasPrefix("www.") ? String(normalizedHost.dropFirst(4)) : normalizedHost
    }
}

public struct DistractionEventRecord: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var occurredAt: Date
    public var ruleID: UUID
    public var targetKind: DistractionTargetKind
    public var targetLabel: String
    public var matchValue: String
    public var action: DistractionAction
    public var sessionID: UUID?
    public var projectID: UUID?
    public var projectName: String
    public var taskID: UUID?
    public var taskTitle: String?
    public var mode: TimerMode

    public init(
        id: UUID = UUID(),
        occurredAt: Date = .now,
        ruleID: UUID,
        targetKind: DistractionTargetKind,
        targetLabel: String,
        matchValue: String,
        action: DistractionAction,
        sessionID: UUID? = nil,
        projectID: UUID? = nil,
        projectName: String = "",
        taskID: UUID? = nil,
        taskTitle: String? = nil,
        mode: TimerMode
    ) {
        self.id = id
        self.occurredAt = occurredAt
        self.ruleID = ruleID
        self.targetKind = targetKind
        self.targetLabel = targetLabel
        self.matchValue = matchValue
        self.action = action
        self.sessionID = sessionID
        self.projectID = projectID
        self.projectName = projectName
        self.taskID = taskID
        self.taskTitle = taskTitle
        self.mode = mode
    }
}

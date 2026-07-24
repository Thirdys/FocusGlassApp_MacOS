import AppKit
import Foundation
import FocusGlassCore

struct FocusGlassPersistedState: Codable {
    var schemaVersion: Int?
    var selectedThemeID: UUID
    var themeProfiles: [ThemeProfile]
    var selectedPresetID: UUID
    var timerPresets: [TimerPreset]
    var language: AppLanguage
    var appearanceMode: AppAppearanceMode
    var strictModeEnabled: Bool
    var strictModeEnforcesDuringBreaks: Bool
    var hasSeenPermissionsOnboarding: Bool
    var intention: String
    var activeProjectID: UUID?
    var activeTaskID: UUID?
    var activeProject: String
    var projects: [FocusProject]
    var tasks: [FocusTask]
    var distractionRules: [DistractionRuleSpec]
    var distractionHistory: [DistractionEventRecord]
    var recentSessions: [FocusSessionRecord]

    init(
        schemaVersion: Int?,
        selectedThemeID: UUID,
        themeProfiles: [ThemeProfile],
        selectedPresetID: UUID = TimerPreset.pomodoro.id,
        timerPresets: [TimerPreset] = TimerPreset.defaultPresets,
        language: AppLanguage,
        appearanceMode: AppAppearanceMode = .system,
        strictModeEnabled: Bool,
        strictModeEnforcesDuringBreaks: Bool = false,
        hasSeenPermissionsOnboarding: Bool = false,
        intention: String,
        activeProjectID: UUID? = nil,
        activeTaskID: UUID? = nil,
        activeProject: String,
        projects: [FocusProject],
        tasks: [FocusTask],
        distractionRules: [DistractionRuleSpec],
        distractionHistory: [DistractionEventRecord] = [],
        recentSessions: [FocusSessionRecord]
    ) {
        self.schemaVersion = schemaVersion
        self.selectedThemeID = selectedThemeID
        self.themeProfiles = themeProfiles
        self.selectedPresetID = selectedPresetID
        self.timerPresets = timerPresets
        self.language = language
        self.appearanceMode = appearanceMode
        self.strictModeEnabled = strictModeEnabled
        self.strictModeEnforcesDuringBreaks = strictModeEnforcesDuringBreaks
        self.hasSeenPermissionsOnboarding = hasSeenPermissionsOnboarding
        self.intention = intention
        self.activeProjectID = activeProjectID
        self.activeTaskID = activeTaskID
        self.activeProject = activeProject
        self.projects = projects
        self.tasks = tasks
        self.distractionRules = distractionRules
        self.distractionHistory = distractionHistory
        self.recentSessions = recentSessions
    }

    init(workspace: FocusGlassWorkspaceState, settings: FocusGlassSettingsState) {
        self.init(
            schemaVersion: max(workspace.schemaVersion ?? 6, settings.schemaVersion ?? 6),
            selectedThemeID: settings.selectedThemeID,
            themeProfiles: settings.themeProfiles,
            selectedPresetID: settings.selectedPresetID,
            timerPresets: settings.timerPresets,
            language: settings.language,
            appearanceMode: settings.appearanceMode,
            strictModeEnabled: settings.strictModeEnabled,
            strictModeEnforcesDuringBreaks: settings.strictModeEnforcesDuringBreaks,
            hasSeenPermissionsOnboarding: settings.hasSeenPermissionsOnboarding,
            intention: workspace.intention,
            activeProjectID: workspace.activeProjectID,
            activeTaskID: workspace.activeTaskID,
            activeProject: workspace.activeProject,
            projects: workspace.projects,
            tasks: workspace.tasks,
            distractionRules: workspace.distractionRules,
            distractionHistory: workspace.distractionHistory,
            recentSessions: workspace.recentSessions
        )
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case selectedThemeID
        case themeProfiles
        case selectedPresetID
        case timerPresets
        case language
        case appearanceMode
        case strictModeEnabled
        case strictModeEnforcesDuringBreaks
        case hasSeenPermissionsOnboarding
        case intention
        case activeProjectID
        case activeTaskID
        case activeProject
        case projects
        case tasks
        case distractionRules
        case distractionHistory
        case recentSessions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion)
        selectedThemeID = try container.decode(UUID.self, forKey: .selectedThemeID)
        themeProfiles = try container.decode([ThemeProfile].self, forKey: .themeProfiles)
        selectedPresetID = try container.decodeIfPresent(UUID.self, forKey: .selectedPresetID) ?? TimerPreset.pomodoro.id
        timerPresets = try container.decodeIfPresent([TimerPreset].self, forKey: .timerPresets) ?? TimerPreset.defaultPresets
        language = try container.decode(AppLanguage.self, forKey: .language)
        appearanceMode = try container.decodeIfPresent(AppAppearanceMode.self, forKey: .appearanceMode) ?? .system
        strictModeEnabled = try container.decode(Bool.self, forKey: .strictModeEnabled)
        strictModeEnforcesDuringBreaks = try container.decodeIfPresent(Bool.self, forKey: .strictModeEnforcesDuringBreaks) ?? false
        hasSeenPermissionsOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasSeenPermissionsOnboarding) ?? false
        intention = try container.decode(String.self, forKey: .intention)
        activeProjectID = try container.decodeIfPresent(UUID.self, forKey: .activeProjectID)
        activeTaskID = try container.decodeIfPresent(UUID.self, forKey: .activeTaskID)
        activeProject = try container.decodeIfPresent(String.self, forKey: .activeProject) ?? ""
        projects = try container.decode([FocusProject].self, forKey: .projects)
        tasks = try container.decode([FocusTask].self, forKey: .tasks)
        distractionRules = try container.decode([DistractionRuleSpec].self, forKey: .distractionRules)
        distractionHistory = try container.decodeIfPresent([DistractionEventRecord].self, forKey: .distractionHistory) ?? []
        recentSessions = try container.decode([FocusSessionRecord].self, forKey: .recentSessions)
    }
}

struct FocusGlassWorkspaceState: Codable, Equatable {
    var schemaVersion: Int?
    var intention: String
    var activeProjectID: UUID?
    var activeTaskID: UUID?
    var activeProject: String
    var projects: [FocusProject]
    var tasks: [FocusTask]
    var distractionRules: [DistractionRuleSpec]
    var distractionHistory: [DistractionEventRecord]
    var recentSessions: [FocusSessionRecord]

    init(
        schemaVersion: Int? = 6,
        intention: String = "",
        activeProjectID: UUID? = nil,
        activeTaskID: UUID? = nil,
        activeProject: String = "",
        projects: [FocusProject] = [],
        tasks: [FocusTask] = [],
        distractionRules: [DistractionRuleSpec] = [],
        distractionHistory: [DistractionEventRecord] = [],
        recentSessions: [FocusSessionRecord] = []
    ) {
        self.schemaVersion = schemaVersion
        self.intention = intention
        self.activeProjectID = activeProjectID
        self.activeTaskID = activeTaskID
        self.activeProject = activeProject
        self.projects = projects
        self.tasks = tasks
        self.distractionRules = distractionRules
        self.distractionHistory = distractionHistory
        self.recentSessions = recentSessions
    }

    init(_ state: FocusGlassPersistedState) {
        self.init(
            schemaVersion: 6,
            intention: state.intention,
            activeProjectID: state.activeProjectID,
            activeTaskID: state.activeTaskID,
            activeProject: state.activeProject,
            projects: state.projects,
            tasks: state.tasks,
            distractionRules: state.distractionRules,
            distractionHistory: state.distractionHistory,
            recentSessions: state.recentSessions
        )
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case intention
        case activeProjectID
        case activeTaskID
        case activeProject
        case projects
        case tasks
        case distractionRules
        case distractionHistory
        case recentSessions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion)
        intention = try container.decodeIfPresent(String.self, forKey: .intention) ?? ""
        activeProjectID = try container.decodeIfPresent(UUID.self, forKey: .activeProjectID)
        activeTaskID = try container.decodeIfPresent(UUID.self, forKey: .activeTaskID)
        activeProject = try container.decodeIfPresent(String.self, forKey: .activeProject) ?? ""
        projects = try container.decodeIfPresent([FocusProject].self, forKey: .projects) ?? []
        tasks = try container.decodeIfPresent([FocusTask].self, forKey: .tasks) ?? []
        distractionRules = try container.decodeIfPresent([DistractionRuleSpec].self, forKey: .distractionRules) ?? []
        distractionHistory = try container.decodeIfPresent([DistractionEventRecord].self, forKey: .distractionHistory) ?? []
        recentSessions = try container.decodeIfPresent([FocusSessionRecord].self, forKey: .recentSessions) ?? []
    }
}

struct FocusGlassSettingsState: Codable, Equatable {
    var schemaVersion: Int?
    var selectedThemeID: UUID
    var themeProfiles: [ThemeProfile]
    var selectedPresetID: UUID
    var timerPresets: [TimerPreset]
    var language: AppLanguage
    var appearanceMode: AppAppearanceMode
    var strictModeEnabled: Bool
    var strictModeEnforcesDuringBreaks: Bool
    var hasSeenPermissionsOnboarding: Bool

    init(
        schemaVersion: Int? = 6,
        selectedThemeID: UUID = ThemeProfile.noirCrimsonID,
        themeProfiles: [ThemeProfile] = ThemeProfile.builtIn,
        selectedPresetID: UUID = TimerPreset.pomodoro.id,
        timerPresets: [TimerPreset] = TimerPreset.defaultPresets,
        language: AppLanguage = .ru,
        appearanceMode: AppAppearanceMode = .system,
        strictModeEnabled: Bool = false,
        strictModeEnforcesDuringBreaks: Bool = false,
        hasSeenPermissionsOnboarding: Bool = false
    ) {
        self.schemaVersion = schemaVersion
        self.selectedThemeID = selectedThemeID
        self.themeProfiles = themeProfiles
        self.selectedPresetID = selectedPresetID
        self.timerPresets = timerPresets
        self.language = language
        self.appearanceMode = appearanceMode
        self.strictModeEnabled = strictModeEnabled
        self.strictModeEnforcesDuringBreaks = strictModeEnforcesDuringBreaks
        self.hasSeenPermissionsOnboarding = hasSeenPermissionsOnboarding
    }

    init(_ state: FocusGlassPersistedState) {
        self.init(
            schemaVersion: 6,
            selectedThemeID: state.selectedThemeID,
            themeProfiles: state.themeProfiles,
            selectedPresetID: state.selectedPresetID,
            timerPresets: state.timerPresets,
            language: state.language,
            appearanceMode: state.appearanceMode,
            strictModeEnabled: state.strictModeEnabled,
            strictModeEnforcesDuringBreaks: state.strictModeEnforcesDuringBreaks,
            hasSeenPermissionsOnboarding: state.hasSeenPermissionsOnboarding
        )
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case selectedThemeID
        case themeProfiles
        case selectedPresetID
        case timerPresets
        case language
        case appearanceMode
        case strictModeEnabled
        case strictModeEnforcesDuringBreaks
        case hasSeenPermissionsOnboarding
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion)
        selectedThemeID = try container.decodeIfPresent(UUID.self, forKey: .selectedThemeID) ?? ThemeProfile.noirCrimsonID
        themeProfiles = try container.decodeIfPresent([ThemeProfile].self, forKey: .themeProfiles) ?? ThemeProfile.builtIn
        selectedPresetID = try container.decodeIfPresent(UUID.self, forKey: .selectedPresetID) ?? TimerPreset.pomodoro.id
        timerPresets = try container.decodeIfPresent([TimerPreset].self, forKey: .timerPresets) ?? TimerPreset.defaultPresets
        language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .ru
        appearanceMode = try container.decodeIfPresent(AppAppearanceMode.self, forKey: .appearanceMode) ?? .system
        strictModeEnabled = try container.decodeIfPresent(Bool.self, forKey: .strictModeEnabled) ?? false
        strictModeEnforcesDuringBreaks = try container.decodeIfPresent(Bool.self, forKey: .strictModeEnforcesDuringBreaks) ?? false
        hasSeenPermissionsOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasSeenPermissionsOnboarding) ?? false
    }
}

struct FocusGlassStoragePaths: Equatable {
    var dataDirectory: URL
    var legacyStateURL: URL
    var workspaceURL: URL
    var settingsURL: URL

    init(
        fileManager: FileManager = .default,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) {
        if let overridePath = Self.dataDirectoryOverride(
            environment: environment,
            arguments: arguments
        ) {
            self.init(dataDirectory: URL(fileURLWithPath: overridePath, isDirectory: true))
            return
        }

        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.init(dataDirectory: baseURL.appendingPathComponent("FocusGlass", isDirectory: true))
    }

    init(legacyStateURL: URL) {
        self.init(dataDirectory: legacyStateURL.deletingLastPathComponent(), legacyStateURL: legacyStateURL)
    }

    private init(dataDirectory: URL, legacyStateURL: URL? = nil) {
        self.dataDirectory = dataDirectory
        self.legacyStateURL = legacyStateURL ?? dataDirectory.appendingPathComponent("state.json")
        self.workspaceURL = dataDirectory.appendingPathComponent("workspace.json")
        self.settingsURL = dataDirectory.appendingPathComponent("settings.json")
    }

    private static func dataDirectoryOverride(
        environment: [String: String],
        arguments: [String]
    ) -> String? {
        if let environmentPath = normalizedOverridePath(environment["FOCUSGLASS_DATA_DIR"]) {
            return environmentPath
        }

        let argumentPrefixes = ["focusglass-data-dir=", "--focusglass-data-dir="]
        for index in arguments.indices {
            let argument = arguments[index]
            if argument == "focusglass-data-dir" || argument == "--focusglass-data-dir" {
                let valueIndex = arguments.index(after: index)
                guard arguments.indices.contains(valueIndex) else { return nil }
                return normalizedOverridePath(arguments[valueIndex])
            }

            for argumentPrefix in argumentPrefixes where argument.hasPrefix(argumentPrefix) {
                return normalizedOverridePath(String(argument.dropFirst(argumentPrefix.count)))
            }
        }

        return nil
    }

    private static func normalizedOverridePath(_ value: String?) -> String? {
        guard let path = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !path.isEmpty else { return nil }
        return path
    }
}

struct FocusGlassStoreStatus: Equatable {
    var savedAt: Date?
    var isError: Bool
    var message: String
}

struct FocusGlassStoreLoadResult {
    var state: FocusGlassPersistedState?
    var warnings: [String]
    var shouldBlockAutomaticSave: Bool
    var migratedFromLegacy: Bool
    var paths: FocusGlassStoragePaths
}

@MainActor
final class FocusGlassStore {
    let paths: FocusGlassStoragePaths
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private(set) var lastSaveStatus: FocusGlassStoreStatus?

    init(fileManager: FileManager = .default) {
        self.paths = FocusGlassStoragePaths(fileManager: fileManager)
        configureCoders()
        ensureDirectory()
    }

    init(fileURL: URL) {
        self.paths = FocusGlassStoragePaths(legacyStateURL: fileURL)
        configureCoders()
        ensureDirectory()
    }

    func load() -> FocusGlassStoreLoadResult {
        ensureDirectory()

        var warnings: [String] = []
        var blockAutomaticSave = false
        let hasWorkspace = FileManager.default.fileExists(atPath: paths.workspaceURL.path)
        let hasSettings = FileManager.default.fileExists(atPath: paths.settingsURL.path)

        if hasWorkspace || hasSettings {
            var workspace = FocusGlassWorkspaceState()
            var settings = FocusGlassSettingsState()

            if hasWorkspace {
                switch decode(FocusGlassWorkspaceState.self, from: paths.workspaceURL) {
                case .success(let loaded):
                    workspace = loaded
                case .failure(let error):
                    let backupURL = backupInvalidFile(at: paths.workspaceURL)
                    blockAutomaticSave = true
                    warnings.append("workspace.json could not be decoded. Backup: \(backupURL?.lastPathComponent ?? "none"). Error: \(error)")
                    logStorageIssue(
                        code: "storage.workspace_decode_failed",
                        message: "workspace.json could not be decoded",
                        details: ["path": paths.workspaceURL.path, "backup": backupURL?.path ?? "", "error": String(describing: error)]
                    )
                }
            }

            if hasSettings {
                switch decode(FocusGlassSettingsState.self, from: paths.settingsURL) {
                case .success(let loaded):
                    settings = loaded
                case .failure(let error):
                    let backupURL = backupInvalidFile(at: paths.settingsURL)
                    warnings.append("settings.json could not be decoded. Backup: \(backupURL?.lastPathComponent ?? "none"). Error: \(error)")
                    logStorageIssue(
                        code: "storage.settings_decode_failed",
                        message: "settings.json could not be decoded",
                        details: ["path": paths.settingsURL.path, "backup": backupURL?.path ?? "", "error": String(describing: error)]
                    )
                }
            }

            return FocusGlassStoreLoadResult(
                state: blockAutomaticSave ? nil : FocusGlassPersistedState(workspace: workspace, settings: settings),
                warnings: warnings,
                shouldBlockAutomaticSave: blockAutomaticSave,
                migratedFromLegacy: false,
                paths: paths
            )
        }

        guard FileManager.default.fileExists(atPath: paths.legacyStateURL.path) else {
            return FocusGlassStoreLoadResult(
                state: nil,
                warnings: [],
                shouldBlockAutomaticSave: false,
                migratedFromLegacy: false,
                paths: paths
            )
        }

        switch decode(FocusGlassPersistedState.self, from: paths.legacyStateURL) {
        case .success(let state):
            return FocusGlassStoreLoadResult(
                state: state,
                warnings: [],
                shouldBlockAutomaticSave: false,
                migratedFromLegacy: true,
                paths: paths
            )
        case .failure(let error):
            let backupURL = backupInvalidFile(at: paths.legacyStateURL)
            let warning = "legacy state.json could not be decoded. Backup: \(backupURL?.lastPathComponent ?? "none"). Error: \(error)"
            logStorageIssue(
                code: "storage.legacy_decode_failed",
                message: "legacy state.json could not be decoded",
                details: ["path": paths.legacyStateURL.path, "backup": backupURL?.path ?? "", "error": String(describing: error)]
            )
            return FocusGlassStoreLoadResult(
                state: nil,
                warnings: [warning],
                shouldBlockAutomaticSave: true,
                migratedFromLegacy: false,
                paths: paths
            )
        }
    }

    func save(_ state: FocusGlassPersistedState) {
        ensureDirectory()
        if write(state, to: paths.legacyStateURL, label: "legacy") {
            lastSaveStatus = FocusGlassStoreStatus(savedAt: .now, isError: false, message: "legacy state.json saved")
        } else {
            lastSaveStatus = FocusGlassStoreStatus(savedAt: .now, isError: true, message: "FocusGlass could not save legacy state.json")
        }
    }

    func save(workspace: FocusGlassWorkspaceState, settings: FocusGlassSettingsState) {
        ensureDirectory()
        let workspaceSaved = write(workspace, to: paths.workspaceURL, label: "workspace")
        let settingsSaved = write(settings, to: paths.settingsURL, label: "settings")

        if workspaceSaved && settingsSaved {
            lastSaveStatus = FocusGlassStoreStatus(savedAt: .now, isError: false, message: "workspace.json and settings.json saved")
        } else {
            lastSaveStatus = FocusGlassStoreStatus(savedAt: .now, isError: true, message: "FocusGlass could not save all data files")
        }
    }

    func openDataDirectory() {
        ensureDirectory()
        NSWorkspace.shared.open(paths.dataDirectory)
    }

    private func configureCoders() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    private func ensureDirectory() {
        try? FileManager.default.createDirectory(at: paths.dataDirectory, withIntermediateDirectories: true)
    }

    private func decode<T: Decodable>(_ type: T.Type, from url: URL) -> Result<T, Error> {
        do {
            let data = try Data(contentsOf: url)
            return .success(try decoder.decode(T.self, from: data))
        } catch {
            return .failure(error)
        }
    }

    private func write<T: Codable>(_ value: T, to url: URL, label: String) -> Bool {
        do {
            let data = try encoder.encode(value)
            try data.write(to: url, options: [.atomic])
            let writtenData = try Data(contentsOf: url)
            _ = try decoder.decode(T.self, from: writtenData)
            return true
        } catch {
            logStorageIssue(
                code: "storage.\(label)_write_failed",
                message: "\(label) could not be saved",
                details: ["path": url.path, "error": String(describing: error)]
            )
            return false
        }
    }

    private func backupInvalidFile(at url: URL) -> URL? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let timestamp = Self.backupTimestampFormatter.string(from: Date())
        let backupURL = url
            .deletingLastPathComponent()
            .appendingPathComponent("\(url.deletingPathExtension().lastPathComponent).invalid-\(timestamp).json")
        do {
            if FileManager.default.fileExists(atPath: backupURL.path) {
                try FileManager.default.removeItem(at: backupURL)
            }
            try FileManager.default.copyItem(at: url, to: backupURL)
            return backupURL
        } catch {
            logStorageIssue(
                code: "storage.invalid_backup_failed",
                message: "Could not create invalid JSON backup",
                details: ["path": url.path, "backup": backupURL.path, "error": String(describing: error)]
            )
            return nil
        }
    }

    private func logStorageIssue(code: String, message: String, details: [String: String]) {
        FocusGlassDiagnosticsLogger.shared.log(
            .error,
            subsystem: "storage",
            code: code,
            message: message,
            details: details,
            resolutionHint: "Check FocusGlass data files in \(paths.dataDirectory.path). Invalid JSON backups are kept next to the source file."
        )
    }

    private static let backupTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()
}

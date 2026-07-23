import AppKit
import Combine
import Foundation
import SwiftUI
import FocusGlassCore

struct RunningApplicationOption: Identifiable, Hashable {
    var id: String { bundleIdentifier }
    var label: String
    var bundleIdentifier: String
}

struct FocusProject: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var detail: String
    var accentName: String
    var notes: String

    init(
        id: UUID = UUID(),
        name: String,
        detail: String,
        accentName: String,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.detail = detail
        self.accentName = accentName
        self.notes = notes
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case detail
        case accentName
        case notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        detail = try container.decodeIfPresent(String.self, forKey: .detail) ?? ""
        accentName = try container.decodeIfPresent(String.self, forKey: .accentName) ?? "aurora"
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
    }
}

enum FocusTaskTimingMode: String, Codable, Equatable, CaseIterable, Identifiable {
    case timed
    case checklist

    var id: String { rawValue }
}

struct FocusTask: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var projectID: UUID?
    var projectName: String
    var timingMode: FocusTaskTimingMode
    var estimate: TimeInterval
    var completed: TimeInterval
    var isDone: Bool

    init(
        id: UUID = UUID(),
        title: String,
        projectID: UUID? = nil,
        projectName: String = "",
        timingMode: FocusTaskTimingMode = .timed,
        estimate: TimeInterval,
        completed: TimeInterval,
        isDone: Bool
    ) {
        self.id = id
        self.title = title
        self.projectID = projectID
        self.projectName = projectName
        self.timingMode = timingMode
        self.estimate = estimate
        self.completed = completed
        self.isDone = isDone
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case projectID
        case projectName
        case timingMode
        case estimate
        case completed
        case isDone
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        projectID = try container.decodeIfPresent(UUID.self, forKey: .projectID)
        projectName = try container.decodeIfPresent(String.self, forKey: .projectName) ?? ""
        timingMode = try container.decodeIfPresent(FocusTaskTimingMode.self, forKey: .timingMode) ?? .timed
        estimate = try container.decode(TimeInterval.self, forKey: .estimate)
        completed = try container.decode(TimeInterval.self, forKey: .completed)
        isDone = try container.decode(Bool.self, forKey: .isDone)
    }
}

struct SessionOutcomePresentation: Identifiable, Equatable {
    var record: FocusSessionRecord
    var task: FocusTask?

    var id: UUID { record.id }
}

@MainActor
final class FocusGlassViewModel: ObservableObject {
    static let mainWindowIdentifier = NSUserInterfaceItemIdentifier("FocusGlass.main")
    static let themeTransitionAnimation = Animation.easeInOut(duration: 0.42)

    @Published var selectedPreset: TimerPreset = .pomodoro
    @Published var selectedPresetID: UUID = TimerPreset.pomodoro.id { didSet { persist() } }
    @Published var timerPresets: [TimerPreset] = TimerPreset.defaultPresets { didSet { persist() } }
    @Published var selectedThemeID: UUID = ThemeProfile.noirCrimsonID {
        didSet {
            guard oldValue != selectedThemeID, !isApplyingThemeMutation else { return }
            handleThemePreferenceChanged(reason: "selectedThemeID")
        }
    }
    @Published var themeProfiles: [ThemeProfile] = ThemeProfile.builtIn {
        didSet {
            guard oldValue != themeProfiles, !isApplyingThemeMutation else { return }
            handleThemePreferenceChanged(reason: "themeProfiles")
        }
    }
    @Published var appearanceMode: AppAppearanceMode = .system {
        didSet {
            guard oldValue != appearanceMode else { return }
            if appearanceMode == .system {
                updateSystemAppearance()
            }
            guard !isApplyingThemeMutation else { return }
            handleThemePreferenceChanged(reason: "appearanceMode")
        }
    }
    @Published var language: AppLanguage = .ru {
        didSet {
            focusGuard.setLanguage(language)
            persist()
        }
    }
    @Published var strictModeEnabled = false { didSet { persist() } }
    @Published var strictModeEnforcesDuringBreaks = false { didSet { persist() } }
    @Published var hasSeenPermissionsOnboarding = false { didSet { persist() } }
    @Published var intention = "" { didSet { persist() } }
    @Published var activeProject = "" { didSet { persist() } }
    @Published var activeProjectID: UUID? = nil { didSet { syncActiveProjectName(); syncActiveTaskSelection(); persist() } }
    @Published var activeTaskID: UUID? = nil { didSet { persist() } }
    @Published var selectedSidebarItem = SidebarItem.focusToday
    @Published var selectedSettingsTab = SettingsTab.general
    @Published var focusGuard = FocusGuardService()
    @Published var lastThemeMessage: String?
    @Published private(set) var storageWarnings: [String] = []
    @Published private(set) var lastStorageStatus: FocusGlassStoreStatus?
    @Published private(set) var lastIconStatus: String?
    @Published private(set) var isThemeSideEffectPending = false
    @Published private(set) var lastThemePerformanceMessage: String?
    @Published private(set) var themeTransitionID = 0
    @Published private(set) var isPersistenceBlocked = false
    @Published private var systemAppearance: AppResolvedAppearance = .current
    @Published private(set) var isFocusModeActive = false
    @Published private(set) var engineSnapshot: TimerEngineSnapshot
    @Published var projects: [FocusProject] = [] { didSet { persist() } }
    @Published var tasks: [FocusTask] = [] { didSet { syncActiveTaskSelection(); persist() } }
    @Published var distractionRules: [DistractionRuleSpec] = [] { didSet { persist() } }
    @Published var distractionHistory: [DistractionEventRecord] = [] { didSet { persist() } }
    @Published var recentSessions: [FocusSessionRecord] = [] { didSet { persist() } }
    @Published private(set) var pendingSessionOutcome: SessionOutcomePresentation?

    private var timer: Timer?
    private let engine: FocusTimerEngine
    private let store: FocusGlassStore
    private var isHydrating = true
    private var currentDistractionCount = 0
    private var currentSessionID: UUID?
    private var sessionProjectID: UUID?
    private var sessionProjectName = ""
    private var sessionMode: TimerMode?
    private var sessionTaskID: UUID?
    private var focusGuardObservation: AnyCancellable?
    private var appearanceObservation: NSObjectProtocol?
    private var themeSideEffectTask: Task<Void, Never>?
    private var runtimeIconTask: Task<Void, Never>?
    private var isApplyingThemeMutation = false
    private var lastRuntimeIconUpdateDuration: TimeInterval = 0

    init(store: FocusGlassStore = FocusGlassStore(), requestPermissionsOnLaunch: Bool = true) {
        self.store = store
        let engine = FocusTimerEngine(preset: .pomodoro)
        self.engine = engine
        self.engineSnapshot = engine.snapshot
        focusGuardObservation = focusGuard.objectWillChange.sink { [weak self] _ in
            Task { @MainActor in
                self?.objectWillChange.send()
            }
        }

        let loadResult = store.load()
        storageWarnings = loadResult.warnings
        isPersistenceBlocked = loadResult.shouldBlockAutomaticSave

        if let persisted = loadResult.state {
            let cleanState = Self.sanitizedStarterState(persisted)
            themeProfiles = Self.mergeThemeProfiles(cleanState.themeProfiles)
            selectedThemeID = cleanState.selectedThemeID
            timerPresets = Self.mergedTimerPresets(cleanState.timerPresets)
            selectedPresetID = cleanState.selectedPresetID
            language = cleanState.language
            appearanceMode = cleanState.appearanceMode
            strictModeEnabled = cleanState.strictModeEnabled
            strictModeEnforcesDuringBreaks = cleanState.strictModeEnforcesDuringBreaks
            hasSeenPermissionsOnboarding = cleanState.hasSeenPermissionsOnboarding
            intention = cleanState.intention
            activeProjectID = cleanState.activeProjectID
            activeTaskID = cleanState.activeTaskID
            activeProject = cleanState.activeProject
            projects = cleanState.projects
            tasks = cleanState.tasks
            distractionRules = cleanState.distractionRules
            distractionHistory = cleanState.distractionHistory
            recentSessions = cleanState.recentSessions
        }

        if !themeProfiles.contains(where: { $0.id == selectedThemeID }) {
            selectedThemeID = ThemeProfile.noirCrimsonID
        }

        selectedPreset = timerPresets.first(where: { $0.id == selectedPresetID }) ?? timerPresets.first ?? .pomodoro
        selectedPresetID = selectedPreset.id
        focusGuard.setLanguage(language)
        engine.configure(selectedPreset)
        syncActiveProjectName()
        syncActiveTaskSelection()
        installAppearanceObserver()
        updateSystemAppearance()
        updateRuntimeIcons()

        isHydrating = false
        updateRuntimeIcons()
        if requestPermissionsOnLaunch {
            requestMissingPermissionsIfNeeded()
        } else {
            focusGuard.refreshPermissionStates()
        }
        if !isPersistenceBlocked {
            persist()
        }
    }

    var presets: [TimerPreset] {
        timerPresets
    }

    var selectedThemeProfile: ThemeProfile {
        themeProfiles.first(where: { $0.id == selectedThemeID }) ?? ThemeProfile.builtIn[0]
    }

    var effectiveTheme: ThemeProfile {
        effectiveTheme(for: resolvedAppearance)
    }

    var theme: ThemeProfile {
        effectiveTheme
    }

    var iconTheme: ThemeProfile {
        selectedThemeProfile.adapted(to: resolvedAppearance)
    }

    var preferredColorScheme: ColorScheme? {
        switch appearanceMode {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var resolvedAppearance: AppResolvedAppearance {
        switch appearanceMode {
        case .system: systemAppearance
        case .light: .light
        case .dark: .dark
        }
    }

    var dataDirectoryPath: String {
        store.paths.dataDirectory.path
    }

    var workspacePath: String {
        store.paths.workspaceURL.path
    }

    var settingsPath: String {
        store.paths.settingsURL.path
    }

    var storageStatusTitle: String {
        if isPersistenceBlocked {
            return t("storage.blocked")
        }
        if let lastStorageStatus {
            return lastStorageStatus.isError ? t("storage.saveFailed") : t("storage.saved")
        }
        return t("storage.ready")
    }

    var canSkipSegment: Bool {
        engineSnapshot.preset.segments.count > 1
    }

    var menuBarTitle: String {
        switch engineSnapshot.status {
        case .running, .paused:
            return engineSnapshot.preset.mode == .stopwatch
                ? engineSnapshot.elapsed.focusClock
                : engineSnapshot.remaining.focusClock
        case .idle:
            return "FocusGlass"
        case .completed:
            return t("timer.status.completed")
        }
    }

    var primaryClockText: String {
        engineSnapshot.preset.mode == .stopwatch
            ? engineSnapshot.elapsed.focusClock
            : engineSnapshot.remaining.focusClock
    }

    var dailySummary: DailyFocusSummary {
        AnalyticsEngine.summarize(recentSessions)
    }

    var modeEffectivenessSummaries: [ModeEffectivenessSummary] {
        AnalyticsEngine.summarizeByMode(recentSessions)
    }

    var projectFocusSummaries: [ProjectFocusSummary] {
        AnalyticsEngine.summarizeByProject(recentSessions)
    }

    var activeProjectName: String {
        activeProjectID.flatMap(projectName(for:)) ?? ""
    }

    var unassignedProjectTitle: String {
        t("projects.unassigned")
    }

    var activeTasks: [FocusTask] {
        tasks.filter { !$0.isDone && $0.projectID == activeProjectID }
    }

    var selectedActiveTask: FocusTask? {
        activeTaskID.flatMap { taskID in
            activeTasks.first { $0.id == taskID }
        }
    }

    var selectedTaskTitle: String {
        selectedActiveTask?.title ?? t("tasks.noActiveTask")
    }

    var needsPermissionAttention: Bool {
        [.notifications, .accessibility, .automation].contains { permission in
            focusGuard.status(for: permission).needsUserAction
        }
    }

    var focusHeatmapValues: [Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let days = (0..<28).compactMap { offset in
            calendar.date(byAdding: .day, value: offset - 27, to: today)
        }
        let totals = days.map { day in
            recentSessions
                .filter { calendar.isDate($0.startedAt, inSameDayAs: day) }
                .reduce(0) { $0 + $1.honestFocusSeconds }
        }
        let maxValue = max(totals.max() ?? 0, 1)
        return totals.map { min(1, max(0, $0 / maxValue)) }
    }

    var strictModeCanEvaluateCurrentPhase: Bool {
        strictModeEnabled
            && engineSnapshot.status == .running
            && (strictModeEnforcesDuringBreaks || engineSnapshot.activeSegment.phase == .focus)
    }

    func t(_ key: String) -> String {
        L10n.string(key, language: language)
    }

    func sidebarTitle(_ item: SidebarItem) -> String {
        t(item.titleKey)
    }

    func languageTitle(_ language: AppLanguage) -> String {
        switch language {
        case .ru: t("language.ru")
        case .en: t("language.en")
        case .system: t("language.system")
        }
    }

    func appearanceModeTitle(_ mode: AppAppearanceMode) -> String {
        switch mode {
        case .system: t("appearance.system")
        case .light: t("appearance.light")
        case .dark: t("appearance.dark")
        }
    }

    func setAppearanceMode(_ mode: AppAppearanceMode) {
        guard appearanceMode != mode else { return }
        performThemeMutation(reason: "appearanceMode") {
            appearanceMode = mode
        }
    }

    func effectiveTheme(for appearance: AppResolvedAppearance) -> ThemeProfile {
        selectedThemeProfile.adapted(to: appearance)
    }

    func presetTitle(_ preset: TimerPreset) -> String {
        if TimerPreset.defaultPreset(matching: preset)?.name == preset.name {
            let focusMinutes = preset.segments
                .filter { $0.phase == .focus && $0.duration > 0 }
                .map { Int(($0.duration / 60).rounded()) }
            let suffix = focusMinutes.isEmpty ? "" : " \(focusMinutes.map(String.init).joined(separator: "/"))"
            return "\(timerModeTitle(preset.mode))\(suffix)"
        }
        return preset.name
    }

    func timerModeTitle(_ mode: TimerMode) -> String {
        switch mode {
        case .pomodoro: t("timer.mode.pomodoro")
        case .countdown: t("timer.mode.countdown")
        case .stopwatch: t("timer.mode.stopwatch")
        case .flow: t("timer.mode.flow")
        case .timebox: t("timer.mode.timebox")
        case .intervals: t("timer.mode.intervals")
        }
    }

    func timerModeDescription(_ mode: TimerMode) -> String {
        switch mode {
        case .pomodoro: t("timer.mode.pomodoro.detail")
        case .countdown: t("timer.mode.countdown.detail")
        case .stopwatch: t("timer.mode.stopwatch.detail")
        case .flow: t("timer.mode.flow.detail")
        case .timebox: t("timer.mode.timebox.detail")
        case .intervals: t("timer.mode.intervals.detail")
        }
    }

    func projectName(for projectID: UUID?) -> String? {
        guard let projectID else { return nil }
        return projects.first { $0.id == projectID }?.name
    }

    func displayProjectName(for projectID: UUID?, legacyName: String = "") -> String {
        projectName(for: projectID) ?? (legacyName.isEmpty ? unassignedProjectTitle : legacyName)
    }

    func tasks(for project: FocusProject) -> [FocusTask] {
        tasks.filter { $0.projectID == project.id }
    }

    func sessions(for project: FocusProject) -> [FocusSessionRecord] {
        recentSessions.filter { $0.projectID == project.id }
    }

    func task(for taskID: UUID?) -> FocusTask? {
        guard let taskID else { return nil }
        return tasks.first { $0.id == taskID }
    }

    var unassignedSessions: [FocusSessionRecord] {
        recentSessions.filter { $0.projectID == nil }
    }

    func phaseTitle(_ phase: TimerPhase) -> String {
        t("timer.phase.\(phase.rawValue)")
    }

    func taskTimingModeTitle(_ mode: FocusTaskTimingMode) -> String {
        switch mode {
        case .timed: t("tasks.timed")
        case .checklist: t("tasks.checklist")
        }
    }

    func statusTitle(_ status: TimerStatus) -> String {
        t("timer.status.\(status.rawValue)")
    }

    func permissionTitle(_ permission: FocusPermission) -> String {
        switch permission {
        case .notifications: t("settings.notifications")
        case .accessibility: t("settings.accessibility")
        case .automation: t("settings.automation")
        case .launchAtLogin: t("settings.launchAtLogin")
        }
    }

    func permissionStatusTitle(_ status: FocusPermissionStatus) -> String {
        switch status {
        case .unknown: t("permissions.status.unknown")
        case .granted: t("permissions.status.granted")
        case .missing: t("permissions.status.missing")
        case .unavailable: t("permissions.status.unavailable")
        }
    }

    func actionTitle(_ action: DistractionAction) -> String {
        switch action {
        case .warn: t("strict.warning")
        case .hide: t("strict.hide")
        case .pauseSession: t("strict.pause")
        case .quitAfterOptIn: t("strict.quit")
        }
    }

    func targetKindTitle(_ kind: DistractionTargetKind) -> String {
        switch kind {
        case .app: t("strict.apps")
        case .site: t("strict.sites")
        }
    }

    func selectPreset(_ preset: TimerPreset) {
        selectedPreset = preset
        selectedPresetID = preset.id
        engine.configure(preset)
        syncSnapshot()
    }

    func selectProject(_ project: FocusProject) {
        activeProjectID = project.id
        selectedSidebarItem = .projects
    }

    func selectUnassignedProject() {
        activeProjectID = nil
        selectedSidebarItem = .projects
    }

    func selectTaskForSession(_ task: FocusTask) {
        guard !task.isDone, task.projectID == activeProjectID else { return }
        activeTaskID = task.id
    }

    @discardableResult
    func addQuickTask() -> FocusTask {
        let title = t("tasks.new")
        let task = FocusTask(
            title: title,
            projectID: activeProjectID,
            projectName: activeProjectName,
            estimate: 25 * 60,
            completed: 0,
            isDone: false
        )
        tasks.insert(task, at: 0)
        activeTaskID = task.id
        return task
    }

    @discardableResult
    func addProject() -> FocusProject {
        let baseName = t("projects.new")
        let existingNames = Set(projects.map(\.name))
        let name = existingNames.contains(baseName) ? "\(baseName) \(projects.count + 1)" : baseName
        let project = FocusProject(name: name, detail: t("projects.new.detail"), accentName: "aurora")
        projects.append(project)
        if activeProjectID == nil {
            activeProjectID = project.id
        }
        return project
    }

    func updateProject(_ project: FocusProject) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        let trimmedName = project.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetail = project.detail.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = project.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        projects[index].name = trimmedName.isEmpty ? t("projects.new") : trimmedName
        projects[index].detail = trimmedDetail.isEmpty ? t("projects.new.detail") : trimmedDetail
        projects[index].accentName = project.accentName
        projects[index].notes = trimmedNotes
        syncActiveProjectName()
    }

    func updateActiveProjectNotes(_ notes: String) {
        guard let activeProjectID,
              let index = projects.firstIndex(where: { $0.id == activeProjectID }) else { return }
        projects[index].notes = notes
    }

    func deleteProject(_ project: FocusProject) {
        projects.removeAll { $0.id == project.id }
        for index in tasks.indices where tasks[index].projectID == project.id {
            tasks[index].projectID = nil
            tasks[index].projectName = ""
        }
        for index in recentSessions.indices where recentSessions[index].projectID == project.id {
            recentSessions[index].projectID = nil
            recentSessions[index].projectName = ""
        }
        if activeProjectID == project.id {
            activeProjectID = projects.first?.id
        }
        syncActiveProjectName()
    }

    func updateTask(_ task: FocusTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        var cleanTask = task
        cleanTask.title = task.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanTask.title.isEmpty {
            cleanTask.title = t("tasks.new")
        }
        cleanTask.estimate = max(60, task.estimate)
        cleanTask.completed = cleanTask.timingMode == .timed
            ? min(max(0, task.completed), cleanTask.estimate)
            : 0
        cleanTask.projectName = projectName(for: cleanTask.projectID) ?? ""
        tasks[index] = cleanTask
        if cleanTask.projectID != activeProjectID {
            activeProjectID = cleanTask.projectID
        }
        activeTaskID = cleanTask.isDone ? nil : cleanTask.id
        syncActiveTaskSelection()
    }

    func deleteTask(_ task: FocusTask) {
        tasks.removeAll { $0.id == task.id }
        if activeTaskID == task.id {
            activeTaskID = nil
        }
        if sessionTaskID == task.id {
            sessionTaskID = nil
        }
        syncActiveTaskSelection()
    }

    func updateTaskEstimate(_ task: FocusTask, estimate: TimeInterval) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].estimate = max(60, estimate)
        tasks[index].completed = min(tasks[index].completed, tasks[index].estimate)
    }

    func updatePreset(_ presetID: UUID, mutate: (inout TimerPreset) -> Void) {
        guard let index = timerPresets.firstIndex(where: { $0.id == presetID }) else { return }
        mutate(&timerPresets[index])
        sanitizePreset(at: index)
        if selectedPresetID == presetID {
            selectedPreset = timerPresets[index]
            if engineSnapshot.status != .running {
                engine.configure(selectedPreset)
                syncSnapshot()
            }
        }
    }

    func updatePresetSegment(_ presetID: UUID, index segmentIndex: Int, mutate: (inout TimerSegment) -> Void) {
        updatePreset(presetID) { preset in
            guard preset.segments.indices.contains(segmentIndex) else { return }
            mutate(&preset.segments[segmentIndex])
        }
    }

    func addPresetSegment(to presetID: UUID) {
        updatePreset(presetID) { preset in
            preset.segments.append(
                TimerSegment(title: t("timer.phase.focus"), duration: 25 * 60, phase: .focus)
            )
        }
    }

    func deletePresetSegment(_ presetID: UUID, index segmentIndex: Int) {
        updatePreset(presetID) { preset in
            guard preset.segments.count > 1, preset.segments.indices.contains(segmentIndex) else { return }
            preset.segments.remove(at: segmentIndex)
        }
    }

    func resetPresetToDefault(_ presetID: UUID) {
        guard let index = timerPresets.firstIndex(where: { $0.id == presetID }),
              let replacement = TimerPreset.defaultPreset(matching: timerPresets[index]) else { return }
        timerPresets[index] = replacement
        if selectedPresetID == presetID || selectedPresetID == replacement.id {
            selectPreset(replacement)
        }
    }

    func requestMissingPermissionsIfNeeded() {
        focusGuard.refreshPermissionStates()
        guard focusGuard.canUseUserNotifications, !hasSeenPermissionsOnboarding else { return }
        hasSeenPermissionsOnboarding = true
        focusGuard.requestNotificationPermissionIfNeeded()
    }

    func openFocusModeFullscreen() {
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func toggleTimer() {
        switch engineSnapshot.status {
        case .idle, .completed:
            prepareSessionContext()
            engine.start()
            focusGuard.runShortcut(named: "FocusGlass Start")
            scheduleTick()
        case .running:
            engine.pause()
            focusGuard.runShortcut(named: "FocusGlass Pause")
            stopTick()
        case .paused:
            engine.resume()
            focusGuard.runShortcut(named: "FocusGlass Resume")
            scheduleTick()
        }
        syncSnapshot()
    }

    func resetTimer() {
        engine.reset()
        clearSessionContext()
        stopTick()
        syncSnapshot()
    }

    func skipSegment() {
        guard canSkipSegment else { return }
        let event = engine.skipSegment()
        handle(event)
        syncSnapshot()
    }

    func toggleTask(_ task: FocusTask) {
        guard let index = tasks.firstIndex(of: task) else { return }
        tasks[index].isDone.toggle()
        if tasks[index].isDone, activeTaskID == task.id {
            activeTaskID = nil
            syncActiveTaskSelection()
        } else if !tasks[index].isDone {
            activeTaskID = task.id
        }
    }

    func dismissSessionOutcome() {
        pendingSessionOutcome = nil
    }

    func completeOutcomeTask() {
        guard let outcome = pendingSessionOutcome else { return }
        if let taskID = outcome.record.taskID,
           let index = tasks.firstIndex(where: { $0.id == taskID }) {
            tasks[index].isDone = true
            if activeTaskID == taskID {
                activeTaskID = nil
            }
            syncActiveTaskSelection()
        }
        pendingSessionOutcome = nil
    }

    func continueOutcomeTask() {
        guard let outcome = pendingSessionOutcome else { return }
        selectOutcomeTaskIfAvailable(outcome)
        pendingSessionOutcome = nil
    }

    func startNextSessionFromOutcome() {
        guard let outcome = pendingSessionOutcome else { return }
        selectOutcomeTaskIfAvailable(outcome)
        pendingSessionOutcome = nil
        guard engineSnapshot.status != .running else { return }

        prepareSessionContext()
        engine.start()
        focusGuard.runShortcut(named: "FocusGlass Start")
        scheduleTick()
        syncSnapshot()
    }

    func toggleRule(_ rule: DistractionRuleSpec) {
        guard let index = distractionRules.firstIndex(of: rule) else { return }
        distractionRules[index].isEnabled.toggle()
    }

    func updateRule(_ rule: DistractionRuleSpec) {
        guard let index = distractionRules.firstIndex(where: { $0.id == rule.id }) else { return }
        distractionRules[index] = rule
    }

    func deleteRule(_ rule: DistractionRuleSpec) {
        distractionRules.removeAll { $0.id == rule.id }
    }

    func clearDistractionHistory() {
        distractionHistory.removeAll()
    }

    var appRules: [DistractionRuleSpec] {
        distractionRules.filter { $0.targetKind == .app }
    }

    var siteRules: [DistractionRuleSpec] {
        distractionRules.filter { $0.targetKind == .site }
    }

    var enabledAppRuleCount: Int {
        appRules.filter(\.isEnabled).count
    }

    var enabledSiteRuleCount: Int {
        siteRules.filter(\.isEnabled).count
    }

    var availableDistractionApps: [RunningApplicationOption] {
        let ownBundleID = Bundle.main.bundleIdentifier
        let options = NSWorkspace.shared.runningApplications.compactMap { app -> RunningApplicationOption? in
            guard let bundleIdentifier = app.bundleIdentifier,
                  bundleIdentifier != ownBundleID,
                  app.activationPolicy == .regular else { return nil }
            return RunningApplicationOption(
                label: app.localizedName ?? bundleIdentifier,
                bundleIdentifier: bundleIdentifier
            )
        }
        return Array(Set(options)).sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }
    }

    func addAppDistractionRule(label: String, bundleIdentifier: String) {
        let trimmedBundleID = bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBundleID.isEmpty else { return }
        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        upsertDistractionRule(
            DistractionRuleSpec(
                label: trimmedLabel.isEmpty ? trimmedBundleID : trimmedLabel,
                targetKind: .app,
                matchValue: trimmedBundleID,
                bundleIdentifier: trimmedBundleID,
                action: .hide,
                isEnabled: true
            )
        )
    }

    func addSiteDistractionRule(pattern: String) {
        guard let normalized = DistractionRuleSpec.normalizedSitePattern(pattern) else { return }
        upsertDistractionRule(
            DistractionRuleSpec(
                label: normalized,
                targetKind: .site,
                matchValue: normalized,
                sitePattern: normalized,
                action: .hide,
                isEnabled: true
            )
        )
    }

    func requestAccessibilityPermission() {
        focusGuard.requestAccessibilityPermission()
    }

    func requestAutomationPermission() {
        focusGuard.requestAutomationPermission()
    }

    func toggleLaunchAtLogin() {
        focusGuard.toggleLaunchAtLogin()
    }

    func enterFocusMode() {
        isFocusModeActive = true
        focusGuard.refreshPermissionStates()
        evaluateStrictModeIfNeeded()
    }

    func leaveFocusMode() {
        isFocusModeActive = false
    }

    func markSyntheticDistraction() {
        guard let rule = distractionRules.first else { return }
        focusGuard.handleDistraction(rule: rule)
        recentSessions.insert(
            FocusSessionRecord(
                projectID: activeProjectID,
                projectName: activeProjectName,
                mode: selectedPreset.mode,
                startedAt: .now.addingTimeInterval(-20 * 60),
                endedAt: .now,
                plannedSeconds: selectedPreset.totalDuration,
                honestFocusSeconds: max(0, engineSnapshot.honestFocusTime - 90),
                distractionCount: 1
            ),
            at: 0
        )
    }

    func selectTheme(_ profile: ThemeProfile) {
        guard selectedThemeID != profile.id else { return }
        performThemeMutation(reason: "selectedThemeID") {
            selectedThemeID = profile.id
        }
    }

    func duplicateActiveTheme() {
        var copy = selectedThemeProfile
        copy.id = UUID()
        copy.name = "\(selectedThemeProfile.name) Custom"
        copy.isBuiltIn = false
        performThemeMutation(reason: "themeProfiles") {
            themeProfiles.append(copy)
            selectedThemeID = copy.id
        }
        lastThemeMessage = t("theme.duplicated")
    }

    func resetActiveTheme() {
        guard selectedThemeProfile.isBuiltIn,
              let builtIn = ThemeProfile.builtIn.first(where: { $0.id == selectedThemeID }),
              let index = themeProfiles.firstIndex(where: { $0.id == selectedThemeID }) else {
            return
        }
        performThemeMutation(reason: "themeProfiles") {
            themeProfiles[index] = builtIn
        }
        lastThemeMessage = t("theme.resetDone")
    }

    func deleteActiveCustomTheme() {
        guard !selectedThemeProfile.isBuiltIn else { return }
        let currentID = selectedThemeID
        performThemeMutation(reason: "themeProfiles") {
            selectedThemeID = ThemeProfile.graphiteAuroraID
            themeProfiles.removeAll { $0.id == currentID }
        }
        lastThemeMessage = t("theme.deleted")
    }

    func updateActiveTheme(_ mutate: (inout ThemeProfile) -> Void) {
        if selectedThemeProfile.isBuiltIn {
            var copy = selectedThemeProfile
            copy.id = UUID()
            copy.name = "\(selectedThemeProfile.name) Custom"
            copy.isBuiltIn = false
            mutate(&copy)

            performThemeMutation(reason: "themeProfiles") {
                themeProfiles.append(copy)
                selectedThemeID = copy.id
            }
            lastThemeMessage = t("theme.duplicated")
            return
        }

        guard let index = themeProfiles.firstIndex(where: { $0.id == selectedThemeID }) else { return }
        performThemeMutation(reason: "themeProfiles") {
            mutate(&themeProfiles[index])
        }
    }

    func exportActiveThemeJSON() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(selectedThemeProfile),
              let text = String(data: data, encoding: .utf8) else {
            lastThemeMessage = t("theme.exportFailed")
            return
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        lastThemeMessage = t("theme.exported")
    }

    func importThemeJSONFromClipboard() {
        guard let text = NSPasteboard.general.string(forType: .string),
              let data = text.data(using: .utf8),
              var imported = try? JSONDecoder().decode(ThemeProfile.self, from: data) else {
            lastThemeMessage = t("theme.importFailed")
            return
        }

        imported.id = UUID()
        imported.isBuiltIn = false
        performThemeMutation(reason: "themeProfiles") {
            themeProfiles.append(imported)
            selectedThemeID = imported.id
        }
        lastThemeMessage = t("theme.imported")
    }

    func openDataDirectory() {
        store.openDataDirectory()
    }

    func focusMainWindow(openWindow: () -> Void) {
        if let window = Self.reusableMainWindow(in: NSApplication.shared.windows) {
            if window.isMiniaturized {
                window.deminiaturize(nil)
            }
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }

        openWindow()
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func updateSystemAppearance() {
        let nextAppearance = AppResolvedAppearance.current
        guard systemAppearance != nextAppearance else { return }
        systemAppearance = nextAppearance
    }

    func updateSystemAppearanceAnimated() {
        let nextAppearance = AppResolvedAppearance.current
        guard systemAppearance != nextAppearance else { return }
        withAnimation(Self.themeTransitionAnimation) {
            systemAppearance = nextAppearance
            themeTransitionID &+= 1
        }
        scheduleRuntimeIconUpdate(reason: "systemAppearance")
        scheduleThemeSideEffects(reason: "systemAppearance", uiUpdateDuration: 0)
    }

    func updateRuntimeIcons(persistAppIcon: Bool = false) {
        guard !isHydrating else { return }
        let image = FocusGlassRuntimeIcon.image(theme: iconTheme)
        NSApplication.shared.applicationIconImage = image

        guard persistAppIcon else { return }
        persistApplicationIcon(image)
    }

    func flushPendingThemeSideEffectsForTesting() async {
        themeSideEffectTask?.cancel()
        runtimeIconTask?.cancel()
        applyRuntimeIconUpdate(reason: "test")
        flushThemeSideEffects(reason: "test", uiUpdateDuration: 0)
    }

    func flushPendingThemeSideEffectsBeforeExit() {
        guard !isHydrating else { return }
        themeSideEffectTask?.cancel()
        runtimeIconTask?.cancel()
        applyRuntimeIconUpdate(reason: "applicationWillTerminate")
        flushThemeSideEffects(reason: "applicationWillTerminate", uiUpdateDuration: 0)
    }

    func startTimerForTesting() {
        prepareSessionContext()
        engine.start()
        syncSnapshot()
    }

    func advanceTimerForTesting(by seconds: TimeInterval) {
        let event = engine.tick(by: seconds)
        handle(event)
        syncSnapshot()
    }

    func applyDistractionResponseForTesting(action: DistractionAction) {
        applyHandledDistractionResponse(
            DistractionRuleSpec(
                label: "Test",
                targetKind: .app,
                matchValue: "test.bundle",
                bundleIdentifier: "test.bundle",
                action: action,
                isEnabled: true
            )
        )
    }

    private func scheduleTick() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func stopTick() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        let event = engine.tick()
        handle(event)
        syncSnapshot()
        evaluateStrictModeIfNeeded()
    }

    private func evaluateStrictModeIfNeeded() {
        guard strictModeCanEvaluateCurrentPhase,
              let rule = focusGuard.activeDistractionRule(from: distractionRules) else { return }
        if focusGuard.handleDistraction(rule: rule) {
            applyHandledDistractionResponse(rule)
        }
    }

    private func applyHandledDistractionResponse(_ rule: DistractionRuleSpec) {
        let effectiveAction = rule.effectiveAction
        if effectiveAction == .pauseSession {
            pauseTimerAfterDistraction()
        }
        currentDistractionCount += 1
        distractionHistory.insert(
            DistractionEventRecord(
                ruleID: rule.id,
                targetKind: rule.targetKind,
                targetLabel: rule.label,
                matchValue: rule.matchValue,
                action: effectiveAction,
                sessionID: currentSessionID,
                projectID: sessionProjectID ?? activeProjectID,
                projectName: sessionProjectName.isEmpty ? activeProjectName : sessionProjectName,
                taskID: sessionTaskID,
                taskTitle: sessionTaskID.flatMap(taskTitle(for:)),
                mode: sessionMode ?? selectedPreset.mode
            ),
            at: 0
        )
        if distractionHistory.count > 500 {
            distractionHistory.removeLast(distractionHistory.count - 500)
        }
        focusAfterDistraction()
    }

    private func pauseTimerAfterDistraction() {
        guard engineSnapshot.status == .running else { return }
        engine.pause()
        focusGuard.runShortcut(named: "FocusGlass Pause")
        stopTick()
        syncSnapshot()
    }

    private func focusAfterDistraction() {
        selectedSidebarItem = .focusToday
        if isFocusModeActive {
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }

        if let window = Self.reusableMainWindow(in: NSApplication.shared.windows) {
            if window.isMiniaturized {
                window.deminiaturize(nil)
            }
            window.makeKeyAndOrderFront(nil)
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func handle(_ event: TimerEngineEvent) {
        switch event {
        case .none:
            break
        case .segmentCompleted(let segment):
            focusGuard.sendSessionNotification(
                title: phaseTitle(segment.phase),
                body: "\(t("timer.nextPhase")): \(phaseTitle(engine.activeSegment.phase))"
            )
        case .presetCompleted:
            stopTick()
            focusGuard.runShortcut(named: "FocusGlass End")
            let finalSnapshot = engine.snapshot
            focusGuard.sendSessionNotification(
                title: t("timer.sessionCompleted"),
                body: "\(t("focus.honestTime")): \(finalSnapshot.honestFocusTime.focusClock)"
            )
            let capturedTaskID = sessionTaskID
            let sessionRecord = FocusSessionRecord(
                id: currentSessionID ?? UUID(),
                projectID: sessionProjectID,
                projectName: sessionProjectName,
                taskID: capturedTaskID,
                taskTitle: capturedTaskID.flatMap(taskTitle(for:)),
                mode: sessionMode ?? selectedPreset.mode,
                startedAt: .now.addingTimeInterval(-finalSnapshot.elapsed),
                endedAt: .now,
                plannedSeconds: max(1, selectedPreset.totalDuration),
                honestFocusSeconds: finalSnapshot.honestFocusTime,
                distractionCount: currentDistractionCount
            )
            recentSessions.insert(sessionRecord, at: 0)
            applySessionTimeToCapturedTask(finalSnapshot.honestFocusTime)
            pendingSessionOutcome = SessionOutcomePresentation(
                record: sessionRecord,
                task: capturedTaskID.flatMap(task(for:))
            )
            selectedSidebarItem = .focusToday
            clearSessionContext()
        }
    }

    private func upsertDistractionRule(_ rule: DistractionRuleSpec) {
        if let index = distractionRules.firstIndex(where: {
            $0.targetKind == rule.targetKind && $0.matchValue == rule.matchValue
        }) {
            distractionRules[index] = rule
        } else {
            distractionRules.append(rule)
        }
    }

    private func syncSnapshot() {
        engineSnapshot = engine.snapshot
    }

    private func persist() {
        guard !isHydrating, !isPersistenceBlocked else { return }

        store.save(
            workspace: FocusGlassWorkspaceState(
                schemaVersion: 5,
                intention: intention,
                activeProjectID: activeProjectID,
                activeTaskID: activeTaskID,
                activeProject: activeProject,
                projects: projects,
                tasks: tasks,
                distractionRules: distractionRules,
                distractionHistory: distractionHistory,
                recentSessions: recentSessions
            ),
            settings: FocusGlassSettingsState(
                schemaVersion: 5,
                selectedThemeID: selectedThemeID,
                themeProfiles: themeProfiles,
                selectedPresetID: selectedPresetID,
                timerPresets: timerPresets,
                language: language,
                appearanceMode: appearanceMode,
                strictModeEnabled: strictModeEnabled,
                strictModeEnforcesDuringBreaks: strictModeEnforcesDuringBreaks,
                hasSeenPermissionsOnboarding: hasSeenPermissionsOnboarding
            )
        )
        lastStorageStatus = store.lastSaveStatus
    }

    private func prepareSessionContext() {
        currentDistractionCount = 0
        syncActiveTaskSelection()
        currentSessionID = UUID()
        sessionProjectID = activeProjectID
        sessionProjectName = activeProjectName
        sessionMode = selectedPreset.mode
        sessionTaskID = selectedActiveTask?.id
    }

    private func clearSessionContext() {
        currentSessionID = nil
        sessionProjectID = nil
        sessionProjectName = ""
        sessionMode = nil
        sessionTaskID = nil
    }

    private func performThemeMutation(reason: String, _ mutate: () -> Void) {
        let wasApplyingThemeMutation = isApplyingThemeMutation
        isApplyingThemeMutation = true
        withAnimation(Self.themeTransitionAnimation) {
            mutate()
            if !wasApplyingThemeMutation {
                themeTransitionID &+= 1
            }
        }
        isApplyingThemeMutation = wasApplyingThemeMutation

        guard !wasApplyingThemeMutation else { return }
        handleThemePreferenceChanged(reason: reason, advancesTransition: false)
    }

    private func handleThemePreferenceChanged(reason: String, advancesTransition: Bool = true) {
        guard !isHydrating else { return }
        let start = Date()
        if advancesTransition, !isApplyingThemeMutation {
            withAnimation(Self.themeTransitionAnimation) {
                themeTransitionID &+= 1
            }
        }
        scheduleRuntimeIconUpdate(reason: reason)
        scheduleThemeSideEffects(
            reason: reason,
            uiUpdateDuration: Date().timeIntervalSince(start)
        )
    }

    private func scheduleRuntimeIconUpdate(reason: String) {
        runtimeIconTask?.cancel()
        runtimeIconTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 120_000_000)
            guard !Task.isCancelled else { return }
            self?.applyRuntimeIconUpdate(reason: reason)
        }
    }

    private func applyRuntimeIconUpdate(reason _: String) {
        guard !isHydrating else { return }
        let start = Date()
        updateRuntimeIcons()
        lastRuntimeIconUpdateDuration = Date().timeIntervalSince(start)
        runtimeIconTask = nil
    }

    private func scheduleThemeSideEffects(reason: String, uiUpdateDuration: TimeInterval) {
        themeSideEffectTask?.cancel()
        if !isThemeSideEffectPending {
            isThemeSideEffectPending = true
        }
        themeSideEffectTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard !Task.isCancelled else { return }
            self?.flushThemeSideEffects(reason: reason, uiUpdateDuration: uiUpdateDuration)
        }
    }

    private func flushThemeSideEffects(reason: String, uiUpdateDuration: TimeInterval) {
        guard !isHydrating else { return }

        let saveStart = Date()
        persist()
        let saveDuration = Date().timeIntervalSince(saveStart)

        let iconStart = Date()
        persistApplicationIcon(FocusGlassRuntimeIcon.image(theme: iconTheme))
        let iconDuration = Date().timeIntervalSince(iconStart)

        isThemeSideEffectPending = false
        themeSideEffectTask = nil
        let message = String(
            format: "UI %.1f ms · runtime icon %.1f ms · save %.1f ms · app icon %.1f ms",
            uiUpdateDuration * 1000,
            lastRuntimeIconUpdateDuration * 1000,
            saveDuration * 1000,
            iconDuration * 1000
        )
        lastThemePerformanceMessage = message
        FocusGlassDiagnosticsLogger.shared.log(
            .info,
            subsystem: "theme",
            code: "theme.switch_completed",
            message: "Theme side effects completed",
            details: [
                "reason": reason,
                "uiMilliseconds": String(format: "%.2f", uiUpdateDuration * 1000),
                "runtimeIconMilliseconds": String(format: "%.2f", lastRuntimeIconUpdateDuration * 1000),
                "saveMilliseconds": String(format: "%.2f", saveDuration * 1000),
                "iconMilliseconds": String(format: "%.2f", iconDuration * 1000)
            ],
            resolutionHint: "Theme UI is updated first; runtime icon, settings save, and custom app icon persistence are deferred to avoid visible hangs."
        )
    }

    private func installAppearanceObserver() {
        appearanceObservation = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard self?.appearanceMode == .system else { return }
                self?.updateSystemAppearanceAnimated()
            }
        }
    }

    private func persistApplicationIcon(_ image: NSImage) {
        let bundleURL = Bundle.main.bundleURL
        guard bundleURL.pathExtension == "app" else {
            lastIconStatus = t("icon.status.runtimeOnly")
            return
        }
        guard !Self.isUserConsentProtectedBundleLocation(bundleURL) else {
            lastIconStatus = t("icon.status.runtimeOnly")
            FocusGlassDiagnosticsLogger.shared.log(
                .info,
                subsystem: "icon",
                code: "icon.persist_skipped_protected_location",
                message: "Skipped custom app icon persistence in a user-protected folder",
                details: ["bundlePath": bundleURL.path],
                resolutionHint: "The runtime Dock icon was updated. Move the app outside Documents, Desktop, or Downloads before expecting macOS to accept persistent app icon writes without a privacy prompt."
            )
            return
        }

        let saved = NSWorkspace.shared.setIcon(image, forFile: bundleURL.path, options: [])
        if saved {
            lastIconStatus = t("icon.status.saved")
        } else {
            lastIconStatus = t("icon.status.failed")
            FocusGlassDiagnosticsLogger.shared.log(
                .warning,
                subsystem: "icon",
                code: "icon.persist_failed",
                message: "Could not persist custom app icon",
                details: ["bundlePath": bundleURL.path],
                resolutionHint: "Runtime Dock icon was updated. Finder/Dock closed icon may keep the bundled fallback if macOS rejects NSWorkspace custom icon storage."
            )
        }
    }

    static func isUserConsentProtectedBundleLocation(
        _ url: URL,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> Bool {
        let bundlePath = url.standardizedFileURL.path
        let home = homeDirectory.standardizedFileURL
        let protectedDirectories = ["Documents", "Desktop", "Downloads"].map {
            home.appendingPathComponent($0, isDirectory: true).standardizedFileURL.path
        }
        return protectedDirectories.contains { directory in
            bundlePath == directory || bundlePath.hasPrefix(directory + "/")
        }
    }

    static func reusableMainWindow(in windows: [NSWindow]) -> NSWindow? {
        windows.first { window in
            window.identifier == mainWindowIdentifier
        } ?? windows.first { window in
            window.title == "FocusGlass"
        }
    }

    private static func mergeThemeProfiles(_ persisted: [ThemeProfile]) -> [ThemeProfile] {
        var profiles = ThemeProfile.builtIn
        for profile in persisted {
            if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
                if !profile.isBuiltIn {
                    profiles[index] = profile
                }
            } else {
                profiles.append(profile)
            }
        }
        return profiles
    }

    private static func mergedTimerPresets(_ persisted: [TimerPreset]) -> [TimerPreset] {
        guard !persisted.isEmpty else { return TimerPreset.defaultPresets }
        var presets = TimerPreset.defaultPresets
        for preset in persisted {
            if let index = presets.firstIndex(where: { $0.id == preset.id }) {
                presets[index] = preset
            } else if let index = presets.firstIndex(where: { $0.mode == preset.mode && $0.name == preset.name }) {
                presets[index] = preset
            } else {
                presets.append(preset)
            }
        }
        return presets
    }

    private func syncActiveProjectName() {
        activeProject = activeProjectName
    }

    private func taskTitle(for taskID: UUID) -> String? {
        tasks.first { $0.id == taskID }?.title
    }

    private func syncActiveTaskSelection() {
        guard !isHydrating else { return }
        if let activeTaskID,
           activeTasks.contains(where: { $0.id == activeTaskID }) {
            return
        }
        activeTaskID = nil
    }

    private func selectOutcomeTaskIfAvailable(_ outcome: SessionOutcomePresentation) {
        guard let taskID = outcome.record.taskID,
              let task = task(for: taskID),
              !task.isDone else { return }
        activeProjectID = task.projectID
        activeTaskID = task.id
    }

    private func applySessionTimeToCapturedTask(_ honestFocusTime: TimeInterval) {
        guard honestFocusTime > 0,
              let sessionTaskID,
              let index = tasks.firstIndex(where: { $0.id == sessionTaskID }),
              tasks[index].timingMode == .timed else { return }
        tasks[index].completed = min(tasks[index].estimate, max(0, tasks[index].completed + honestFocusTime))
    }

    private func sanitizePreset(at index: Int) {
        guard timerPresets.indices.contains(index) else { return }
        if timerPresets[index].name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            timerPresets[index].name = timerModeTitle(timerPresets[index].mode)
        }
        if timerPresets[index].segments.isEmpty {
            timerPresets[index].segments = [
                TimerSegment(title: timerModeTitle(timerPresets[index].mode), duration: 25 * 60, phase: .focus)
            ]
        }
        for segmentIndex in timerPresets[index].segments.indices {
            if timerPresets[index].mode == .stopwatch {
                timerPresets[index].segments[segmentIndex].duration = max(0, timerPresets[index].segments[segmentIndex].duration)
            } else {
                timerPresets[index].segments[segmentIndex].duration = max(60, timerPresets[index].segments[segmentIndex].duration)
            }
            if timerPresets[index].segments[segmentIndex].title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                timerPresets[index].segments[segmentIndex].title = phaseTitle(timerPresets[index].segments[segmentIndex].phase)
            }
        }
    }

    private static func sanitizedStarterState(_ persisted: FocusGlassPersistedState) -> FocusGlassPersistedState {
        let starterProjectNames = legacyStarterProjectNames
        let starterTaskTitles = legacyStarterTaskTitles
        let starterIntentions = legacyStarterIntentions
        let shouldCleanLegacyPlaceholders = persisted.schemaVersion == nil
        let placeholderProjectNames: Set<String> = ["Новый проект", "New Project"]
        let placeholderProjectDetails: Set<String> = ["Описание проекта", "Project description"]

        let removedProjectNames = Set(
            persisted.projects
                .filter { project in
                    starterProjectNames.contains(project.name)
                        || (
                            shouldCleanLegacyPlaceholders
                            && placeholderProjectNames.contains(project.name)
                            && placeholderProjectDetails.contains(project.detail)
                        )
                }
                .map(\.name)
        )

        var projects = persisted.projects.filter { !removedProjectNames.contains($0.name) }
        let projectsByName = Dictionary(uniqueKeysWithValues: projects.map { ($0.name, $0.id) })
        let projectNames = Set(projects.map(\.name))
        let tasks = persisted.tasks.filter { task in
            !starterTaskTitles.contains(task.title) && !removedProjectNames.contains(task.projectName)
        }.map { task in
            var migrated = task
            if migrated.projectID == nil {
                migrated.projectID = projectsByName[migrated.projectName]
            }
            if let projectID = migrated.projectID,
               let project = projects.first(where: { $0.id == projectID }) {
                migrated.projectName = project.name
            } else {
                migrated.projectName = ""
            }
            return migrated
        }
        let sessions = persisted.recentSessions.filter { session in
            !removedProjectNames.contains(session.projectName)
        }.map { session in
            var migrated = session
            if migrated.projectID == nil {
                migrated.projectID = projectsByName[migrated.projectName]
            }
            if let projectID = migrated.projectID,
               let project = projects.first(where: { $0.id == projectID }) {
                migrated.projectName = project.name
            } else if !projectNames.contains(migrated.projectName) {
                migrated.projectName = ""
            }
            return migrated
        }
        let distractionRules = persisted.distractionRules.filter { rule in
            !["Telegram", "YouTube in browser", "Discord"].contains(rule.label)
        }

        let persistedActiveProjectID = persisted.activeProjectID.flatMap { id in
            projects.contains { $0.id == id } ? id : nil
        }
        let activeProjectID = persistedActiveProjectID
            ?? (projectNames.contains(persisted.activeProject) ? projectsByName[persisted.activeProject] : nil)
            ?? projects.first?.id
        let activeProject = activeProjectID.flatMap { id in projects.first { $0.id == id }?.name } ?? ""
        let activeTaskID = persisted.activeTaskID.flatMap { id in
            tasks.contains { $0.id == id && !$0.isDone && $0.projectID == activeProjectID } ? id : nil
        }
        let legacyIntention = starterIntentions.contains(persisted.intention)
            ? ""
            : persisted.intention.trimmingCharacters(in: .whitespacesAndNewlines)
        var intention = legacyIntention
        if !legacyIntention.isEmpty,
           let activeProjectID,
           let index = projects.firstIndex(where: { $0.id == activeProjectID }),
           projects[index].notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            projects[index].notes = legacyIntention
            intention = ""
        }

        return FocusGlassPersistedState(
            schemaVersion: 5,
            selectedThemeID: persisted.selectedThemeID,
            themeProfiles: persisted.themeProfiles,
            selectedPresetID: persisted.selectedPresetID,
            timerPresets: persisted.timerPresets,
            language: persisted.language,
            appearanceMode: persisted.appearanceMode,
            strictModeEnabled: persisted.strictModeEnabled,
            strictModeEnforcesDuringBreaks: persisted.strictModeEnforcesDuringBreaks,
            hasSeenPermissionsOnboarding: persisted.hasSeenPermissionsOnboarding,
            intention: intention,
            activeProjectID: activeProjectID,
            activeTaskID: activeTaskID,
            activeProject: activeProject,
            projects: projects,
            tasks: tasks,
            distractionRules: distractionRules,
            distractionHistory: persisted.distractionHistory,
            recentSessions: sessions
        )
    }

    private static let legacyStarterProjectNames: Set<String> = [
        "Стажировка",
        "Учеба",
        "Личное",
        "Internship",
        "Study",
        "Personal"
    ]

    private static let legacyStarterTaskTitles: Set<String> = [
        "Закончить ревью авторизации",
        "Доработать сохранение сессий",
        "Записать заметки по стажировке",
        "Finish authentication review",
        "Refactor session persistence",
        "Write internship notes"
    ]

    private static let legacyStarterIntentions: Set<String> = [
        "Закончить ревью авторизации",
        "Finish authentication review"
    ]
}

enum SidebarItem: String, CaseIterable, Identifiable {
    case focusToday
    case projects
    case analytics
    case strictMode
    case settings

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .focusToday: "sidebar.focusToday"
        case .projects: "sidebar.projects"
        case .analytics: "sidebar.analytics"
        case .strictMode: "sidebar.strictMode"
        case .settings: "sidebar.settings"
        }
    }

    var symbolName: String {
        switch self {
        case .focusToday: "scope"
        case .projects: "folder"
        case .analytics: "chart.xyaxis.line"
        case .strictMode: "shield"
        case .settings: "gearshape"
        }
    }
}

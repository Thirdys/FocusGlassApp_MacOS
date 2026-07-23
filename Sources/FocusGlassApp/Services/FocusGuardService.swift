import AppKit
import ApplicationServices
import Foundation
import ServiceManagement
@preconcurrency import UserNotifications
import FocusGlassCore

@MainActor
final class FocusGuardService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published private(set) var permissionStates: [FocusPermission: FocusPermissionStatus] = Dictionary(
        uniqueKeysWithValues: FocusPermission.allCases.map { ($0, .unknown) }
    )
    @Published private(set) var lastDistractionMessage: String?
    @Published private(set) var lastPermissionMessage: String?
    @Published private(set) var lastAutomationMessage: String?

    private let automationProbeKey = "FocusGlass.AutomationProbeSucceeded"
    private var lastDistractionSignature: String?
    private var lastDistractionAt: Date?
    private var language: AppLanguage = .ru

    override init() {
        super.init()
        if Bundle.main.bundleURL.pathExtension == "app" {
            UNUserNotificationCenter.current().delegate = self
        }
    }

    var canUseUserNotifications: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge, .list])
    }

    var isAppBundle: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }

    func status(for permission: FocusPermission) -> FocusPermissionStatus {
        permissionStates[permission] ?? .unknown
    }

    func setLanguage(_ language: AppLanguage) {
        self.language = language
    }

    func refreshPermissionStates() {
        permissionStates[.accessibility] = isAppBundle
            ? (AXIsProcessTrusted() ? .granted : .missing)
            : .unavailable
        permissionStates[.automation] = isAppBundle
            ? (UserDefaults.standard.bool(forKey: automationProbeKey) ? .granted : .unknown)
            : .unavailable
        refreshLaunchAtLoginStatus()

        guard canUseUserNotifications else {
            permissionStates[.notifications] = .unavailable
            return
        }

        Task { [weak self] in
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            await MainActor.run {
                self?.permissionStates[.notifications] = Self.notificationStatus(settings.authorizationStatus)
                self?.clearPermissionMessageIfResolved()
            }
        }
    }

    func requestNotifications() {
        requestNotificationPermissionIfNeeded()
    }

    func requestNotificationPermissionIfNeeded() {
        guard canUseUserNotifications else {
            setUserMessage(localized("permissions.notifications.bundleRequired"))
            permissionStates[.notifications] = .unavailable
            logPermissionIssue(
                code: "notifications.bundle_unavailable",
                message: localized("diagnostics.notifications.bundleUnavailable"),
                details: ["bundlePath": Bundle.main.bundleURL.path],
                hint: localized("diagnostics.notifications.bundleHint")
            )
            return
        }

        permissionStates[.notifications] = .unknown
        Task { [weak self] in
            do {
                let center = UNUserNotificationCenter.current()
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                let settings = await center.notificationSettings()
                await MainActor.run {
                    self?.permissionStates[.notifications] = Self.notificationStatus(settings.authorizationStatus)
                    if self?.permissionStates[.notifications] == .granted {
                        self?.lastPermissionMessage = nil
                    }
                }
                if !granted || settings.authorizationStatus == .denied {
                    await MainActor.run {
                        self?.permissionStates[.notifications] = .missing
                        self?.setUserMessage(self?.localized("permissions.notifications.denied") ?? "")
                        self?.logPermissionIssue(
                            code: "notifications.denied",
                            message: self?.localized("diagnostics.notifications.denied") ?? "Notifications denied",
                            details: ["authorizationStatus": "\(settings.authorizationStatus.rawValue)"],
                            hint: self?.localized("diagnostics.notifications.deniedHint") ?? ""
                        )
                        self?.openNotificationSettings()
                    }
                }
            } catch {
                await MainActor.run {
                    self?.setUserMessage(self?.localized("permissions.notifications.failed") ?? "")
                    self?.permissionStates[.notifications] = .missing
                    self?.logPermissionIssue(
                        code: "notifications.request_failed",
                        message: self?.localized("diagnostics.notifications.failed") ?? "Notification request failed",
                        details: ["error": String(describing: error)],
                        hint: self?.localized("diagnostics.notifications.failedHint") ?? ""
                    )
                    self?.openNotificationSettings()
                }
            }
        }
    }

    func openNotificationSettings() {
        let bundleID = Bundle.main.bundleIdentifier ?? "local.focusglass.app"
        let urls = [
            URL(string: "x-apple.systempreferences:com.apple.preference.notifications?id=\(bundleID)"),
            URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension")
        ]
        if let url = urls.compactMap(\.self).first {
            NSWorkspace.shared.open(url)
        }
    }

    func requestAccessibilityPermission() {
        guard isAppBundle else {
            permissionStates[.accessibility] = .unavailable
            setUserMessage(localized("permissions.accessibility.bundleRequired"))
            logPermissionIssue(
                code: "accessibility.bundle_unavailable",
                message: localized("diagnostics.accessibility.bundleUnavailable"),
                details: ["bundlePath": Bundle.main.bundleURL.path],
                hint: localized("diagnostics.accessibility.bundleHint")
            )
            return
        }

        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        permissionStates[.accessibility] = trusted ? .granted : .missing
        clearPermissionMessageIfResolved()
        openAccessibilitySettings()
    }

    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        if let url {
            NSWorkspace.shared.open(url)
        }
    }

    func requestAutomationPermission() {
        guard isAppBundle else {
            permissionStates[.automation] = .unavailable
            setUserMessage(localized("permissions.automation.bundleRequired"))
            setAutomationMessage(localized("permissions.automation.bundleRequired"))
            logPermissionIssue(
                code: "automation.bundle_unavailable",
                message: localized("diagnostics.automation.bundleUnavailable"),
                details: ["bundlePath": Bundle.main.bundleURL.path],
                hint: localized("diagnostics.automation.bundleHint")
            )
            return
        }

        if runAppleScript(#"tell application "System Events" to get name of first process"#) != nil {
            UserDefaults.standard.set(true, forKey: automationProbeKey)
            permissionStates[.automation] = .granted
            clearPermissionMessageIfResolved()
            setAutomationMessage(localized("automation.access.granted"))
        } else {
            UserDefaults.standard.set(false, forKey: automationProbeKey)
            permissionStates[.automation] = .missing
            setUserMessage(localized("permissions.automation.failed"))
            setAutomationMessage(localized("automation.access.failed"))
            logPermissionIssue(
                code: "automation.probe_failed",
                message: localized("diagnostics.automation.failed"),
                details: ["probe": "System Events process name"],
                hint: localized("diagnostics.automation.failedHint")
            )
        }
    }

    func toggleLaunchAtLogin() {
        guard isAppBundle else {
            permissionStates[.launchAtLogin] = .unavailable
            openLoginItemsSettings()
            return
        }

        do {
            switch SMAppService.mainApp.status {
            case .enabled:
                try SMAppService.mainApp.unregister()
            default:
                try SMAppService.mainApp.register()
            }
        } catch {
            setUserMessage(localized("permissions.launchAtLogin.failed"))
            logPermissionIssue(
                code: "launch_at_login.failed",
                message: localized("diagnostics.launchAtLogin.failed"),
                details: ["error": String(describing: error), "status": "\(SMAppService.mainApp.status.rawValue)"],
                hint: localized("diagnostics.launchAtLogin.failedHint")
            )
            openLoginItemsSettings()
        }
        refreshLaunchAtLoginStatus()
        clearPermissionMessageIfResolved()
    }

    func openLoginItemsSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")
        if let url {
            NSWorkspace.shared.open(url)
        }
    }

    func sendSessionNotification(title: String, body: String) {
        guard canUseUserNotifications else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        Task {
            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                await MainActor.run {
                    FocusGlassDiagnosticsLogger.shared.log(
                        .error,
                        subsystem: "notifications",
                        code: "notifications.delivery_failed",
                        message: self.localized("diagnostics.notifications.deliveryFailed"),
                        details: ["title": title, "body": body, "error": String(describing: error)],
                        resolutionHint: self.localized("diagnostics.notifications.deliveryHint")
                    )
                }
            }
        }
    }

    func runShortcut(named name: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["run", name]
        process.terminationHandler = { [weak self] finishedProcess in
            Task { @MainActor in
                guard let self else { return }
                if finishedProcess.terminationStatus == 0 {
                    self.setAutomationMessage(
                        String(format: self.localized("automation.shortcut.completed"), name)
                    )
                } else {
                    self.setAutomationMessage(
                        String(format: self.localized("automation.shortcut.failed"), name)
                    )
                }
            }
        }

        do {
            try process.run()
            setAutomationMessage(String(format: localized("automation.shortcut.started"), name))
        } catch {
            setAutomationMessage(String(format: localized("automation.shortcut.failed"), name))
            FocusGlassDiagnosticsLogger.shared.log(
                .warning,
                subsystem: "automation",
                code: "shortcuts.launch_failed",
                message: localized("diagnostics.automation.shortcutLaunchFailed"),
                details: ["shortcut": name, "error": String(describing: error)],
                resolutionHint: localized("diagnostics.automation.shortcutLaunchHint")
            )
        }
    }

    func activeDistractionRule(from rules: [DistractionRuleSpec]) -> DistractionRuleSpec? {
        guard let app = NSWorkspace.shared.frontmostApplication,
              app.bundleIdentifier != Bundle.main.bundleIdentifier else { return nil }

        if let appRule = rules.first(where: { $0.matches(bundleIdentifier: app.bundleIdentifier) }) {
            return appRule
        }

        guard let urlString = activeBrowserURL(for: app) else { return nil }
        return rules.first { $0.matches(siteURL: urlString) }
    }

    @discardableResult
    func handleDistraction(rule: DistractionRuleSpec) -> Bool {
        let signature = "\(rule.id.uuidString)-\(rule.matchValue)"
        if let lastDistractionAt,
           lastDistractionSignature == signature,
           Date().timeIntervalSince(lastDistractionAt) < 8 {
            return false
        }

        lastDistractionSignature = signature
        lastDistractionAt = .now

        switch rule.effectiveAction {
        case .warn:
            lastDistractionMessage = String(format: localized("strict.warning.message"), rule.label)
            sendSessionNotification(
                title: "FocusGlass",
                body: String(format: localized("strict.notification.warn"), rule.label)
            )
        case .hide:
            lastDistractionMessage = String(format: localized("strict.blocked.message"), rule.label)
            sendSessionNotification(
                title: "FocusGlass",
                body: String(format: localized("strict.notification.hide"), rule.label)
            )
            hide(rule: rule)
        case .pauseSession:
            lastDistractionMessage = String(format: localized("strict.notification.paused.body"), rule.label)
            sendSessionNotification(
                title: localized("strict.notification.paused.title"),
                body: String(format: localized("strict.notification.paused.body"), rule.label)
            )
        case .quitAfterOptIn:
            lastDistractionMessage = String(format: localized("strict.quit.message"), rule.label)
            terminate(rule: rule)
        }

        NSApplication.shared.activate(ignoringOtherApps: true)
        return true
    }

    private static func notificationStatus(_ status: UNAuthorizationStatus) -> FocusPermissionStatus {
        switch status {
        case .authorized, .provisional, .ephemeral:
            .granted
        case .denied, .notDetermined:
            .missing
        @unknown default:
            .unknown
        }
    }

    private func refreshLaunchAtLoginStatus() {
        guard isAppBundle else {
            permissionStates[.launchAtLogin] = .unavailable
            return
        }

        switch SMAppService.mainApp.status {
        case .enabled:
            permissionStates[.launchAtLogin] = .granted
        case .notRegistered, .requiresApproval, .notFound:
            permissionStates[.launchAtLogin] = .missing
        @unknown default:
            permissionStates[.launchAtLogin] = .unknown
        }
    }

    private func hide(rule: DistractionRuleSpec) {
        switch rule.targetKind {
        case .app:
            NSWorkspace.shared.runningApplications
                .filter { rule.matches(bundleIdentifier: $0.bundleIdentifier) }
                .forEach { $0.hide() }
        case .site:
            NSWorkspace.shared.frontmostApplication?.hide()
        }
    }

    private func terminate(rule: DistractionRuleSpec) {
        guard rule.targetKind == .app else {
            hide(rule: rule)
            return
        }

        NSWorkspace.shared.runningApplications
            .filter { rule.matches(bundleIdentifier: $0.bundleIdentifier) }
            .forEach { $0.terminate() }
    }

    private func activeBrowserURL(for app: NSRunningApplication) -> String? {
        guard let bundleIdentifier = app.bundleIdentifier else { return nil }
        switch bundleIdentifier {
        case "com.apple.Safari":
            return runAppleScript(#"tell application id "com.apple.Safari" to if (count of windows) > 0 then return URL of current tab of front window"#)
        case "com.google.Chrome":
            return runAppleScript(#"tell application id "com.google.Chrome" to if (count of windows) > 0 then return URL of active tab of front window"#)
        case "company.thebrowser.Browser":
            return runAppleScript(#"tell application id "company.thebrowser.Browser" to if (count of windows) > 0 then return URL of active tab of front window"#)
        case "com.microsoft.edgemac":
            return runAppleScript(#"tell application id "com.microsoft.edgemac" to if (count of windows) > 0 then return URL of active tab of front window"#)
        default:
            return nil
        }
    }

    private func runAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let descriptor = script.executeAndReturnError(&error)
        guard error == nil else { return nil }
        return descriptor.stringValue
    }

    private func localized(_ key: String) -> String {
        L10n.string(key, language: language)
    }

    private func setUserMessage(_ message: String) {
        guard !message.isEmpty else { return }
        lastPermissionMessage = message
    }

    private func setAutomationMessage(_ message: String) {
        guard !message.isEmpty else { return }
        lastAutomationMessage = message
    }

    private func clearPermissionMessageIfResolved() {
        let criticalPermissions: [FocusPermission] = [.notifications, .accessibility, .automation]
        if !criticalPermissions.contains(where: { permissionStates[$0]?.needsUserAction == true }) {
            lastPermissionMessage = nil
        }
    }

    private func logPermissionIssue(code: String, message: String, details: [String: String], hint: String) {
        FocusGlassDiagnosticsLogger.shared.log(
            .warning,
            subsystem: "permissions",
            code: code,
            message: message,
            details: details,
            resolutionHint: hint
        )
    }
}

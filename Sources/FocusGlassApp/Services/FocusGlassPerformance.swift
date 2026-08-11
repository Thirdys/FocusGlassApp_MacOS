import os

enum FocusGlassPerformance {
    private static let log = OSLog(
        subsystem: "com.thirdys.FocusGlass",
        category: .pointsOfInterest
    )

    static func routeChanged(_ route: String) {
        event("RouteChanged", value: route)
    }

    static func settingsTabChanged(_ tab: String) {
        event("SettingsTabChanged", value: tab)
    }

    static func themeCommitted(reason: String) {
        event("ThemeCommitted", value: reason)
    }

    static func menuPanelChanged(isVisible: Bool) {
        event("MenuPanelChanged", value: isVisible ? "shown" : "hidden")
    }

    static func outcomeChanged(isPresented: Bool) {
        event("OutcomeChanged", value: isPresented ? "presented" : "dismissed")
    }

    private static func event(_ name: StaticString, value: String) {
        os_signpost(.event, log: log, name: name, "%{public}@", value)
    }
}

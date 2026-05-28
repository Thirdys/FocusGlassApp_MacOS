import Foundation

public enum ThemeMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case system
    case light
    case dark
    case graphiteGlass
    case aurora
    case forest
    case solar
    case midnight

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        case .graphiteGlass: "Graphite Glass"
        case .aurora: "Aurora"
        case .forest: "Forest"
        case .solar: "Solar"
        case .midnight: "Midnight"
        }
    }
}

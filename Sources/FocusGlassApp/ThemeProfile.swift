import AppKit
import SwiftUI

enum AppLanguage: String, CaseIterable, Codable, Identifiable {
    case ru
    case en
    case system

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ru: "Русский"
        case .en: "English"
        case .system: "Системный"
        }
    }

    var resolvedCode: String {
        switch self {
        case .ru: "ru"
        case .en: "en"
        case .system:
            Locale.preferredLanguages.first?.hasPrefix("ru") == true ? "ru" : "en"
        }
    }
}

enum AppAppearanceMode: String, CaseIterable, Codable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
}

enum AppResolvedAppearance: String, Codable, Equatable {
    case light
    case dark

    @MainActor
    static var current: AppResolvedAppearance {
        let match = NSApplication.shared.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua])
        return match == .aqua ? .light : .dark
    }
}

struct ThemeProfile: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var isBuiltIn: Bool
    var primaryHex: String
    var secondaryHex: String
    var glowHex: String
    var backgroundTopHex: String
    var backgroundMidHex: String
    var backgroundBottomHex: String
    var surfaceHex: String
    var elevatedSurfaceHex: String
    var textHex: String
    var mutedTextHex: String
    var timerRingStartHex: String
    var timerRingEndHex: String
    var heatmapLowHex: String
    var heatmapHighHex: String
    var strictHex: String
    var highlightHex: String
    var glassOpacity: Double
    var menuGlassOpacity: Double
    var surfaceAlpha: Double
    var highlightAlpha: Double
    var specularOpacity: Double
    var blurIntensity: Double
    var fullscreenGlowIntensity: Double
    var cornerRadius: Double
    var borderOpacity: Double
    var shadowDepth: Double
    var density: Double
    var motion: Double

    init(
        id: UUID = UUID(),
        name: String,
        isBuiltIn: Bool = true,
        primaryHex: String,
        secondaryHex: String,
        glowHex: String,
        backgroundTopHex: String,
        backgroundMidHex: String,
        backgroundBottomHex: String,
        surfaceHex: String,
        elevatedSurfaceHex: String,
        textHex: String = "#f6f8ff",
        mutedTextHex: String = "#aab3c7",
        timerRingStartHex: String,
        timerRingEndHex: String,
        heatmapLowHex: String,
        heatmapHighHex: String,
        strictHex: String,
        highlightHex: String = "#FFFFFF",
        glassOpacity: Double = 0.42,
        menuGlassOpacity: Double = 0.56,
        surfaceAlpha: Double = 0.24,
        highlightAlpha: Double = 0.26,
        specularOpacity: Double = 0.34,
        blurIntensity: Double = 0.72,
        fullscreenGlowIntensity: Double = 0.85,
        cornerRadius: Double = 18,
        borderOpacity: Double = 0.22,
        shadowDepth: Double = 0.30,
        density: Double = 0.55,
        motion: Double = 0.45
    ) {
        self.id = id
        self.name = name
        self.isBuiltIn = isBuiltIn
        self.primaryHex = primaryHex
        self.secondaryHex = secondaryHex
        self.glowHex = glowHex
        self.backgroundTopHex = backgroundTopHex
        self.backgroundMidHex = backgroundMidHex
        self.backgroundBottomHex = backgroundBottomHex
        self.surfaceHex = surfaceHex
        self.elevatedSurfaceHex = elevatedSurfaceHex
        self.textHex = textHex
        self.mutedTextHex = mutedTextHex
        self.timerRingStartHex = timerRingStartHex
        self.timerRingEndHex = timerRingEndHex
        self.heatmapLowHex = heatmapLowHex
        self.heatmapHighHex = heatmapHighHex
        self.strictHex = strictHex
        self.highlightHex = highlightHex
        self.glassOpacity = glassOpacity
        self.menuGlassOpacity = menuGlassOpacity
        self.surfaceAlpha = surfaceAlpha
        self.highlightAlpha = highlightAlpha
        self.specularOpacity = specularOpacity
        self.blurIntensity = blurIntensity
        self.fullscreenGlowIntensity = fullscreenGlowIntensity
        self.cornerRadius = cornerRadius
        self.borderOpacity = borderOpacity
        self.shadowDepth = shadowDepth
        self.density = density
        self.motion = motion
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case isBuiltIn
        case primaryHex
        case secondaryHex
        case glowHex
        case backgroundTopHex
        case backgroundMidHex
        case backgroundBottomHex
        case surfaceHex
        case elevatedSurfaceHex
        case textHex
        case mutedTextHex
        case timerRingStartHex
        case timerRingEndHex
        case heatmapLowHex
        case heatmapHighHex
        case strictHex
        case highlightHex
        case glassOpacity
        case menuGlassOpacity
        case surfaceAlpha
        case highlightAlpha
        case specularOpacity
        case blurIntensity
        case fullscreenGlowIntensity
        case cornerRadius
        case borderOpacity
        case shadowDepth
        case density
        case motion
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.init(
            id: try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID(),
            name: try container.decode(String.self, forKey: .name),
            isBuiltIn: try container.decodeIfPresent(Bool.self, forKey: .isBuiltIn) ?? true,
            primaryHex: try container.decode(String.self, forKey: .primaryHex),
            secondaryHex: try container.decode(String.self, forKey: .secondaryHex),
            glowHex: try container.decode(String.self, forKey: .glowHex),
            backgroundTopHex: try container.decode(String.self, forKey: .backgroundTopHex),
            backgroundMidHex: try container.decode(String.self, forKey: .backgroundMidHex),
            backgroundBottomHex: try container.decode(String.self, forKey: .backgroundBottomHex),
            surfaceHex: try container.decode(String.self, forKey: .surfaceHex),
            elevatedSurfaceHex: try container.decode(String.self, forKey: .elevatedSurfaceHex),
            textHex: try container.decodeIfPresent(String.self, forKey: .textHex) ?? "#f6f8ff",
            mutedTextHex: try container.decodeIfPresent(String.self, forKey: .mutedTextHex) ?? "#aab3c7",
            timerRingStartHex: try container.decode(String.self, forKey: .timerRingStartHex),
            timerRingEndHex: try container.decode(String.self, forKey: .timerRingEndHex),
            heatmapLowHex: try container.decode(String.self, forKey: .heatmapLowHex),
            heatmapHighHex: try container.decode(String.self, forKey: .heatmapHighHex),
            strictHex: try container.decode(String.self, forKey: .strictHex),
            highlightHex: try container.decodeIfPresent(String.self, forKey: .highlightHex) ?? "#FFFFFF",
            glassOpacity: try container.decodeIfPresent(Double.self, forKey: .glassOpacity) ?? 0.42,
            menuGlassOpacity: try container.decodeIfPresent(Double.self, forKey: .menuGlassOpacity) ?? 0.56,
            surfaceAlpha: try container.decodeIfPresent(Double.self, forKey: .surfaceAlpha) ?? 0.24,
            highlightAlpha: try container.decodeIfPresent(Double.self, forKey: .highlightAlpha) ?? 0.26,
            specularOpacity: try container.decodeIfPresent(Double.self, forKey: .specularOpacity) ?? 0.34,
            blurIntensity: try container.decodeIfPresent(Double.self, forKey: .blurIntensity) ?? 0.72,
            fullscreenGlowIntensity: try container.decodeIfPresent(Double.self, forKey: .fullscreenGlowIntensity) ?? 0.85,
            cornerRadius: try container.decodeIfPresent(Double.self, forKey: .cornerRadius) ?? 18,
            borderOpacity: try container.decodeIfPresent(Double.self, forKey: .borderOpacity) ?? 0.22,
            shadowDepth: try container.decodeIfPresent(Double.self, forKey: .shadowDepth) ?? 0.30,
            density: try container.decodeIfPresent(Double.self, forKey: .density) ?? 0.55,
            motion: try container.decodeIfPresent(Double.self, forKey: .motion) ?? 0.45
        )
    }
}

extension ThemeProfile {
    static let graphiteAuroraID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    static let noirCrimsonID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    static let midnightID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    static let paperID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
    static let forestID = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
    static let solarID = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!

    static let builtIn: [ThemeProfile] = [
        ThemeProfile(
            id: graphiteAuroraID,
            name: "Graphite Aurora",
            primaryHex: "#5aa7ff",
            secondaryHex: "#8d6bff",
            glowHex: "#43d5cc",
            backgroundTopHex: "#111827",
            backgroundMidHex: "#152a31",
            backgroundBottomHex: "#090d16",
            surfaceHex: "#182231",
            elevatedSurfaceHex: "#233142",
            timerRingStartHex: "#58a6ff",
            timerRingEndHex: "#9d6cff",
            heatmapLowHex: "#263957",
            heatmapHighHex: "#7f65ff",
            strictHex: "#75e39b",
            glassOpacity: 0.40,
            menuGlassOpacity: 0.54,
            surfaceAlpha: 0.24,
            highlightAlpha: 0.25,
            specularOpacity: 0.34,
            blurIntensity: 0.72,
            fullscreenGlowIntensity: 0.78,
            cornerRadius: 18,
            borderOpacity: 0.23,
            shadowDepth: 0.28
        ),
        ThemeProfile(
            id: noirCrimsonID,
            name: "Noir Crimson",
            primaryHex: "#ff4d57",
            secondaryHex: "#b51f2b",
            glowHex: "#ff7b5d",
            backgroundTopHex: "#09090d",
            backgroundMidHex: "#130b0f",
            backgroundBottomHex: "#030305",
            surfaceHex: "#151217",
            elevatedSurfaceHex: "#21171d",
            timerRingStartHex: "#ff4758",
            timerRingEndHex: "#8f101d",
            heatmapLowHex: "#33161a",
            heatmapHighHex: "#ff515e",
            strictHex: "#ff5b66",
            glassOpacity: 0.38,
            menuGlassOpacity: 0.52,
            surfaceAlpha: 0.22,
            highlightAlpha: 0.32,
            specularOpacity: 0.40,
            blurIntensity: 0.82,
            fullscreenGlowIntensity: 0.92,
            cornerRadius: 18,
            borderOpacity: 0.24,
            shadowDepth: 0.34
        ),
        ThemeProfile(
            id: midnightID,
            name: "Midnight",
            primaryHex: "#7c88ff",
            secondaryHex: "#3b47a8",
            glowHex: "#5ddcff",
            backgroundTopHex: "#070a16",
            backgroundMidHex: "#101733",
            backgroundBottomHex: "#03040a",
            surfaceHex: "#12172a",
            elevatedSurfaceHex: "#1b2340",
            timerRingStartHex: "#6f8cff",
            timerRingEndHex: "#40d5ff",
            heatmapLowHex: "#202b50",
            heatmapHighHex: "#6f8cff",
            strictHex: "#65f0bd"
        ),
        ThemeProfile(
            id: paperID,
            name: "Paper",
            primaryHex: "#377dff",
            secondaryHex: "#705cf6",
            glowHex: "#a7cdfd",
            backgroundTopHex: "#f6f8ff",
            backgroundMidHex: "#edf2fb",
            backgroundBottomHex: "#dce6f5",
            surfaceHex: "#ffffff",
            elevatedSurfaceHex: "#f7f9fe",
            textHex: "#172033",
            mutedTextHex: "#667085",
            timerRingStartHex: "#377dff",
            timerRingEndHex: "#705cf6",
            heatmapLowHex: "#dbe6ff",
            heatmapHighHex: "#377dff",
            strictHex: "#1aaf6c",
            glassOpacity: 0.54,
            menuGlassOpacity: 0.62,
            surfaceAlpha: 0.36,
            highlightAlpha: 0.30,
            specularOpacity: 0.28,
            blurIntensity: 0.56,
            fullscreenGlowIntensity: 0.52,
            shadowDepth: 0.18
        ),
        ThemeProfile(
            id: forestID,
            name: "Forest",
            primaryHex: "#52c878",
            secondaryHex: "#2d7f5e",
            glowHex: "#9af0b8",
            backgroundTopHex: "#07110d",
            backgroundMidHex: "#10231a",
            backgroundBottomHex: "#030705",
            surfaceHex: "#111f18",
            elevatedSurfaceHex: "#1a3024",
            timerRingStartHex: "#52c878",
            timerRingEndHex: "#2da88a",
            heatmapLowHex: "#1c3527",
            heatmapHighHex: "#52c878",
            strictHex: "#66e391"
        ),
        ThemeProfile(
            id: solarID,
            name: "Solar",
            primaryHex: "#ffb454",
            secondaryHex: "#ff7a45",
            glowHex: "#ffe2a8",
            backgroundTopHex: "#17110a",
            backgroundMidHex: "#2a1d10",
            backgroundBottomHex: "#0b0704",
            surfaceHex: "#24190f",
            elevatedSurfaceHex: "#352414",
            timerRingStartHex: "#ffb454",
            timerRingEndHex: "#ff7a45",
            heatmapLowHex: "#422813",
            heatmapHighHex: "#ffb454",
            strictHex: "#74e69b"
        )
    ]

    var primary: Color { Color(hex: primaryHex) }
    var accent: Color { primary }
    var secondary: Color { Color(hex: secondaryHex) }
    var glow: Color { Color(hex: glowHex) }
    var surface: Color { Color(hex: surfaceHex) }
    var elevatedSurface: Color { Color(hex: elevatedSurfaceHex) }
    var text: Color { Color(hex: textHex) }
    var mutedText: Color { Color(hex: mutedTextHex) }
    var strict: Color { Color(hex: strictHex) }
    var highlight: Color { Color(hex: highlightHex) }

    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: backgroundTopHex), Color(hex: backgroundMidHex), Color(hex: backgroundBottomHex)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var background: LinearGradient { backgroundGradient }

    var ringGradient: AngularGradient {
        AngularGradient(
            colors: [Color(hex: timerRingStartHex), Color(hex: glowHex), Color(hex: timerRingEndHex), Color(hex: timerRingStartHex)],
            center: .center
        )
    }

    var colorScheme: ColorScheme? {
        luminance(of: backgroundTopHex) > 0.65 ? .light : .dark
    }

    func adapted(to appearance: AppResolvedAppearance) -> ThemeProfile {
        var profile = self
        switch appearance {
        case .light:
            let adaptedPrimary = NSColor(hex: primaryHex).mixed(with: NSColor(hex: "#4f8cff"), fraction: 0.24).lightModeAccent()
            let adaptedSecondary = NSColor(hex: secondaryHex).mixed(with: NSColor(hex: "#8f7cff"), fraction: 0.30).lightModeAccent()
            let adaptedGlow = adaptedPrimary.mixed(with: NSColor(hex: "#ffffff"), fraction: 0.54)
            profile.primaryHex = adaptedPrimary.hexString
            profile.secondaryHex = adaptedSecondary.hexString
            profile.glowHex = adaptedGlow.hexString
            profile.timerRingStartHex = adaptedPrimary.hexString
            profile.timerRingEndHex = adaptedSecondary.hexString
            profile.backgroundTopHex = "#f8faff"
            profile.backgroundMidHex = "#edf4fb"
            profile.backgroundBottomHex = "#dfe9f5"
            profile.surfaceHex = "#ffffff"
            profile.elevatedSurfaceHex = "#f7faff"
            profile.textHex = "#172033"
            profile.mutedTextHex = "#5f6d82"
            profile.glassOpacity = max(profile.glassOpacity, 0.50)
            profile.menuGlassOpacity = max(profile.menuGlassOpacity, 0.60)
            profile.surfaceAlpha = max(profile.surfaceAlpha, 0.30)
            profile.highlightAlpha = min(max(profile.highlightAlpha, 0.22), 0.31)
            profile.specularOpacity = min(max(profile.specularOpacity, 0.22), 0.34)
            profile.blurIntensity = min(profile.blurIntensity, 0.62)
            profile.shadowDepth = min(profile.shadowDepth, 0.17)
        case .dark:
            profile.backgroundTopHex = "#09090d"
            profile.backgroundMidHex = "#130d12"
            profile.backgroundBottomHex = "#030305"
            profile.surfaceHex = "#151217"
            profile.elevatedSurfaceHex = "#21191f"
            profile.textHex = "#f6f8ff"
            profile.mutedTextHex = "#aab3c7"
            profile.glassOpacity = min(profile.glassOpacity, 0.44)
            profile.menuGlassOpacity = min(profile.menuGlassOpacity, 0.58)
            profile.surfaceAlpha = min(profile.surfaceAlpha, 0.28)
            profile.highlightAlpha = max(profile.highlightAlpha, 0.24)
            profile.specularOpacity = max(profile.specularOpacity, 0.30)
            profile.blurIntensity = max(profile.blurIntensity, 0.72)
            profile.shadowDepth = max(profile.shadowDepth, 0.28)
        }
        return profile
    }

    private func luminance(of hex: String) -> Double {
        let c = NSColor(hex: hex)
        guard let rgb = c.usingColorSpace(.sRGB) else { return 0 }
        return 0.2126 * Double(rgb.redComponent) + 0.7152 * Double(rgb.greenComponent) + 0.0722 * Double(rgb.blueComponent)
    }
}

extension Color {
    init(hex: String) {
        self.init(nsColor: NSColor(hex: hex))
    }
}

extension NSColor {
    func mixed(with other: NSColor, fraction: CGFloat) -> NSColor {
        let amount = min(1, max(0, fraction))
        guard let first = usingColorSpace(.sRGB), let second = other.usingColorSpace(.sRGB) else {
            return self
        }

        return NSColor(
            srgbRed: first.redComponent * (1 - amount) + second.redComponent * amount,
            green: first.greenComponent * (1 - amount) + second.greenComponent * amount,
            blue: first.blueComponent * (1 - amount) + second.blueComponent * amount,
            alpha: 1
        )
    }

    func lightModeAccent() -> NSColor {
        guard let rgb = usingColorSpace(.sRGB) else { return self }
        let minimumBrightness: CGFloat = 0.30
        let maximumBrightness: CGFloat = 0.68
        let red = min(max(rgb.redComponent, minimumBrightness), maximumBrightness)
        let green = min(max(rgb.greenComponent, minimumBrightness), maximumBrightness)
        let blue = min(max(rgb.blueComponent, minimumBrightness), maximumBrightness)
        return NSColor(srgbRed: red, green: green, blue: blue, alpha: 1)
    }

    convenience init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let r: UInt64
        let g: UInt64
        let b: UInt64

        switch cleaned.count {
        case 3:
            r = ((value >> 8) & 0xF) * 17
            g = ((value >> 4) & 0xF) * 17
            b = (value & 0xF) * 17
        default:
            r = (value >> 16) & 0xFF
            g = (value >> 8) & 0xFF
            b = value & 0xFF
        }

        let divisor = CGFloat(255)
        let red = CGFloat(r) / divisor
        let green = CGFloat(g) / divisor
        let blue = CGFloat(b) / divisor

        self.init(
            srgbRed: red,
            green: green,
            blue: blue,
            alpha: 1
        )
    }

    var hexString: String {
        guard let rgb = usingColorSpace(.sRGB) else { return "#ffffff" }
        let r = Int(round(rgb.redComponent * 255))
        let g = Int(round(rgb.greenComponent * 255))
        let b = Int(round(rgb.blueComponent * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

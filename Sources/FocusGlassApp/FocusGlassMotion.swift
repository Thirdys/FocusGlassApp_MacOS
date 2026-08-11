import SwiftUI

enum FocusGlassMotionToken: CaseIterable {
    case micro
    case selection
    case disclosure
    case navigation
    case emphasis
    case progress

    fileprivate var baseDuration: Double {
        switch self {
        case .micro: 0.12
        case .selection: 0.18
        case .disclosure: 0.24
        case .navigation: 0.28
        case .emphasis: 0.36
        case .progress: 0.30
        }
    }
}

enum FocusGlassTransitionStyle {
    case content
    case disclosure
    case listItem
    case toast
    case emphasis
}

struct FocusGlassMotion: Equatable {
    let durationScale: Double
    let reduceMotion: Bool

    init(durationScale: Double = 1, reduceMotion: Bool = false) {
        self.durationScale = min(1.15, max(0.80, durationScale))
        self.reduceMotion = reduceMotion
    }

    init(theme: ThemeProfile, reduceMotion: Bool) {
        self.init(durationScale: theme.motionDurationScale, reduceMotion: reduceMotion)
    }

    var allowsSpatialMotion: Bool {
        !reduceMotion
    }

    func duration(_ token: FocusGlassMotionToken) -> Double {
        if reduceMotion {
            return token == .progress ? 0 : 0.12
        }
        return token.baseDuration * durationScale
    }

    func animation(_ token: FocusGlassMotionToken) -> Animation? {
        if reduceMotion {
            return token == .progress ? nil : .easeOut(duration: duration(token))
        }

        if token == .progress {
            return .linear(duration: duration(token))
        }

        return .timingCurve(
            0.20,
            0,
            0,
            1,
            duration: duration(token)
        )
    }

    func transition(_ style: FocusGlassTransitionStyle) -> AnyTransition {
        guard allowsSpatialMotion else { return .opacity }

        return switch style {
        case .content:
            .asymmetric(
                insertion: .opacity.combined(with: .offset(y: 6)),
                removal: .opacity.combined(with: .offset(y: -3))
            )
        case .disclosure:
            .asymmetric(
                insertion: .opacity.combined(with: .offset(y: -4)),
                removal: .opacity
            )
        case .listItem:
            .asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.985)),
                removal: .opacity
            )
        case .toast:
            .asymmetric(
                insertion: .opacity
                    .combined(with: .offset(y: 10))
                    .combined(with: .scale(scale: 0.985)),
                removal: .opacity.combined(with: .offset(y: 6))
            )
        case .emphasis:
            .opacity.combined(with: .scale(scale: 0.985))
        }
    }
}

private struct FocusGlassMotionEnvironmentKey: EnvironmentKey {
    static let defaultValue = FocusGlassMotion()
}

extension EnvironmentValues {
    var focusGlassMotion: FocusGlassMotion {
        get { self[FocusGlassMotionEnvironmentKey.self] }
        set { self[FocusGlassMotionEnvironmentKey.self] = newValue }
    }
}

private struct FocusGlassMotionScopeModifier: ViewModifier {
    let theme: ThemeProfile
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.environment(
            \.focusGlassMotion,
            FocusGlassMotion(theme: theme, reduceMotion: reduceMotion)
        )
    }
}

extension View {
    func focusGlassMotionScope(theme: ThemeProfile) -> some View {
        modifier(FocusGlassMotionScopeModifier(theme: theme))
    }
}

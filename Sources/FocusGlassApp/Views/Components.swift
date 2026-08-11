import AppKit
import SwiftUI
import FocusGlassCore

enum LiquidGlassDepth {
    case primary
    case secondary
    case floating
}

struct LiquidGlassPanel<Content: View>: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    var radius: CGFloat?
    var padding: CGFloat
    var depth: LiquidGlassDepth
    var content: Content

    init(
        radius: CGFloat? = nil,
        padding: CGFloat = 18,
        depth: LiquidGlassDepth = .primary,
        @ViewBuilder content: () -> Content
    ) {
        self.radius = radius
        self.padding = padding
        self.depth = depth
        self.content = content()
    }

    var body: some View {
        let resolvedRadius = radius ?? CGFloat(model.theme.cornerRadius)

        content
            .padding(model.theme.spacing(padding))
            .background {
                LiquidGlassPanelBackground(
                    theme: model.theme,
                    radius: resolvedRadius,
                    depth: depth,
                    fillOpacity: fillOpacity,
                    topLightOpacity: topLightOpacity,
                    bottomShadeOpacity: bottomShadeOpacity,
                    readabilityScrimOpacity: readabilityScrimOpacity,
                    glintMultiplier: glintMultiplier,
                    strokeMultiplier: strokeMultiplier,
                    material: material
                )
            }
            .shadow(
                color: Color.black.opacity(model.theme.shadowDepth),
                radius: shadowRadius,
                x: 0,
                y: shadowY
            )
            .shadow(
                color: model.theme.glow.opacity(model.theme.specularOpacity * glowShadowOpacity),
                radius: glowShadowRadius,
                x: -4,
                y: 0
            )
    }

    private var material: Material {
        switch depth {
        case .primary: .regularMaterial
        case .secondary: .thinMaterial
        case .floating: .ultraThinMaterial
        }
    }

    private var fillOpacity: Double {
        switch depth {
        case .primary: model.theme.resolvedSurfaceAlpha * 1.10
        case .secondary: model.theme.resolvedSurfaceAlpha * 0.82
        case .floating: max(model.theme.menuGlassOpacity * model.theme.glassStrength, model.theme.resolvedSurfaceAlpha)
        }
    }

    private var topLightOpacity: Double {
        switch depth {
        case .primary: model.theme.highlightAlpha * 0.36
        case .secondary: model.theme.highlightAlpha * 0.25
        case .floating: model.theme.highlightAlpha * 0.44
        }
    }

    private var bottomShadeOpacity: Double {
        switch depth {
        case .primary: model.theme.shadowDepth * 0.28
        case .secondary: model.theme.shadowDepth * 0.18
        case .floating: model.theme.shadowDepth * 0.24
        }
    }

    private var readabilityScrimOpacity: Double {
        switch depth {
        case .primary: 0.10 + model.theme.surfaceAlpha * 0.18
        case .secondary: 0.07 + model.theme.surfaceAlpha * 0.12
        case .floating: 0.12 + model.theme.menuGlassOpacity * 0.10
        }
    }

    private var glintMultiplier: Double {
        switch depth {
        case .primary: 1.0
        case .secondary: 0.72
        case .floating: 1.18
        }
    }

    private var strokeMultiplier: Double {
        switch depth {
        case .primary: 1.0
        case .secondary: 0.72
        case .floating: 1.18
        }
    }

    private var shadowRadius: Double {
        switch depth {
        case .primary: 18 + 18 * model.theme.blurIntensity
        case .secondary: 10 + 10 * model.theme.blurIntensity
        case .floating: 22 + 18 * model.theme.blurIntensity
        }
    }

    private var shadowY: Double {
        switch depth {
        case .primary: 18
        case .secondary: 10
        case .floating: 20
        }
    }

    private var glowShadowOpacity: Double {
        switch depth {
        case .primary: 0.14
        case .secondary: 0.07
        case .floating: 0.18
        }
    }

    private var glowShadowRadius: Double {
        switch depth {
        case .primary: 20 * model.theme.blurIntensity
        case .secondary: 10 * model.theme.blurIntensity
        case .floating: 24 * model.theme.blurIntensity
        }
    }

}

private struct LiquidGlassPanelBackground: View {
    let theme: ThemeProfile
    let radius: CGFloat
    let depth: LiquidGlassDepth
    let fillOpacity: Double
    let topLightOpacity: Double
    let bottomShadeOpacity: Double
    let readabilityScrimOpacity: Double
    let glintMultiplier: Double
    let strokeMultiplier: Double
    let material: Material

    var body: some View {
        ZStack {
            baseFill
            readabilityLayer
            glintLayer
            topSpecularLine
            outerStroke
            innerShadeStroke
        }
        .clipShape(panelShape)
        .allowsHitTesting(false)
    }

    private var panelShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }

    private var baseFill: some View {
        panelShape
            .fill(
                LinearGradient(
                    colors: [
                        theme.highlight.opacity(topLightOpacity),
                        theme.elevatedSurface.opacity(fillOpacity),
                        theme.surface.opacity(fillOpacity * 0.86),
                        Color.black.opacity(bottomShadeOpacity)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .background(panelShape.fill(material))
    }

    private var readabilityLayer: some View {
        panelShape
            .fill(theme.background.opacity(readabilityScrimOpacity))
    }

    private var glintLayer: some View {
        panelShape
            .fill(
                LinearGradient(
                    colors: [
                        theme.highlight.opacity(theme.highlightAlpha * glintMultiplier),
                        theme.glow.opacity(theme.highlightAlpha * 0.18 * glintMultiplier),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .opacity(0.92)
    }

    private var topSpecularLine: some View {
        VStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            theme.highlight.opacity(theme.specularOpacity * 0.46 * glintMultiplier),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1.2)
                .padding(.horizontal, radius * 0.72)
                .padding(.top, 1)
            Spacer(minLength: 0)
        }
    }

    private var outerStroke: some View {
        panelShape
            .stroke(
                LinearGradient(
                    colors: [
                        theme.highlight.opacity(theme.specularOpacity * strokeMultiplier),
                        theme.glow.opacity(theme.specularOpacity * 0.22 * strokeMultiplier),
                        theme.highlight.opacity(theme.borderOpacity * 0.18),
                        Color.black.opacity(theme.shadowDepth * 0.34)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }

    private var innerShadeStroke: some View {
        panelShape
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(theme.shadowDepth * 0.22),
                        Color.black.opacity(theme.shadowDepth * 0.36)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.7
            )
    }
}

struct LiquidGlassButtonStyle: ButtonStyle {
    enum Variant {
        case primary
        case secondary
        case icon
        case danger
    }

    let theme: ThemeProfile
    var variant: Variant = .secondary

    func makeBody(configuration: Configuration) -> some View {
        LiquidGlassButtonBody(
            configuration: configuration,
            theme: theme,
            variant: variant
        )
    }

    private struct LiquidGlassButtonBody: View {
        let configuration: Configuration
        let theme: ThemeProfile
        let variant: Variant

        @State private var isHovering = false
        @Environment(\.isFocused) private var isFocused
        @Environment(\.focusGlassIsScrolling) private var isScrolling
        @Environment(\.focusGlassMotion) private var motion

        var body: some View {
            let pressed = configuration.isPressed
            let hovered = isHovering

            configuration.label
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(foreground)
            .padding(.horizontal, theme.spacing(horizontalPadding))
            .padding(.vertical, theme.spacing(verticalPadding))
            .frame(minHeight: FocusGlassHitTarget.compact)
            .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .background(background(isPressed: pressed, isHovering: hovered), in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(.thinMaterial)
            )
            .overlay(alignment: .topLeading) {
                LinearGradient(
                    colors: [
                        theme.highlight.opacity(theme.highlightAlpha * (pressed ? 0.44 : (hovered ? 1.18 : 0.92))),
                        theme.glow.opacity(theme.highlightAlpha * (pressed ? 0.04 : (hovered ? 0.24 : 0.14))),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                .blendMode(.screen)
                .allowsHitTesting(false)
            }
            .overlay(alignment: .top) {
                Capsule()
                    .fill(theme.highlight.opacity(theme.specularOpacity * (pressed ? 0.20 : (hovered ? 0.52 : 0.38))))
                    .frame(height: 1)
                    .padding(.horizontal, radius * 0.62)
                    .padding(.top, 1)
                    .allowsHitTesting(false)
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(
                        isFocused ? theme.primary.opacity(0.92) : stroke(isPressed: pressed, isHovering: hovered),
                        lineWidth: isFocused ? 2 : 1
                    )
            }
            .shadow(
                color: isFocused ? theme.primary.opacity(0.30) : shadow(isPressed: pressed, isHovering: hovered),
                radius: isFocused ? 14 : (pressed ? 5 : (variant == .primary ? (hovered ? 22 : 18) : (hovered ? 13 : 10))),
                x: 0,
                y: pressed ? 3 : (hovered ? 9 : 8)
            )
            .scaleEffect(pressed ? 0.985 : (hovered ? 1.008 : 1))
            .brightness(pressed ? -0.025 : (hovered ? 0.018 : 0))
            .onHover { hovering in
                if isScrolling {
                    isHovering = hovering
                } else {
                    withAnimation(motion.animation(.micro)) {
                        isHovering = hovering
                    }
                }
            }
            .animation(motion.animation(.selection), value: pressed)
            .animation(isScrolling ? nil : motion.animation(.micro), value: isHovering)
        }

        private var foreground: Color {
            switch variant {
            case .primary, .danger: .white
            case .secondary, .icon: theme.text
            }
        }

        private func background(isPressed: Bool, isHovering: Bool) -> LinearGradient {
            let pressShade = isPressed ? 0.82 : 1.0
            let hoverLift = isHovering && !isPressed ? 1.18 : 1.0
            return switch variant {
            case .primary:
                LinearGradient(
                    colors: [
                        theme.primary.opacity(min(1, 0.94 * pressShade * hoverLift)),
                        theme.secondary.opacity(min(1, 0.80 * pressShade * hoverLift)),
                        theme.glow.opacity(min(0.42, 0.20 * pressShade * hoverLift))
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .secondary:
                LinearGradient(
                    colors: [
                        theme.highlight.opacity(min(0.72, theme.highlightAlpha * 0.50 * pressShade * hoverLift)),
                        theme.elevatedSurface.opacity(min(1, theme.surfaceAlpha * 1.18 * pressShade * hoverLift)),
                        theme.surface.opacity(min(1, theme.surfaceAlpha * 0.72 * pressShade * hoverLift))
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .icon:
                LinearGradient(
                    colors: [
                        theme.highlight.opacity(min(0.66, theme.highlightAlpha * 0.42 * pressShade * hoverLift)),
                        theme.surface.opacity(min(1, theme.surfaceAlpha * 0.92 * pressShade * hoverLift)),
                        Color.black.opacity(theme.shadowDepth * (isHovering && !isPressed ? 0.06 : 0.10))
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .danger:
                LinearGradient(
                    colors: [
                        theme.strict.opacity(min(1, 0.92 * pressShade * hoverLift)),
                        Color.red.opacity(min(0.92, 0.72 * pressShade * hoverLift)),
                        Color.black.opacity(isHovering && !isPressed ? 0.08 : 0.14)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }

        private func stroke(isPressed: Bool, isHovering: Bool) -> Color {
            let pressedMultiplier = isPressed ? 0.68 : 1.0
            let hoverMultiplier = isHovering && !isPressed ? 1.34 : 1.0
            return switch variant {
            case .primary: theme.highlight.opacity(min(1, max(0.24, theme.specularOpacity) * pressedMultiplier * hoverMultiplier))
            case .secondary: theme.highlight.opacity(min(0.86, max(0.14, theme.specularOpacity * 0.58) * pressedMultiplier * hoverMultiplier))
            case .icon: theme.highlight.opacity(min(0.78, max(0.12, theme.specularOpacity * 0.50) * pressedMultiplier * hoverMultiplier))
            case .danger: theme.highlight.opacity(min(0.92, max(0.20, theme.specularOpacity * 0.70) * pressedMultiplier * hoverMultiplier))
            }
        }

        private func shadow(isPressed: Bool, isHovering: Bool) -> Color {
            let pressedMultiplier = isPressed ? 0.42 : 1.0
            let hoverMultiplier = isHovering && !isPressed ? 1.22 : 1.0
            return switch variant {
            case .primary: theme.glow.opacity(0.24 * pressedMultiplier * hoverMultiplier)
            case .secondary: theme.glow.opacity(0.10 * pressedMultiplier * hoverMultiplier)
            case .icon: theme.glow.opacity(0.08 * pressedMultiplier * hoverMultiplier)
            case .danger: theme.strict.opacity(0.18 * pressedMultiplier * hoverMultiplier)
            }
        }

        private var radius: CGFloat {
            variant == .icon ? 11 : 12
        }

        private var horizontalPadding: CGFloat {
            switch variant {
            case .primary: 16
            case .secondary, .danger: 12
            case .icon: 9
            }
        }

        private var verticalPadding: CGFloat {
            variant == .icon ? 9 : 10
        }
    }
}

enum FocusGlassHitTarget {
    static let compact: CGFloat = 40
    static let row: CGFloat = 44
}

struct GlassHoverHighlight: ViewModifier {
    let theme: ThemeProfile
    var radius: CGFloat = 11
    var isActive = false

    @State private var isHovering = false
    @Environment(\.isFocused) private var isFocused
    @Environment(\.focusGlassIsScrolling) private var isScrolling
    @Environment(\.focusGlassMotion) private var motion

    func body(content: Content) -> some View {
        content
            .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(background)
            }
            .overlay(alignment: .top) {
                Capsule()
                    .fill(theme.highlight.opacity(topHighlightOpacity))
                    .frame(height: 1)
                    .padding(.horizontal, radius * 0.74)
                    .padding(.top, 1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(stroke, lineWidth: 1)
            }
            .shadow(color: shadow, radius: isFocused ? 12 : (isHovering ? 10 : 0), x: 0, y: isFocused || isHovering ? 5 : 0)
            .brightness(isHovering ? 0.024 : 0)
            .onHover { hovering in
                if isScrolling {
                    isHovering = hovering
                } else {
                    withAnimation(motion.animation(.micro)) {
                        isHovering = hovering
                    }
                }
            }
            .animation(isScrolling ? nil : motion.animation(.micro), value: isHovering)
            .animation(motion.animation(.selection), value: isActive)
    }

    private var background: LinearGradient {
        let fill = fillStrength
        return LinearGradient(
            colors: [
                theme.highlight.opacity((isHovering ? 0.22 : 0.16) * fill),
                theme.elevatedSurface.opacity(max(0.32, theme.surfaceAlpha * (isHovering ? 1.72 : 1.44)) * fill),
                theme.surface.opacity(max(0.24, theme.surfaceAlpha * (isHovering ? 1.34 : 1.12)) * fill),
                theme.primary.opacity((isHovering ? 0.14 : 0.10) * fill)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var stroke: LinearGradient {
        let fill = fillStrength
        return LinearGradient(
            colors: [
                theme.highlight.opacity((isHovering ? 0.52 : 0.32) * fill),
                theme.primary.opacity((isHovering ? 0.48 : 0.34) * fill),
                theme.glow.opacity((isHovering ? 0.28 : 0.14) * fill)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var fillStrength: Double {
        if isHovering || isFocused {
            return 1
        }
        return isActive ? 0.92 : 0
    }

    private var topHighlightOpacity: Double {
        guard isHovering || isFocused || isActive else { return 0 }
        return isHovering || isFocused ? max(0.22, theme.specularOpacity * 0.72) : theme.specularOpacity * 0.34
    }

    private var shadow: Color {
        if isFocused {
            return theme.primary.opacity(0.30)
        }
        guard isHovering else { return .clear }
        return theme.glow.opacity(0.14)
    }
}

struct GlassCheckboxToggleStyle: ToggleStyle {
    let theme: ThemeProfile

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 8) {
                checkbox(isOn: configuration.isOn)
                configuration.label
            }
            .foregroundStyle(theme.text)
            .frame(minHeight: FocusGlassHitTarget.compact)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func checkbox(isOn: Bool) -> some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(
                LinearGradient(
                    colors: isOn ? [
                        theme.primary.opacity(0.96),
                        theme.strict.opacity(0.78)
                    ] : [
                        theme.highlight.opacity(theme.highlightAlpha * 0.30),
                        theme.elevatedSurface.opacity(theme.surfaceAlpha * 1.24),
                        theme.surface.opacity(theme.surfaceAlpha * 0.88)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(
                        isOn
                            ? theme.highlight.opacity(max(0.24, theme.specularOpacity * 0.90))
                            : theme.highlight.opacity(max(0.12, theme.borderOpacity)),
                        lineWidth: 1
                    )
            }
            .overlay {
                if isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.white)
                }
            }
            .shadow(color: isOn ? theme.primary.opacity(0.24) : .clear, radius: 7, x: 0, y: 3)
            .frame(width: 18, height: 18)
    }
}

extension View {
    func glassHover(theme: ThemeProfile, radius: CGFloat = 11, isActive: Bool = false) -> some View {
        modifier(GlassHoverHighlight(theme: theme, radius: radius, isActive: isActive))
    }
}

struct GlassDisclosureSection<Label: View, Content: View>: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @Environment(\.focusGlassMotion) private var motion

    @Binding var isExpanded: Bool
    private let label: Label
    private let content: Content

    init(
        isExpanded: Binding<Bool>,
        @ViewBuilder label: () -> Label,
        @ViewBuilder content: () -> Content
    ) {
        _isExpanded = isExpanded
        self.label = label()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(motion.animation(.disclosure)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .center, spacing: 10) {
                    label
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .foregroundStyle(model.theme.mutedText)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, minHeight: FocusGlassHitTarget.row, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .glassHover(theme: model.theme, radius: 10, isActive: isExpanded)

            if isExpanded {
                content
                    .transition(motion.transition(.disclosure))
            }
        }
        .animation(motion.animation(.disclosure), value: isExpanded)
    }
}

struct GlassSegmentedControl<Value: Hashable>: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @Environment(\.focusGlassMotion) private var motion

    @Binding var selection: Value
    let options: [Value]
    let title: (Value) -> String
    var symbol: (Value) -> String? = { _ in nil }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    withAnimation(motion.animation(.selection)) {
                        selection = option
                    }
                } label: {
                    HStack(spacing: 7) {
                        if let symbolName = symbol(option) {
                            Image(systemName: symbolName)
                                .font(.system(size: 11, weight: .bold))
                                .accessibilityHidden(true)
                        }
                        Text(title(option))
                            .font(.system(size: 12, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, model.theme.spacing(10))
                    .padding(.vertical, model.theme.spacing(9))
                    .frame(minHeight: FocusGlassHitTarget.compact)
                    .foregroundStyle(isSelected ? model.theme.text : model.theme.mutedText)
                    .background(
                        isSelected ? model.theme.primary.opacity(0.20) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .glassHover(theme: model.theme, radius: 11, isActive: isSelected)
                .help(title(option))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .animation(motion.animation(.selection), value: isSelected)
            }
        }
        .padding(model.theme.spacing(5))
        .background(
            LinearGradient(
                colors: [
                    model.theme.highlight.opacity(model.theme.highlightAlpha * 0.24),
                    model.theme.surface.opacity(model.theme.surfaceAlpha * 0.92),
                    Color.black.opacity(model.theme.shadowDepth * 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(alignment: .top) {
            Capsule()
                .fill(model.theme.highlight.opacity(model.theme.specularOpacity * 0.22))
                .frame(height: 1)
                .padding(.horizontal, 10)
                .padding(.top, 1)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            model.theme.highlight.opacity(model.theme.borderOpacity * 1.16),
                            model.theme.glow.opacity(model.theme.borderOpacity * 0.30),
                            Color.black.opacity(model.theme.shadowDepth * 0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}

struct GlassSelect<Value: Hashable>: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @Environment(\.focusGlassIsScrolling) private var isScrolling
    @Environment(\.focusGlassMotion) private var motion

    @Binding var selection: Value
    let options: [Value]
    let title: (Value) -> String
    var symbol: (Value) -> String? = { _ in nil }
    var minWidth: CGFloat = 220
    var lineLimit = 1

    @State private var isPresented = false
    @State private var isHovering = false

    var body: some View {
        let hovered = isHovering

        Button {
            withAnimation(motion.animation(.selection)) {
                isPresented.toggle()
            }
        } label: {
            HStack(spacing: 9) {
                if let symbolName = symbol(selection) {
                    Image(systemName: symbolName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(model.theme.mutedText)
                        .frame(width: 17)
                        .accessibilityHidden(true)
                }
                Text(title(selection))
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(lineLimit)
                    .minimumScaleFactor(0.68)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(model.theme.text)
                Spacer(minLength: 10)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(model.theme.primary)
            }
            .padding(.horizontal, model.theme.spacing(12))
            .padding(.vertical, model.theme.spacing(9))
            .frame(minWidth: minWidth, minHeight: FocusGlassHitTarget.row, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .background(
                LinearGradient(
                    colors: [
                        model.theme.highlight.opacity(model.theme.highlightAlpha * (hovered ? 0.50 : 0.34)),
                        model.theme.elevatedSurface.opacity(model.theme.surfaceAlpha * (hovered ? 1.24 : 1.12)),
                        model.theme.surface.opacity(model.theme.surfaceAlpha * (hovered ? 0.86 : 0.74))
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.thinMaterial)
            )
            .overlay(alignment: .top) {
                Capsule()
                    .fill(model.theme.highlight.opacity(model.theme.specularOpacity * (hovered ? 0.42 : 0.28)))
                    .frame(height: 1)
                    .padding(.horizontal, 9)
                    .padding(.top, 1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                model.theme.highlight.opacity(model.theme.borderOpacity * (hovered ? 1.52 : 1.22)),
                                model.theme.glow.opacity(model.theme.borderOpacity * (hovered ? 0.46 : 0.28)),
                                Color.black.opacity(model.theme.shadowDepth * 0.20)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .glassHover(theme: model.theme, radius: 12)
        .onHover { hovering in
            if isScrolling {
                isHovering = hovering
            } else {
                withAnimation(motion.animation(.micro)) {
                    isHovering = hovering
                }
            }
        }
        .help(title(selection))
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(options, id: \.self) { option in
                    Button {
                        withAnimation(motion.animation(.selection)) {
                            selection = option
                            isPresented = false
                        }
                    } label: {
                        HStack(spacing: 10) {
                            if let symbolName = symbol(option) {
                                Image(systemName: symbolName)
                                    .frame(width: 18)
                                    .accessibilityHidden(true)
                            }
                            Text(title(option))
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                            Spacer()
                            if option == selection {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(model.theme.primary)
                                    .accessibilityHidden(true)
                            }
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 9)
                        .frame(maxWidth: .infinity, minHeight: FocusGlassHitTarget.compact, alignment: .leading)
                        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .foregroundStyle(option == selection ? model.theme.text : model.theme.mutedText)
                        .background(
                            option == selection ? model.theme.primary.opacity(0.16) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                        .glassHover(theme: model.theme, radius: 10, isActive: option == selection)
                    }
                    .buttonStyle(.plain)
                    .help(title(option))
                    .accessibilityAddTraits(option == selection ? .isSelected : [])
                }
            }
            .padding(8)
            .frame(minWidth: minWidth)
            .background(model.theme.background)
            .foregroundStyle(model.theme.text)
        }
    }
}

struct GlassStepper: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    @Binding var value: Int
    let range: ClosedRange<Int>
    var step: Int = 1
    var title: (Int) -> String

    var body: some View {
        HStack(spacing: 8) {
            Button {
                value = decrementedValue
            } label: {
                Image(systemName: "minus")
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .icon))
            .disabled(value <= range.lowerBound)
            .help("-\(step)")

            Text(title(value))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.74)
                .frame(minWidth: 78)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [
                            model.theme.highlight.opacity(model.theme.highlightAlpha * 0.20),
                            model.theme.surface.opacity(model.theme.surfaceAlpha * 0.92),
                            Color.black.opacity(model.theme.shadowDepth * 0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(model.theme.highlight.opacity(model.theme.borderOpacity * 0.86), lineWidth: 1)
                }

            Button {
                value = incrementedValue
            } label: {
                Image(systemName: "plus")
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .icon))
            .disabled(value >= range.upperBound)
            .help("+\(step)")
        }
    }

    private var incrementedValue: Int {
        GlassStepperMath.increment(value: value, range: range, step: step)
    }

    private var decrementedValue: Int {
        GlassStepperMath.decrement(value: value, range: range, step: step)
    }
}

struct GlassSlider: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @State private var isDragging = false

    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 0.01
    var onEditingChanged: (Bool) -> Void = { _ in }

    var body: some View {
        GeometryReader { proxy in
            let width = max(CGFloat(1), proxy.size.width)
            let fillWidth = max(CGFloat(12), width * CGFloat(fraction))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                model.theme.highlight.opacity(model.theme.highlightAlpha * 0.18),
                                model.theme.surface.opacity(model.theme.surfaceAlpha * 0.92),
                                Color.black.opacity(model.theme.shadowDepth * 0.12)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay {
                        Capsule()
                            .stroke(model.theme.highlight.opacity(model.theme.borderOpacity * 0.88), lineWidth: 1)
                    }
                    .frame(height: 12)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                model.theme.primary,
                                model.theme.glow.opacity(0.92),
                                model.theme.secondary
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: fillWidth, height: 12)
                    .shadow(color: model.theme.glow.opacity(0.20), radius: 8, x: 0, y: 2)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                model.theme.highlight.opacity(0.92),
                                model.theme.primary,
                                model.theme.secondary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 22, height: 22)
                    .overlay {
                        Circle()
                            .stroke(model.theme.highlight.opacity(max(0.34, model.theme.specularOpacity)), lineWidth: 1)
                    }
                    .shadow(color: model.theme.glow.opacity(0.26), radius: 10, x: 0, y: 4)
                    .offset(x: min(width - 22, max(0, fillWidth - 11)))
            }
            .frame(height: 26)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        if !isDragging {
                            isDragging = true
                            onEditingChanged(true)
                        }
                        updateValue(locationX: Double(drag.location.x), width: Double(width))
                    }
                    .onEnded { drag in
                        updateValue(locationX: Double(drag.location.x), width: Double(width))
                        isDragging = false
                        onEditingChanged(false)
                    }
            )
        }
        .frame(height: 26)
        .accessibilityValue(Text(String(format: "%.2f", value)))
    }

    private var fraction: Double {
        guard range.upperBound > range.lowerBound else { return 0 }
        let clamped = min(range.upperBound, max(range.lowerBound, value))
        return (clamped - range.lowerBound) / (range.upperBound - range.lowerBound)
    }

    private func updateValue(locationX: Double, width: Double) {
        let rawFraction = min(1, max(0, locationX / max(1, width)))
        let rawValue = range.lowerBound + rawFraction * (range.upperBound - range.lowerBound)
        let stepped = step > 0 ? (rawValue / step).rounded() * step : rawValue
        value = min(range.upperBound, max(range.lowerBound, stepped))
    }
}

enum GlassStepperMath {
    static func increment(value: Int, range: ClosedRange<Int>, step: Int) -> Int {
        guard step > 1 else { return min(range.upperBound, value + step) }
        let next = ((value / step) + 1) * step
        return min(range.upperBound, max(range.lowerBound, next))
    }

    static func decrement(value: Int, range: ClosedRange<Int>, step: Int) -> Int {
        guard step > 1 else { return max(range.lowerBound, value - step) }
        let previous = ((value - 1) / step) * step
        return max(range.lowerBound, min(range.upperBound, previous))
    }
}

struct GlassMinuteInputField: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    @Binding var value: Int
    let range: ClosedRange<Int>
    @State private var draftText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            TextField(model.t("tasks.minutes"), text: $draftText)
                .textFieldStyle(.plain)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(model.theme.text)
                .multilineTextAlignment(.center)
                .focused($isFocused)
                .frame(width: 72)
                .onSubmit {
                    commitDraft(draftText)
                    syncDraft()
                }
                .onChange(of: draftText) { _, newValue in
                    commitDraft(newValue)
                }
                .onChange(of: value) { _, newValue in
                    guard !isFocused else { return }
                    draftText = "\(newValue)"
                }
                .onChange(of: isFocused) { _, focused in
                    if focused {
                        draftText = "\(value)"
                    } else {
                        commitDraft(draftText)
                        syncDraft()
                    }
                }
                .onAppear {
                    syncDraft()
                }
            Text(model.t("tasks.minutes"))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(model.theme.mutedText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: [
                    model.theme.highlight.opacity(model.theme.highlightAlpha * 0.18),
                    model.theme.surface.opacity(model.theme.surfaceAlpha * 0.90),
                    Color.black.opacity(model.theme.shadowDepth * 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(model.theme.highlight.opacity(model.theme.borderOpacity * 0.86), lineWidth: 1)
        }
        .help(model.t("help.manualMinutes"))
        .accessibilityLabel(model.t("help.manualMinutes"))
    }

    private func syncDraft() {
        draftText = "\(value)"
    }

    private func commitDraft(_ text: String) {
        let filtered = text.filter(\.isNumber)
        if filtered != text {
            draftText = filtered
            return
        }
        guard let parsed = Int(filtered) else { return }
        value = min(range.upperBound, max(range.lowerBound, parsed))
    }
}

struct GlassTextFieldStyle: TextFieldStyle {
    let theme: ThemeProfile

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(theme.text)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                LinearGradient(
                    colors: [
                        theme.highlight.opacity(theme.highlightAlpha * 0.26),
                        theme.elevatedSurface.opacity(theme.surfaceAlpha * 1.08),
                        theme.surface.opacity(theme.surfaceAlpha * 0.72)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 11, style: .continuous)
            )
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(alignment: .top) {
                Capsule()
                    .fill(theme.highlight.opacity(theme.specularOpacity * 0.22))
                    .frame(height: 1)
                    .padding(.horizontal, 9)
                    .padding(.top, 1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                theme.highlight.opacity(theme.borderOpacity),
                                theme.glow.opacity(theme.borderOpacity * 0.22),
                                Color.black.opacity(theme.shadowDepth * 0.18)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
    }
}

struct EmptyInlineState: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(model.theme.primary)
                .frame(width: 30, height: 30)
                .background(model.theme.primary.opacity(0.14), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                Text(detail)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(model.theme.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let detail: String
    let symbolName: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: symbolName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 30, height: 30)
                    .background(accent.opacity(0.17), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                Spacer()
            }

            Text(value)
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                Text(detail)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct ModeChip: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @Environment(\.focusGlassMotion) private var motion

    let title: String
    let symbolName: String
    let isSelected: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbolName)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .frame(minHeight: FocusGlassHitTarget.row)
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .foregroundStyle(isSelected ? model.theme.text : model.theme.text.opacity(0.74))
            .background(
                LinearGradient(
                    colors: chipFillColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(alignment: .top) {
                Capsule()
                    .fill(model.theme.highlight.opacity(isSelected ? model.theme.specularOpacity * 0.36 : model.theme.specularOpacity * 0.18))
                    .frame(height: 1)
                    .padding(.horizontal, 11)
                    .padding(.top, 1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: chipStrokeColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: isSelected ? accent.opacity(0.22) : Color.black.opacity(model.theme.shadowDepth * 0.18), radius: isSelected ? 12 : 7, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .glassHover(theme: model.theme, radius: 12, isActive: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(motion.animation(.selection), value: isSelected)
    }

    private var chipFillColors: [Color] {
        if isSelected {
            return [
                accent.opacity(0.34),
                model.theme.elevatedSurface.opacity(model.theme.surfaceAlpha * 1.20),
                accent.opacity(0.18)
            ]
        }

        return [
            model.theme.highlight.opacity(model.theme.highlightAlpha * 0.20),
            model.theme.surface.opacity(model.theme.surfaceAlpha * 0.94),
            Color.black.opacity(model.theme.shadowDepth * 0.08)
        ]
    }

    private var chipStrokeColors: [Color] {
        if isSelected {
            return [
                model.theme.highlight.opacity(model.theme.specularOpacity * 0.72),
                accent.opacity(0.64),
                Color.black.opacity(model.theme.shadowDepth * 0.16)
            ]
        }

        return [
            model.theme.highlight.opacity(model.theme.borderOpacity * 0.92),
            model.theme.glow.opacity(model.theme.borderOpacity * 0.18),
            Color.black.opacity(model.theme.shadowDepth * 0.14)
        ]
    }
}

struct CircularTimerView: View {
    @Environment(\.focusGlassMotion) private var motion

    let clockText: String
    let phase: String
    let progress: Double
    let theme: ThemeProfile
    let statusText: String
    var size: CGFloat = 390
    var clockSize: CGFloat = 76

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [theme.elevatedSurface.opacity(0.92), theme.surface.opacity(0.55)],
                        center: .center,
                        startRadius: 12,
                        endRadius: size * 0.58
                    )
                )
                .shadow(color: theme.glow.opacity(0.24), radius: 34, x: 0, y: 0)

            tickMarks

            Circle()
                .stroke(.white.opacity(0.08), lineWidth: 18)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    theme.ringGradient,
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: theme.glow.opacity(0.36), radius: 16, x: 0, y: 0)
                .animation(motion.animation(.progress), value: progress)

            VStack(spacing: 12) {
                Text(phase)
                    .font(.system(size: 13, weight: .bold))
                    .textCase(.uppercase)
                    .foregroundStyle(theme.primary)
                    .contentTransition(.opacity)
                    .animation(motion.animation(.selection), value: phase)
                Text(clockText)
                    .font(.system(size: clockSize, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.44)
                Text(statusText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .contentTransition(.opacity)
                    .animation(motion.animation(.selection), value: statusText)
            }
            .padding(34)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(width: size, height: size)
    }

    private var tickMarks: some View {
        ZStack {
            ForEach(0..<72, id: \.self) { index in
                Capsule()
                    .fill(.white.opacity(index % 6 == 0 ? 0.18 : 0.08))
                    .frame(width: 2, height: index % 6 == 0 ? 12 : 7)
                    .offset(y: -(size / 2 - 34))
                    .rotationEffect(.degrees(Double(index) * 5))
            }
        }
    }
}

struct HeatmapMiniView: View {
    let values: [Double]
    let low: Color
    let high: Color

    var body: some View {
        let cells = normalizedCells
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(12), spacing: 5), count: 14), spacing: 5) {
            ForEach(cells) { cell in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(cell.value == 0 ? low.opacity(0.34) : low.mix(with: high, by: cell.value))
                    .frame(width: 12, height: 12)
            }
        }
    }

    private var normalizedCells: [HeatmapCell] {
        let prefix = Array(values.prefix(28))
        let padded = prefix.count == 28
            ? prefix
            : prefix + Array(repeating: 0, count: 28 - prefix.count)
        return padded.enumerated().map { HeatmapCell(id: $0.offset, value: $0.element) }
    }

    private struct HeatmapCell: Identifiable {
        let id: Int
        let value: Double
    }
}

struct ThemeSwatch: View {
    @Environment(\.focusGlassMotion) private var motion
    let profile: ThemeProfile
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [profile.primary, profile.secondary, profile.glow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 28)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    }

                Text(profile.name)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, minHeight: FocusGlassHitTarget.row, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .background(
                isSelected ? profile.primary.opacity(0.18) : .white.opacity(0.045),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? profile.primary.opacity(0.48) : .clear, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .glassHover(theme: profile, radius: 10, isActive: isSelected)
        .animation(motion.animation(.selection), value: isSelected)
    }
}

extension Color {
    func mix(with other: Color, by amount: Double) -> Color {
        let amount = min(1, max(0, amount))
        let from = NSColor(self).usingColorSpace(.sRGB) ?? .white
        let to = NSColor(other).usingColorSpace(.sRGB) ?? .white

        return Color(
            red: Double(from.redComponent) + (Double(to.redComponent) - Double(from.redComponent)) * amount,
            green: Double(from.greenComponent) + (Double(to.greenComponent) - Double(from.greenComponent)) * amount,
            blue: Double(from.blueComponent) + (Double(to.blueComponent) - Double(from.blueComponent)) * amount
        )
    }
}

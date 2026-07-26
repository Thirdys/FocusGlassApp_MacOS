import AppKit
import SwiftUI
import FocusGlassCore

struct ContentView: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var hiddenToastMessage: String?
    @State private var toastGeneration = 0
    @State private var showsLaunchSequence = FocusGlassLaunchSession.shouldPresent
    @State private var didStartLaunchSequence = false
    @State private var launchAnimationReady = false

    var body: some View {
        GeometryReader { proxy in
            let layout = AppShellLayout(width: proxy.size.width)

            ZStack {
                model.theme.background
                    .ignoresSafeArea()

                Circle()
                    .fill(model.theme.glow.opacity(0.24))
                    .frame(width: 520, height: 520)
                    .blur(radius: 120)
                    .offset(x: 260, y: -260)

                Circle()
                    .fill(model.theme.secondary.opacity(0.16))
                    .frame(width: 460, height: 460)
                    .blur(radius: 130)
                    .offset(x: -420, y: 120)

                switch layout {
                case .compact:
                    VStack(spacing: 0) {
                        CompactNavBar()
                        contentScroll(horizontalPadding: 18, verticalPadding: 18, showsContextRail: false)
                    }
                case .medium:
                    HStack(spacing: 0) {
                        SidebarView()
                            .frame(width: 220)

                        Divider().opacity(0.16)

                        contentScroll(horizontalPadding: 24, verticalPadding: 24, showsContextRail: false)
                    }
                case .wide:
                    HStack(spacing: 0) {
                        SidebarView()
                            .frame(width: 220)

                        Divider().opacity(0.16)

                        contentScroll(horizontalPadding: 28, verticalPadding: 26, showsContextRail: false)

                        Divider().opacity(0.12)

                        FocusContextRailView()
                            .frame(width: 300)
                    }
                }

                if showsLaunchSequence {
                    FocusGlassLaunchOverlay(
                        theme: model.theme,
                        reduceMotion: accessibilityReduceMotion
                    ) {
                        launchAnimationReady = true
                    }
                        .transition(.opacity)
                        .zIndex(2)
                }
            }
            .foregroundStyle(model.theme.text)
        }
        .overlay(alignment: .bottom) {
            if let message = model.focusGuard.lastDistractionMessage,
               message != hiddenToastMessage,
               !model.isFocusModeActive {
                DistractionToast(message: message)
                    .environmentObject(model)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onReceive(model.focusGuard.$lastDistractionMessage) { message in
            hiddenToastMessage = nil
            guard let message else { return }
            toastGeneration &+= 1
            let generation = toastGeneration
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(4))
                if model.focusGuard.lastDistractionMessage == message,
                   toastGeneration == generation {
                    withAnimation(.easeInOut(duration: 0.20)) {
                        hiddenToastMessage = message
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            model.focusGuard.refreshPermissionStates()
        }
        .task {
            await runLaunchSequenceIfNeeded()
        }
    }

    private func contentScroll(horizontalPadding: CGFloat, verticalPadding: CGFloat, showsContextRail: Bool) -> some View {
        FocusGlassScrollView {
            LazyVStack(spacing: 22) {
                HeaderView()
                if model.needsPermissionAttention {
                    PermissionBannerView()
                }
                RouteContentView()
                if showsContextRail && model.selectedSidebarItem == .focusToday {
                    FocusContextRailView()
                }
                MainWindowBuildBadge()
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .allowsHitTesting(false)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: 1240)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
    }

    private func runLaunchSequenceIfNeeded() async {
        guard !didStartLaunchSequence else { return }
        didStartLaunchSequence = true
        guard FocusGlassLaunchSession.claim() else {
            showsLaunchSequence = false
            return
        }

        if accessibilityReduceMotion {
            try? await Task.sleep(for: .milliseconds(160))
        } else {
            if FocusGlassLaunchCapture.delayMilliseconds > 0 {
                try? await Task.sleep(for: .milliseconds(FocusGlassLaunchCapture.delayMilliseconds))
            }
            let scale = model.theme.motionDurationScale
            let minimumMilliseconds = Int(620 * scale)
            let maximumMilliseconds = Int(900 * scale)
            var elapsed = 0
            while elapsed < maximumMilliseconds,
                  (elapsed < minimumMilliseconds || !launchAnimationReady) {
                try? await Task.sleep(for: .milliseconds(20))
                elapsed += 20
            }
        }
        withAnimation(.easeInOut(duration: accessibilityReduceMotion ? 0.16 : model.theme.animationDuration(0.15))) {
            showsLaunchSequence = false
        }
    }
}

private struct MainWindowBuildBadge: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    private let buildInfo = AppBuildInfo.current

    var body: some View {
        Text(displayText)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .foregroundStyle(model.theme.mutedText)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(model.theme.elevatedSurface.opacity(0.42), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(model.theme.highlight.opacity(0.12), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 8)
            .accessibilityLabel(displayText)
    }

    private var displayText: String {
        "\(model.t("app.version")) \(buildInfo.version) / \(model.t("app.build")) \(buildInfo.build)"
    }
}

private struct AppBuildInfo {
    let version: String
    let build: String

    static let current = AppBuildInfo(
        version: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev",
        build: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "local"
    )
}

private enum FocusGlassLaunchCapture {
    static let delayMilliseconds: Int = {
#if DEBUG
        let prefix = "focusglass-launch-capture-delay="
        guard let argument = CommandLine.arguments.first(where: { $0.hasPrefix(prefix) }),
              let value = Int(argument.dropFirst(prefix.count)) else {
            return 0
        }
        return min(3_000, max(0, value))
#else
        return 0
#endif
    }()
}

@MainActor
private enum FocusGlassLaunchSession {
    static var didPresent = false

    static var shouldPresent: Bool {
        !didPresent
    }

    static func claim() -> Bool {
        guard !didPresent else { return false }
        didPresent = true
        return true
    }
}

private struct FocusGlassLaunchOverlay: View {
    let theme: ThemeProfile
    let reduceMotion: Bool
    let onAnimationReady: () -> Void

    @State private var tileProgress = 0.0
    @State private var arcProgress = 0.0
    @State private var handProgress = 0.0
    @State private var dotProgress = 0.0
    @State private var wordmarkProgress = 0.0

    var body: some View {
        GeometryReader { proxy in
            let minimumSide = min(proxy.size.width, proxy.size.height)
            let markSize = min(196, max(148, minimumSide * 0.25))
            let glowSize = markSize * 2.35

            ZStack {
                theme.background
                    .ignoresSafeArea()

                Circle()
                    .fill(theme.glow.opacity(0.22 * tileProgress))
                    .frame(width: glowSize, height: glowSize)
                    .blur(radius: markSize * 0.46)

                VStack(spacing: theme.spacing(20)) {
                    FocusGlassLaunchMark(
                        theme: theme,
                        tileProgress: tileProgress,
                        arcProgress: arcProgress,
                        handProgress: handProgress,
                        dotProgress: dotProgress
                    )
                    .frame(width: markSize, height: markSize)

                    Text("FocusGlass")
                        .font(.system(size: min(38, markSize * 0.20), weight: .bold, design: .rounded))
                        .foregroundStyle(theme.text)
                        .opacity(wordmarkProgress)
                        .offset(y: (1 - wordmarkProgress) * 4)
                }
                .offset(y: -min(34, proxy.size.height * 0.04))
                .shadow(color: theme.glow.opacity(0.18), radius: markSize * 0.16, x: 0, y: markSize * 0.08)
            }
        }
        .accessibilityHidden(true)
        .onAppear {
            if reduceMotion {
                tileProgress = 1
                arcProgress = 1
                handProgress = 1
                dotProgress = 1
                wordmarkProgress = 1
                onAnimationReady()
                return
            }

            Task { @MainActor in
                if FocusGlassLaunchCapture.delayMilliseconds > 0 {
                    try? await Task.sleep(for: .milliseconds(FocusGlassLaunchCapture.delayMilliseconds))
                }
                await runPhases()
            }
        }
    }

    @MainActor
    private func runPhases() async {
        let scale = theme.motionDurationScale
        withAnimation(.easeOut(duration: 0.12 * scale)) {
            tileProgress = 1
        }
        try? await Task.sleep(for: .milliseconds(Int(100 * scale)))
        withAnimation(.easeInOut(duration: 0.28 * scale)) {
            arcProgress = 1
        }
        try? await Task.sleep(for: .milliseconds(Int(120 * scale)))
        withAnimation(.easeInOut(duration: 0.28 * scale)) {
            handProgress = 1
        }
        try? await Task.sleep(for: .milliseconds(Int(200 * scale)))
        withAnimation(.easeOut(duration: 0.17 * scale)) {
            dotProgress = 1.10
        }
        try? await Task.sleep(for: .milliseconds(Int(40 * scale)))
        withAnimation(.easeOut(duration: 0.19 * scale)) {
            wordmarkProgress = 1
        }
        try? await Task.sleep(for: .milliseconds(Int(50 * scale)))
        withAnimation(.easeInOut(duration: 0.08 * scale)) {
            dotProgress = 1
        }
        try? await Task.sleep(for: .milliseconds(Int(140 * scale)))
        onAnimationReady()
    }
}

private struct FocusGlassLaunchMark: View {
    let theme: ThemeProfile
    let tileProgress: Double
    let arcProgress: Double
    let handProgress: Double
    let dotProgress: Double

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let tileInset = size * FocusGlassMarkGeometry.tileInset
            let tileRadius = size * FocusGlassMarkGeometry.tileCornerRadius
            let faceInset = size * FocusGlassMarkGeometry.faceInset
            let faceStrokeInset = size * FocusGlassMarkGeometry.faceStrokeInset
            let dotFrame = FocusGlassMarkGeometry.swiftUIRect(
                x: FocusGlassMarkGeometry.focusDotX,
                appKitY: FocusGlassMarkGeometry.focusDotY,
                width: FocusGlassMarkGeometry.focusDotSize,
                height: FocusGlassMarkGeometry.focusDotSize,
                size: size
            )
            let lensGlintFrame = FocusGlassMarkGeometry.swiftUIRect(
                x: 0.278,
                appKitY: 0.644,
                width: 0.052,
                height: 0.052,
                size: size
            )

            ZStack {
                RoundedRectangle(cornerRadius: tileRadius, style: .continuous)
                    .fill(theme.background)
                    .overlay {
                        RoundedRectangle(cornerRadius: tileRadius, style: .continuous)
                            .fill(theme.primary.opacity(0.10))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: tileRadius, style: .continuous)
                            .stroke(theme.highlight.opacity(0.24), lineWidth: max(1, size * 0.012))
                    }
                    .padding(tileInset)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.highlight.opacity(0.26),
                                theme.elevatedSurface.opacity(0.70),
                                theme.surface.opacity(0.88)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(faceInset)

                Circle()
                    .stroke(theme.highlight.opacity(0.32), lineWidth: max(1.4, size * 0.017))
                    .padding(faceStrokeInset)

                FocusGlassProgressArc(progress: arcProgress)
                    .stroke(
                        theme.primary,
                        style: StrokeStyle(
                            lineWidth: max(4, size * FocusGlassMarkGeometry.progressLineWidth),
                            lineCap: .round
                        )
                    )

                FocusGlassClockHands(progress: handProgress)
                    .stroke(
                        theme.text.opacity(0.94),
                        style: StrokeStyle(
                            lineWidth: max(2.2, size * FocusGlassMarkGeometry.handLineWidth),
                            lineCap: .round
                        )
                    )

                Circle()
                    .fill(theme.text.opacity(0.98))
                    .frame(
                        width: size * FocusGlassMarkGeometry.centerDotSize,
                        height: size * FocusGlassMarkGeometry.centerDotSize
                    )

                Circle()
                    .stroke(theme.primary.opacity(0.18 * dotProgress), lineWidth: max(1, size * 0.012))
                    .frame(
                        width: size * FocusGlassMarkGeometry.focusHaloSize,
                        height: size * FocusGlassMarkGeometry.focusHaloSize
                    )
                    .position(x: dotFrame.midX, y: dotFrame.midY)
                    .scaleEffect(0.82 + 0.18 * dotProgress)

                Circle()
                    .fill(theme.primary.opacity(0.92))
                    .frame(width: dotFrame.width, height: dotFrame.height)
                    .position(x: dotFrame.midX, y: dotFrame.midY)
                    .scaleEffect(max(0.72, dotProgress))
                    .opacity(min(1, dotProgress))

                FocusGlassLensShine()
                    .stroke(
                        theme.highlight.opacity(0.30),
                        style: StrokeStyle(lineWidth: max(2, size * 0.030), lineCap: .round)
                    )

                Circle()
                    .fill(theme.highlight.opacity(0.18))
                    .frame(width: lensGlintFrame.width, height: lensGlintFrame.height)
                    .position(x: lensGlintFrame.midX, y: lensGlintFrame.midY)

                RoundedRectangle(cornerRadius: tileRadius, style: .continuous)
                    .stroke(theme.primary.opacity(0.18), lineWidth: max(1, size * 0.010))
                    .padding(tileInset + size * 0.012)
            }
            .frame(width: size, height: size)
            .opacity(tileProgress)
            .scaleEffect(0.96 + 0.04 * tileProgress)
        }
    }
}

private struct FocusGlassProgressArc: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let start = -FocusGlassMarkGeometry.progressStartAngle
        let finish = -FocusGlassMarkGeometry.progressEndAngle
        let end = start + (finish - start) * progress
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: min(rect.width, rect.height) * FocusGlassMarkGeometry.progressRadius,
            startAngle: .degrees(start),
            endAngle: .degrees(end),
            clockwise: false
        )
        return path
    }
}

private struct FocusGlassClockHands: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let size = min(rect.width, rect.height)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let staticHand = CGPoint(
            x: FocusGlassMarkGeometry.minuteHandEnd.x * size,
            y: (1 - FocusGlassMarkGeometry.minuteHandEnd.y) * size
        )
        let startAngle = -CGFloat.pi / 2
        let finalPoint = CGPoint(
            x: FocusGlassMarkGeometry.hourHandEnd.x * size,
            y: (1 - FocusGlassMarkGeometry.hourHandEnd.y) * size
        )
        let finalAngle = atan2(finalPoint.y - center.y, finalPoint.x - center.x)
        let angle = startAngle + (finalAngle - startAngle) * progress
        let length = hypot(finalPoint.x - center.x, finalPoint.y - center.y)
        let movingHand = CGPoint(
            x: center.x + cos(angle) * length,
            y: center.y + sin(angle) * length
        )

        var path = Path()
        path.move(to: center)
        path.addLine(to: staticHand)
        path.move(to: center)
        path.addLine(to: movingHand)
        return path
    }
}

private struct FocusGlassLensShine: Shape {
    func path(in rect: CGRect) -> Path {
        let size = min(rect.width, rect.height)
        var path = Path()
        path.move(to: CGPoint(x: size * 0.305, y: size * (1 - 0.690)))
        path.addCurve(
            to: CGPoint(x: size * 0.565, y: size * (1 - 0.755)),
            control1: CGPoint(x: size * 0.365, y: size * (1 - 0.765)),
            control2: CGPoint(x: size * 0.482, y: size * (1 - 0.790))
        )
        return path
    }
}

private struct DistractionToast: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(model.theme.strict)
            Text(message)
                .font(.system(size: 13, weight: .bold))
                .lineLimit(2)
                .foregroundStyle(model.theme.text)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [
                    model.theme.highlight.opacity(model.theme.highlightAlpha * 0.34),
                    model.theme.elevatedSurface.opacity(model.theme.surfaceAlpha * 1.12),
                    model.theme.surface.opacity(model.theme.surfaceAlpha * 0.82)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: Capsule()
        )
        .background(.thinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .stroke(model.theme.strict.opacity(0.32), lineWidth: 1)
        }
        .shadow(color: model.theme.glow.opacity(0.16), radius: 18, x: 0, y: 10)
        .padding(.horizontal, 24)
        .frame(maxWidth: 560)
    }
}

private enum AppShellLayout {
    case wide
    case medium
    case compact

    init(width: CGFloat) {
        if width >= 1680 {
            self = .wide
        } else if width >= 980 {
            self = .medium
        } else {
            self = .compact
        }
    }
}

private struct PermissionBannerView: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    var body: some View {
        LiquidGlassPanel(radius: 18, padding: 14) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(model.theme.strict)
                    .frame(width: 34, height: 34)
                    .background(model.theme.strict.opacity(0.13), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(model.t("permissions.banner.title"))
                        .font(.system(size: 13, weight: .bold))
                    Text(model.focusGuard.lastPermissionMessage ?? model.t("permissions.banner.detail"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(model.theme.mutedText)
                        .lineLimit(2)
                }

                Spacer()

                if model.focusGuard.status(for: .notifications) == .missing {
                    Button(model.t("settings.requestNotifications")) {
                        model.focusGuard.requestNotificationPermissionIfNeeded()
                    }
                    .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))
                }

                if model.focusGuard.status(for: .accessibility) == .missing {
                    Button(model.t("settings.requestAccessibility")) {
                        model.requestAccessibilityPermission()
                    }
                    .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .primary))
                }

                if model.focusGuard.status(for: .automation) == .missing {
                    Button(model.t("settings.requestAutomation")) {
                        model.requestAutomationPermission()
                    }
                    .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))
                }
            }
        }
    }
}

private struct HeaderView: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 18) {
                titleBlock
                Spacer()
                headerControls
            }

            VStack(alignment: .leading, spacing: 14) {
                titleBlock
                headerControls
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .lineLimit(2)
                .minimumScaleFactor(0.82)
            Text(subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(model.theme.mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var headerControls: some View {
        HStack(spacing: 12) {
            Image(systemName: model.strictModeEnabled ? "shield.checkered" : "shield")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(model.strictModeEnabled ? model.theme.strict : model.theme.mutedText)
            Toggle("", isOn: $model.strictModeEnabled)
                .labelsHidden()
                .toggleStyle(.switch)
                .help(model.t("help.strictMode"))
                .accessibilityLabel(model.t("strict.mode"))

            Button {
                openWindow(id: "focus-mode")
                model.openFocusModeFullscreen()
            } label: {
                Label(model.t("focus.fullscreen"), systemImage: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 13, weight: .bold))
            }
            .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .primary))
            .help(model.t("help.fullscreen"))
        }
        .padding(10)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var title: String {
        switch model.selectedSidebarItem {
        case .focusToday: model.t("focus.today")
        case .projects: model.t("projects.title")
        case .analytics: model.t("analytics.title")
        case .strictMode: model.t("strict.title")
        case .settings: model.t("settings.title")
        }
    }

    private var subtitle: String {
        switch model.selectedSidebarItem {
        case .focusToday: model.t("focus.subtitle")
        case .projects: model.t("projects.subtitle")
        case .analytics: model.t("analytics.subtitle")
        case .strictMode: model.t("strict.subtitle")
        case .settings: model.t("settings.subtitle")
        }
    }
}

private struct RouteContentView: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    var body: some View {
        switch model.selectedSidebarItem {
        case .focusToday:
            FocusTodayView()
        case .projects:
            ProjectsScreen()
        case .analytics:
            AnalyticsScreen()
        case .strictMode:
            StrictModeScreen()
        case .settings:
            SettingsContentView(showsHeader: false)
        }
    }
}

private struct CompactNavBar: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    var body: some View {
        FocusGlassScrollView(.horizontal) {
            LazyHStack(spacing: 8) {
                ForEach(SidebarItem.allCases) { item in
                    Button {
                        model.selectedSidebarItem = item
                    } label: {
                        Label(model.sidebarTitle(item), systemImage: item.symbolName)
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .frame(minHeight: FocusGlassHitTarget.compact)
                            .fixedSize(horizontal: true, vertical: false)
                            .foregroundStyle(model.selectedSidebarItem == item ? model.theme.text : model.theme.mutedText)
                            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .fixedSize(horizontal: true, vertical: false)
                    .glassHover(theme: model.theme, radius: 14, isActive: model.selectedSidebarItem == item)
                    .accessibilityAddTraits(model.selectedSidebarItem == item ? .isSelected : [])
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
        .frame(height: 64)
        .background(model.theme.surface.opacity(0.20))
        .background(.ultraThinMaterial)
    }
}

private struct SidebarView: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(model.theme.primary.opacity(0.16))
                    Image(systemName: "timer.circle.fill")
                        .font(.system(size: 29, weight: .semibold))
                        .foregroundStyle(model.theme.primary)
                }
                .frame(width: 42, height: 42)

                Text("FocusGlass")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
            }
            .padding(.horizontal, 18)
            .padding(.top, 26)

            VStack(spacing: 7) {
                ForEach(SidebarItem.allCases) { item in
                    Button {
                        model.selectedSidebarItem = item
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: item.symbolName)
                                .frame(width: 19)
                            Text(model.sidebarTitle(item))
                            Spacer()
                            if item == .focusToday {
                                Text("\(model.activeTasks.count)")
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.white.opacity(0.11), in: Capsule())
                            }
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(model.selectedSidebarItem == item ? model.theme.text : model.theme.mutedText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .glassHover(theme: model.theme, radius: 11, isActive: model.selectedSidebarItem == item)
                    .accessibilityAddTraits(model.selectedSidebarItem == item ? .isSelected : [])
                }
            }
            .padding(.horizontal, 10)

            Divider()
                .opacity(0.16)
                .padding(.horizontal, 18)

            VStack(alignment: .leading, spacing: 12) {
                Text(model.t("sidebar.projects"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(model.theme.mutedText)
                    .textCase(.uppercase)

                ForEach(model.projects) { project in
                    Button {
                        model.selectProject(project)
                    } label: {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(project.id == model.activeProjectID ? model.theme.primary : model.theme.primary.opacity(0.42))
                                .frame(width: 8, height: 8)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(project.name)
                                    .font(.system(size: 13, weight: .bold))
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(project.detail)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(model.theme.mutedText)
                                    .lineLimit(2)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .glassHover(theme: model.theme, radius: 11, isActive: project.id == model.activeProjectID)
                    .accessibilityAddTraits(project.id == model.activeProjectID ? .isSelected : [])
                    .help("\(project.name)\n\(project.detail)")
                }
            }
            .padding(.horizontal, 18)

            Spacer()

            LiquidGlassPanel(radius: 18, padding: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(model.t("sidebar.todayScore"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(model.theme.mutedText)
                    Text("\(model.dailySummary.focusScore)")
                        .font(.system(size: 40, weight: .semibold, design: .rounded))
                    Text(model.t("sidebar.todayScoreDetail"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(model.theme.mutedText)
                        .lineLimit(2)
                }
            }
            .padding(16)
        }
        .background(model.theme.surface.opacity(0.28))
        .background(.ultraThinMaterial)
    }
}

private struct FocusTodayView: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 18) {
                QuickModeRow()

                if let outcome = model.pendingSessionOutcome {
                    SessionOutcomeCard(outcome: outcome)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                focusLayout
            }

            AnalyticsStripView()
        }
    }

    private var focusLayout: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 24) {
                FocusProjectPanel()
                    .frame(width: 360)

                FocusTimerStack(size: 360, clockSize: 72)
                    .frame(minWidth: 360)

                FocusTaskPanel()
                    .frame(width: 360)
            }

            VStack(spacing: 18) {
                FocusTimerStack(size: 318, clockSize: 62)
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 16) {
                        FocusProjectPanel()
                        FocusTaskPanel()
                    }

                    VStack(spacing: 16) {
                        FocusProjectPanel()
                        FocusTaskPanel()
                    }
                }
            }
        }
    }
}

private struct FocusTimerStack: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @EnvironmentObject private var timerPresentation: FocusTimerPresentationState

    let size: CGFloat
    let clockSize: CGFloat

    var body: some View {
        VStack(spacing: 18) {
            CircularTimerView(
                clockText: timerPresentation.primaryClockText,
                phase: model.phaseTitle(timerPresentation.snapshot.activeSegment.phase),
                progress: timerPresentation.snapshot.progress,
                theme: model.theme,
                statusText: model.statusTitle(timerPresentation.snapshot.status),
                size: size,
                clockSize: clockSize
            )

            TimerControlRow()
        }
    }
}

private struct QuickModeRow: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 150, maximum: 230), spacing: 10)],
            alignment: .leading,
            spacing: 10
        ) {
            ForEach(model.presets) { preset in
                modeChip(for: preset)
            }
        }
    }

    private func modeChip(for preset: TimerPreset) -> some View {
        ModeChip(
            title: model.presetTitle(preset),
            symbolName: preset.mode.symbolName,
            isSelected: preset.id == model.selectedPreset.id,
            accent: model.theme.primary
        ) {
            model.selectPreset(preset)
        }
    }
}

private struct FocusProjectPanel: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @State private var isNotesExpanded = false

    private var activeProject: FocusProject? {
        model.activeProjectID.flatMap { projectID in
            model.projects.first { $0.id == projectID }
        }
    }

    var body: some View {
        LiquidGlassPanel(radius: 18, padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                projectContext
                projectNotes
            }
        }
    }

    private var projectContext: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(model.t("focus.activeProject"))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(model.theme.mutedText)
                        .textCase(.uppercase)

                    GlassSelect(
                        selection: $model.activeProjectID,
                        options: [nil] + model.projects.map(\.id),
                        title: projectTitle,
                        symbol: { $0 == nil ? "tray" : "folder" },
                        minWidth: 180,
                        lineLimit: 2
                    )
                    .help(model.t("focus.activeProject"))
                }

                Spacer(minLength: 0)
            }

            Text(projectDetail)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(model.theme.mutedText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(model.theme.highlight.opacity(0.12), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var projectNotes: some View {
        if activeProject != nil {
            GlassDisclosureSection(isExpanded: $isNotesExpanded) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "note.text")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(model.theme.primary)
                        Text(model.t("projects.notes"))
                            .font(.system(size: 12, weight: .bold))
                        Spacer(minLength: 0)
                    }

                    if !isNotesExpanded {
                        Text(notesPreview.isEmpty ? model.t("projects.notes.empty") : notesPreview)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(model.theme.mutedText)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(13)
            } content: {
                TextField(model.t("projects.notes.placeholder"), text: activeProjectNotesBinding, axis: .vertical)
                    .textFieldStyle(GlassTextFieldStyle(theme: model.theme))
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(3...7)
                    .padding(.horizontal, 13)
                    .padding(.bottom, 13)
            }
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(model.theme.highlight.opacity(0.12), lineWidth: 1)
            }
        }
    }

    private var activeProjectNotesBinding: Binding<String> {
        Binding(
            get: { activeProject?.notes ?? "" },
            set: { model.updateActiveProjectNotes($0) }
        )
    }

    private var notesPreview: String {
        activeProject?.notes.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private var projectDetail: String {
        if let activeProject {
            return activeProject.detail.isEmpty ? model.t("projects.new.detail") : activeProject.detail
        }
        return model.t("projects.unassigned.detail")
    }

    private func projectTitle(_ projectID: UUID?) -> String {
        projectID.flatMap(model.projectName(for:)) ?? model.t("projects.unassigned")
    }
}

private struct FocusTaskPanel: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @State private var editingTask: FocusTask?

    private var secondaryTasks: [FocusTask] {
        model.activeTasks.filter { $0.id != model.activeTaskID }
    }

    var body: some View {
        LiquidGlassPanel(radius: 20, padding: 16, depth: .floating) {
            VStack(alignment: .leading, spacing: 14) {
                activeTaskSummary
                taskList
                addTaskButton
            }
        }
        .sheet(item: $editingTask) { task in
            TaskEditorSheet(task: task) { updatedTask in
                model.updateTask(updatedTask)
                editingTask = nil
            } onDelete: { deletedTask in
                model.deleteTask(deletedTask)
                editingTask = nil
            }
            .environmentObject(model)
        }
    }

    @ViewBuilder
    private var activeTaskSummary: some View {
        if let task = model.selectedActiveTask {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Label(model.t("tasks.activeForSession"), systemImage: "target")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(model.theme.primary)
                    Spacer()
                    Button {
                        editingTask = task
                    } label: {
                        Image(systemName: "pencil")
                            .frame(width: FocusGlassHitTarget.compact, height: FocusGlassHitTarget.compact)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(model.theme.mutedText)
                    .glassHover(theme: model.theme, radius: 8)
                    .help(model.t("tasks.edit"))
                }

                Text(task.title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .lineLimit(3)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    taskMeta(for: task)
                    Spacer(minLength: 0)
                }

                if task.timingMode == .timed {
                    ProgressView(value: task.completed, total: max(1, task.estimate))
                        .tint(model.theme.primary)
                }
            }
            .padding(15)
            .background(
                LinearGradient(
                    colors: [
                        model.theme.primary.opacity(0.18),
                        model.theme.surface.opacity(0.58),
                        Color.white.opacity(0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 17, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(model.theme.primary.opacity(0.42), lineWidth: 1)
            }
            .shadow(color: model.theme.primary.opacity(0.16), radius: 22, x: 0, y: 14)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var taskList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(model.activeProjectID == nil ? model.t("tasks.focusStack") : model.t("tasks.projectTasks"))
                .font(.system(size: 14, weight: .bold))

            if model.activeTasks.isEmpty {
                EmptyInlineState(
                    symbol: "checklist.unchecked",
                    title: model.t("tasks.empty.title"),
                    detail: model.t("tasks.empty.detail")
                )
            } else if !secondaryTasks.isEmpty {
                FocusGlassScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(secondaryTasks) { task in
                            FocusTaskCardRow(task: task) {
                                editingTask = task
                            }
                        }
                    }
                    .padding(.trailing, 2)
                }
                .frame(maxHeight: 360)
            }
        }
    }

    private var addTaskButton: some View {
        Button {
            editingTask = model.addQuickTask()
        } label: {
            Label(model.t("focus.addTask"), systemImage: "plus")
                .font(.system(size: 12, weight: .bold))
        }
        .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))
    }

    @ViewBuilder
    private func taskMeta(for task: FocusTask) -> some View {
        if task.timingMode == .timed {
            Label("\(task.completed.focusClock) / \(task.estimate.focusClock)", systemImage: "clock")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(model.theme.mutedText)
        } else {
            Label(model.t("tasks.checklist"), systemImage: "checklist")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(model.theme.mutedText)
        }
    }
}

private struct TimerControlRow: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @EnvironmentObject private var timerPresentation: FocusTimerPresentationState

    var body: some View {
        HStack(spacing: 14) {
            Button {
                model.resetTimer()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .icon))
            .help(model.t("help.timerReset"))

            Button {
                model.toggleTimer()
            } label: {
                Text(primaryTitle)
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 150)
            }
            .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .primary))
            .help(primaryTitle)

            Button {
                model.skipSegment()
            } label: {
                Image(systemName: "forward.end.fill")
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .icon))
            .disabled(!timerPresentation.canSkipSegment)
            .opacity(timerPresentation.canSkipSegment ? 1 : 0.42)
            .help(model.t("help.timerSkip"))
        }
    }

    private var primaryTitle: String {
        switch timerPresentation.snapshot.status {
        case .running: model.t("timer.pause")
        case .paused: model.t("timer.resume")
        case .idle, .completed: model.t("timer.start")
        }
    }
}

private struct FocusTaskCardRow: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @Environment(\.focusGlassIsScrolling) private var isScrolling
    @State private var isHovering = false

    let task: FocusTask
    let onEdit: () -> Void

    private var isSelected: Bool {
        model.activeTaskID == task.id
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                model.toggleTask(task)
            } label: {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: FocusGlassHitTarget.compact, height: FocusGlassHitTarget.compact)
                    .contentShape(Rectangle())
                    .foregroundStyle(task.isDone ? model.theme.primary : model.theme.mutedText)
            }
            .buttonStyle(.plain)
            .glassHover(theme: model.theme, radius: 8)
            .help(model.t("tasks.done"))
            .accessibilityLabel("\(model.t("tasks.done")): \(task.title)")

            Button {
                model.selectTaskForSession(task)
            } label: {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(task.title)
                            .font(.system(size: 14, weight: .bold))
                            .lineLimit(3)
                            .minimumScaleFactor(0.82)
                            .fixedSize(horizontal: false, vertical: true)
                            .layoutPriority(1)
                        Spacer(minLength: 0)
                    }

                    HStack(spacing: 8) {
                        selectedBadge
                        taskMeta
                        Spacer(minLength: 0)
                    }

                    if task.timingMode == .timed {
                        ProgressView(value: task.completed, total: max(1, task.estimate))
                            .tint(model.theme.primary)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: FocusGlassHitTarget.row, alignment: .leading)
                .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .glassHover(theme: model.theme, radius: 12, isActive: isSelected)
            .help(model.t("tasks.selectForSession"))
            .accessibilityAddTraits(isSelected ? .isSelected : [])

            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil")
                    .frame(width: FocusGlassHitTarget.compact, height: FocusGlassHitTarget.compact)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(model.theme.mutedText)
            .opacity((isHovering && !isScrolling) || isSelected ? 1 : 0.58)
            .glassHover(theme: model.theme, radius: 8)
            .help(model.t("tasks.edit"))
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .background(
            (isSelected ? model.theme.primary.opacity(0.13) : Color.white.opacity(0.052)),
            in: RoundedRectangle(cornerRadius: 15, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(isSelected ? model.theme.primary.opacity(0.44) : model.theme.highlight.opacity(0.10), lineWidth: 1)
        }
        .glassHover(theme: model.theme, radius: 15, isActive: isSelected)
        .onHover { hovering in
            guard !isScrolling else { return }
            withAnimation(.easeInOut(duration: 0.14)) {
                isHovering = hovering
            }
        }
        .onChange(of: isScrolling) { _, scrolling in
            if scrolling {
                isHovering = false
            }
        }
    }

    @ViewBuilder
    private var selectedBadge: some View {
        if isSelected {
            Label(model.t("tasks.activeForSession"), systemImage: "target")
                .labelStyle(.titleAndIcon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(model.theme.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(model.theme.primary.opacity(0.12), in: Capsule())
        }
    }

    @ViewBuilder
    private var taskMeta: some View {
        if task.timingMode == .timed {
            Text("\(task.completed.focusClock) / \(task.estimate.focusClock)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(model.theme.mutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        } else {
            Text(model.t("tasks.checklist"))
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(model.theme.mutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
    }
}

private struct SessionOutcomeCard: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    let outcome: SessionOutcomePresentation

    var body: some View {
        LiquidGlassPanel(radius: 20, padding: 18, depth: .floating) {
            VStack(alignment: .leading, spacing: 16) {
                header
                metrics
                taskSummary
                actions
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(model.theme.primary)
                .frame(width: 42, height: 42)
                .background(model.theme.primary.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(model.t("session.outcome.title"))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text(model.t("session.outcome.subtitle"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(model.theme.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button {
                model.dismissSessionOutcome()
            } label: {
                Image(systemName: "xmark")
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .icon))
            .help(model.t("session.outcome.dismiss"))
        }
    }

    private var metrics: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 14) {
                metric(
                    title: model.t("session.outcome.planned"),
                    value: outcome.record.plannedSeconds.focusClock,
                    symbolName: "calendar.badge.clock"
                )
                metric(
                    title: model.t("session.outcome.honest"),
                    value: outcome.record.honestFocusSeconds.focusClock,
                    symbolName: "clock.badge.checkmark"
                )
                metric(
                    title: model.t("session.outcome.distractions"),
                    value: "\(outcome.record.distractionCount)",
                    symbolName: "shield.lefthalf.filled"
                )
            }

            VStack(spacing: 10) {
                metric(
                    title: model.t("session.outcome.planned"),
                    value: outcome.record.plannedSeconds.focusClock,
                    symbolName: "calendar.badge.clock"
                )
                metric(
                    title: model.t("session.outcome.honest"),
                    value: outcome.record.honestFocusSeconds.focusClock,
                    symbolName: "clock.badge.checkmark"
                )
                metric(
                    title: model.t("session.outcome.distractions"),
                    value: "\(outcome.record.distractionCount)",
                    symbolName: "shield.lefthalf.filled"
                )
            }
        }
    }

    private func metric(title: String, value: String, symbolName: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbolName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(model.theme.primary)
                .frame(width: 26, height: 26)
                .background(model.theme.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(model.theme.mutedText)
                    .textCase(.uppercase)
                Text(value)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var taskSummary: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Image(systemName: outcome.task == nil ? "tray" : "target")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(model.theme.primary)
                Text(taskTitle)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Spacer()
                Text(model.timerModeTitle(outcome.record.mode))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(model.theme.mutedText)
            }

            Text(taskDetail)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(model.theme.mutedText)
                .fixedSize(horizontal: false, vertical: true)

            if let task = outcome.task, task.timingMode == .timed {
                ProgressView(value: task.completed, total: max(1, task.estimate))
                    .tint(model.theme.primary)
            }
        }
        .padding(14)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(model.theme.highlight.opacity(0.12), lineWidth: 1)
        }
    }

    private var actions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                actionButtons
            }
            VStack(spacing: 10) {
                actionButtons
            }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        Button {
            model.completeOutcomeTask()
        } label: {
            Label(model.t("session.outcome.completeTask"), systemImage: "checkmark.circle.fill")
        }
        .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .primary))
        .disabled(outcome.record.taskID == nil)
        .opacity(outcome.record.taskID == nil ? 0.48 : 1)

        Button {
            model.continueOutcomeTask()
        } label: {
            Label(model.t("session.outcome.continueTask"), systemImage: "arrow.uturn.forward")
        }
        .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))
        .disabled(outcome.record.taskID == nil)
        .opacity(outcome.record.taskID == nil ? 0.48 : 1)

        Button {
            model.startNextSessionFromOutcome()
        } label: {
            Label(model.t("session.outcome.startNext"), systemImage: "play.fill")
        }
        .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))
    }

    private var taskTitle: String {
        outcome.record.taskTitle ?? outcome.task?.title ?? model.t("session.outcome.noTask")
    }

    private var taskDetail: String {
        guard let task = outcome.task else {
            return model.t("session.outcome.noTask.detail")
        }

        if task.timingMode == .checklist {
            return model.t("session.outcome.checklist.detail")
        }

        return "\(model.t("session.outcome.taskProgress")) \(task.completed.focusClock) / \(task.estimate.focusClock)"
    }
}

private struct AnalyticsStripView: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    var body: some View {
        LiquidGlassPanel(radius: 20, padding: 18) {
            HStack(alignment: .top, spacing: 14) {
                MetricTile(
                    title: model.t("focus.score"),
                    value: "\(model.dailySummary.focusScore)",
                    detail: model.t("focus.score.detail"),
                    symbolName: "checkmark.seal",
                    accent: model.theme.primary
                )
                MetricTile(
                    title: model.t("focus.sessions"),
                    value: "\(model.dailySummary.sessionsCompleted)",
                    detail: model.t("analytics.sessionsDetail"),
                    symbolName: "checklist.checked",
                    accent: .orange
                )
                MetricTile(
                    title: model.t("focus.honestTime"),
                    value: model.dailySummary.honestFocusSeconds.focusClock,
                    detail: model.t("analytics.honestFocusDetail"),
                    symbolName: "clock.badge.checkmark",
                    accent: model.theme.secondary
                )

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(model.t("focus.heatmap"))
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
                        Text(model.t("focus.thisWeek"))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(model.theme.mutedText)
                    }
                    HeatmapMiniView(
                        values: model.focusHeatmapValues,
                        low: Color(hex: model.theme.heatmapLowHex),
                        high: Color(hex: model.theme.heatmapHighHex)
                    )
                    Text(model.t("analytics.heatmapDetail"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(model.theme.mutedText)
                }
                .frame(minWidth: 230, alignment: .leading)
                .padding(14)
                .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }
}

private struct FocusContextRailView: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @EnvironmentObject private var timerPresentation: FocusTimerPresentationState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            LiquidGlassPanel(radius: 18, padding: 16) {
                VStack(alignment: .leading, spacing: 13) {
                    HStack {
                        Label(model.presetTitle(model.selectedPreset), systemImage: model.selectedPreset.mode.symbolName)
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
                        Text(model.statusTitle(timerPresentation.snapshot.status))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(model.theme.primary)
                    }

                    HStack {
                        Text(model.t("timer.nextPhase"))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(model.theme.mutedText)
                        Spacer()
                        Text(model.phaseTitle(timerPresentation.snapshot.activeSegment.phase))
                            .font(.system(size: 12, weight: .bold))
                    }

                    ProgressView(value: timerPresentation.snapshot.progress)
                        .tint(model.theme.primary)
                }
            }

            LiquidGlassPanel(radius: 18, padding: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label(model.t("strict.mode"), systemImage: model.strictModeEnabled ? "shield.checkered" : "shield")
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
                        Text(model.strictModeEnabled ? model.t("strict.active") : model.t("strict.off"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(model.strictModeEnabled ? model.theme.strict : model.theme.mutedText)
                    }

                    HStack {
                        Text(model.t("strict.blockedApps"))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(model.theme.mutedText)
                        Spacer()
                        Text("\(model.enabledAppRuleCount)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                    }
                }
            }
        }
        .padding(20)
    }
}

private struct ProjectEditorSheet: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var draft: FocusProject

    let onSave: (FocusProject) -> Void
    let onDelete: (FocusProject) -> Void

    init(project: FocusProject, onSave: @escaping (FocusProject) -> Void, onDelete: @escaping (FocusProject) -> Void) {
        _draft = State(initialValue: project)
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(model.t("projects.edit"))
                .font(.system(size: 22, weight: .bold, design: .rounded))

            VStack(alignment: .leading, spacing: 10) {
                Text(model.t("projects.name"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(model.theme.mutedText)
                TextField(model.t("projects.name"), text: $draft.name)
                    .textFieldStyle(GlassTextFieldStyle(theme: model.theme))

                Text(model.t("projects.detail"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(model.theme.mutedText)
                TextField(model.t("projects.detail"), text: $draft.detail, axis: .vertical)
                    .textFieldStyle(GlassTextFieldStyle(theme: model.theme))

                Text(model.t("projects.notes"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(model.theme.mutedText)
                TextField(model.t("projects.notes.placeholder"), text: $draft.notes, axis: .vertical)
                    .textFieldStyle(GlassTextFieldStyle(theme: model.theme))
                    .lineLimit(4...8)
            }

            HStack {
                Button(role: .destructive) {
                    onDelete(draft)
                    dismiss()
                } label: {
                    Label(model.t("common.delete"), systemImage: "trash")
                }
                .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .danger))

                Spacer()

                Button(model.t("common.cancel")) {
                    dismiss()
                }
                .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))

                Button(model.t("common.save")) {
                    onSave(draft)
                    dismiss()
                }
                .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .primary))
            }
        }
        .padding(24)
        .frame(width: 460)
        .background(model.theme.background)
        .foregroundStyle(model.theme.text)
    }
}

private struct TaskEditorSheet: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var draft: FocusTask

    let onSave: (FocusTask) -> Void
    let onDelete: (FocusTask) -> Void

    init(task: FocusTask, onSave: @escaping (FocusTask) -> Void, onDelete: @escaping (FocusTask) -> Void) {
        _draft = State(initialValue: task)
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(model.t("tasks.edit"))
                .font(.system(size: 22, weight: .bold, design: .rounded))

            VStack(alignment: .leading, spacing: 10) {
                Text(model.t("tasks.name"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(model.theme.mutedText)
                TextField(model.t("tasks.name"), text: $draft.title)
                    .textFieldStyle(GlassTextFieldStyle(theme: model.theme))

                Text(model.t("focus.activeProject"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(model.theme.mutedText)
                GlassSelect(
                    selection: $draft.projectID,
                    options: [Optional<UUID>.none] + model.projects.map { Optional($0.id) },
                    title: projectTitle,
                    symbol: { $0 == nil ? "tray" : "folder" },
                    minWidth: 260
                )
                .help(model.t("focus.activeProject"))

                Text(model.t("tasks.type"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(model.theme.mutedText)
                GlassSelect(
                    selection: $draft.timingMode,
                    options: FocusTaskTimingMode.allCases,
                    title: model.taskTimingModeTitle,
                    symbol: { $0 == .timed ? "timer" : "checklist.checked" },
                    minWidth: 260
                )
                .help(model.t("help.taskTimingMode"))

                if draft.timingMode == .timed {
                    Text(model.t("tasks.estimate"))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(model.theme.mutedText)
                    TimeEstimatePicker(seconds: $draft.estimate)
                } else {
                    Label(model.t("tasks.checklist.detail"), systemImage: "checklist")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(model.theme.mutedText)
                        .padding(11)
                        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                }

                Toggle(model.t("tasks.done"), isOn: $draft.isDone)
                    .toggleStyle(.switch)
                    .help(model.t("tasks.done"))
            }

            HStack {
                Button(role: .destructive) {
                    onDelete(draft)
                    dismiss()
                } label: {
                    Label(model.t("common.delete"), systemImage: "trash")
                }
                .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .danger))

                Spacer()

                Button(model.t("common.cancel")) {
                    dismiss()
                }
                .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))

                Button(model.t("common.save")) {
                    onSave(draft)
                    dismiss()
                }
                .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .primary))
            }
        }
        .padding(24)
        .frame(width: 500)
        .background(model.theme.background)
        .foregroundStyle(model.theme.text)
    }

    private func projectTitle(_ projectID: UUID?) -> String {
        guard let projectID else { return model.t("projects.unassigned") }
        return model.projectName(for: projectID) ?? model.t("projects.unassigned")
    }
}

private struct TimeEstimatePicker: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @Binding var seconds: TimeInterval

    private let minutePresets = [5, 15, 25, 45, 60]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ForEach(minutePresets, id: \.self) { minutes in
                    Button("\(minutes)") {
                        seconds = TimeInterval(minutes * 60)
                    }
                    .buttonStyle(LiquidGlassButtonStyle(
                        theme: model.theme,
                        variant: Int(seconds / 60) == minutes ? .primary : .secondary
                    ))
                }
            }

            GlassStepper(value: minuteBinding, range: 1...240, step: 5) { value in
                "\(value) \(model.t("tasks.minutes"))"
            }
            .help(model.t("tasks.estimate"))

            GlassMinuteInputField(value: minuteBinding, range: 1...240)
        }
    }

    private var minuteBinding: Binding<Int> {
        Binding(
            get: { max(1, Int((seconds / 60).rounded())) },
            set: { seconds = TimeInterval(max(1, $0) * 60) }
        )
    }
}

private struct ProjectsScreen: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @State private var editingProject: FocusProject?

    var body: some View {
        LiquidGlassPanel(radius: 22) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text(model.t("projects.active"))
                        .font(.system(size: 15, weight: .bold))
                    Spacer()
                    Button {
                        editingProject = model.addProject()
                    } label: {
                        Label(model.t("projects.add"), systemImage: "plus")
                    }
                    .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .primary))
                }

                if model.projects.isEmpty {
                    EmptyInlineState(
                        symbol: "folder.badge.plus",
                        title: model.t("projects.empty.title"),
                        detail: model.t("projects.empty.detail")
                    )
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 340), spacing: 14)], spacing: 14) {
                        ForEach(model.projects) { project in
                            ProjectGridCard(
                                project: project,
                                taskCount: model.taskCount(for: project)
                            ) {
                                editingProject = project
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $editingProject) { project in
            ProjectEditorSheet(project: project) { updatedProject in
                model.updateProject(updatedProject)
                editingProject = nil
            } onDelete: { deletedProject in
                model.deleteProject(deletedProject)
                editingProject = nil
            }
            .environmentObject(model)
        }
    }
}

private struct ProjectGridCard: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    let project: FocusProject
    let taskCount: Int
    let onEdit: () -> Void

    private var isSelected: Bool {
        project.id == model.activeProjectID
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button {
                model.selectProject(project)
            } label: {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(isSelected ? model.theme.primary : model.theme.secondary)
                            .frame(width: 10, height: 10)
                        if isSelected {
                            Text(model.t("projects.selected"))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(model.theme.primary)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                    }

                    Text(project.name)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)

                    Text(project.detail)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(model.theme.mutedText)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)

                    Text("\(taskCount) \(model.t("projects.tasks"))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(model.theme.mutedText)
                        .lineLimit(1)
                }
                .padding(16)
                .padding(.trailing, 48)
                .frame(maxWidth: .infinity, minHeight: 178, alignment: .topLeading)
                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .glassHover(theme: model.theme, radius: 16, isActive: isSelected)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .help("\(project.name)\n\(project.detail)")

            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil")
                    .frame(width: FocusGlassHitTarget.compact, height: FocusGlassHitTarget.compact)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(model.theme.mutedText)
            .glassHover(theme: model.theme, radius: 10)
            .help(model.t("projects.edit"))
            .accessibilityLabel("\(model.t("projects.edit")): \(project.name)")
            .padding(10)
        }
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct AnalyticsScreen: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @State private var visibleTaskCount = 6
    @State private var visibleSessionCount = 8
    @State private var contentWidth: CGFloat = 0

    var body: some View {
        VStack(spacing: 18) {
            AnalyticsStripView()

            if contentWidth >= 900 {
                HStack(alignment: .top, spacing: 18) {
                    plannedActualCard
                        .frame(minWidth: 300, idealWidth: 330, maxWidth: 360)
                    modeEffectivenessCard
                        .frame(minWidth: 500)
                }
            } else {
                VStack(spacing: 18) {
                    plannedActualCard
                    modeEffectivenessCard
                }
            }

            projectBreakdownCard
            taskBreakdownCard
            recentSessionsCard
            distractionBreakdownCard
        }
        .frame(maxWidth: .infinity)
        .background {
            GeometryReader { proxy in
                Color.clear.preference(key: AnalyticsWidthPreferenceKey.self, value: proxy.size.width)
            }
        }
        .onPreferenceChange(AnalyticsWidthPreferenceKey.self) { width in
            Task { @MainActor in
                contentWidth = width
            }
        }
    }

    private var plannedActualCard: some View {
        LiquidGlassPanel(radius: 20) {
            VStack(alignment: .leading, spacing: 14) {
                Label(model.t("analytics.plannedVsActual"), systemImage: "chart.bar.xaxis")
                    .font(.system(size: 15, weight: .bold))

                HStack(spacing: 24) {
                    analyticsValue(model.t("analytics.planned"), value: model.dailySummary.plannedSeconds.focusClock)
                    analyticsValue(model.t("analytics.actual"), value: model.dailySummary.honestFocusSeconds.focusClock)
                    analyticsValue(model.t("analytics.effectiveness"), value: effectivenessText(model.dailySummary))
                }

                ProgressView(
                    value: model.dailySummary.honestFocusSeconds,
                    total: max(1, model.dailySummary.plannedSeconds)
                )
                .tint(model.theme.primary)
            }
        }
    }

    private var modeEffectivenessCard: some View {
        LiquidGlassPanel(radius: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Label(model.t("analytics.modeEffectiveness"), systemImage: "dial.medium")
                    .font(.system(size: 15, weight: .bold))

                if model.modeEffectivenessSummaries.isEmpty {
                    EmptyInlineState(
                        symbol: "timer",
                        title: model.t("analytics.empty.title"),
                        detail: model.t("analytics.empty.detail")
                    )
                } else {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 260), spacing: 10)],
                        alignment: .leading,
                        spacing: 10
                    ) {
                        ForEach(model.modeEffectivenessSummaries) { summary in
                            analyticsBreakdownRow(
                                title: model.timerModeTitle(summary.mode),
                                detail: "\(summary.sessionsCompleted) \(model.t("analytics.sessionsShort")) · \(summary.distractionCount) \(model.t("analytics.distractionsShort"))",
                                value: summary.honestFocusSeconds.focusClock,
                                progress: summary.effectiveness
                            )
                        }
                    }
                }
            }
        }
    }

    private var projectBreakdownCard: some View {
        LiquidGlassPanel(radius: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Label(model.t("analytics.byProject"), systemImage: "folder.badge.gearshape")
                    .font(.system(size: 15, weight: .bold))

                if model.projectFocusSummaries.isEmpty {
                    EmptyInlineState(
                        symbol: "chart.xyaxis.line",
                        title: model.t("analytics.empty.title"),
                        detail: model.t("analytics.empty.detail")
                    )
                } else {
                    ForEach(model.projectFocusSummaries) { summary in
                        analyticsBreakdownRow(
                            title: summary.projectName.isEmpty ? model.t("projects.unassigned") : summary.projectName,
                            detail: "\(model.t("analytics.planned")) \(summary.plannedSeconds.focusClock) · \(summary.sessionsCompleted) \(model.t("analytics.sessionsShort"))",
                            value: summary.honestFocusSeconds.focusClock,
                            progress: summary.effectiveness
                        )
                    }
                }
            }
        }
    }

    private var recentSessionsCard: some View {
        LiquidGlassPanel(radius: 20) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(model.t("analytics.recentSessions"), systemImage: "clock.arrow.circlepath")
                        .font(.system(size: 15, weight: .bold))
                    Spacer(minLength: 12)
                    CompactCountBadge(value: model.recentSessions.count, color: model.theme.primary)
                }

                if model.recentSessions.isEmpty {
                    EmptyInlineState(
                        symbol: "clock.badge.questionmark",
                        title: model.t("analytics.empty.title"),
                        detail: model.t("analytics.empty.detail")
                    )
                } else {
                    ForEach(Array(model.recentSessions.prefix(visibleSessionCount))) { session in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: session.mode.symbolName)
                                .foregroundStyle(model.theme.primary)
                                .frame(width: 28, height: 28)
                                .background(model.theme.primary.opacity(0.13), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.taskTitle ?? (session.projectName.isEmpty ? model.t("projects.unassigned") : session.projectName))
                                    .font(.system(size: 13, weight: .bold))
                                    .lineLimit(2)
                                Text("\(session.startedAt.formatted(date: .abbreviated, time: .shortened)) · \(model.timerModeTitle(session.mode))")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(model.theme.mutedText)
                            }

                            Spacer(minLength: 12)

                            VStack(alignment: .trailing, spacing: 3) {
                                Text(session.honestFocusSeconds.focusClock)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(model.theme.primary)
                                Text("\(model.t("analytics.planned")) \(session.plannedSeconds.focusClock)")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(model.theme.mutedText)
                                Text(ratioPercentText(session.honestFocusSeconds / max(1, session.plannedSeconds)))
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(model.theme.primary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(model.theme.primary.opacity(0.12), in: Capsule())
                                    .accessibilityLabel(
                                        "\(model.t("analytics.effectiveness")) \(ratioPercentText(session.honestFocusSeconds / max(1, session.plannedSeconds)))"
                                    )
                            }
                        }
                        .padding(11)
                        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    if model.recentSessions.count > 8 {
                        expansionButton(
                            visibleCount: $visibleSessionCount,
                            totalCount: model.recentSessions.count,
                            pageSize: 8
                        )
                    }
                }
            }
        }
    }

    private var taskBreakdownCard: some View {
        LiquidGlassPanel(radius: 20) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(model.t("analytics.byTask"), systemImage: "checklist")
                        .font(.system(size: 15, weight: .bold))
                    Spacer(minLength: 12)
                    CompactCountBadge(value: model.taskFocusSummaries.count, color: model.theme.primary)
                }

                if model.taskFocusSummaries.isEmpty {
                    EmptyInlineState(
                        symbol: "checklist.unchecked",
                        title: model.t("analytics.task.empty.title"),
                        detail: model.t("analytics.task.empty.detail")
                    )
                } else {
                    LazyVGrid(
                        columns: taskGridColumns,
                        alignment: .leading,
                        spacing: 10
                    ) {
                        ForEach(Array(model.taskFocusSummaries.prefix(visibleTaskCount))) { summary in
                            TaskAnalyticsCard(
                                presentation: model.taskAnalyticsPresentation(for: summary)
                            )
                        }
                    }

                    if model.taskFocusSummaries.count > 6 {
                        expansionButton(
                            visibleCount: $visibleTaskCount,
                            totalCount: model.taskFocusSummaries.count,
                            pageSize: 6
                        )
                    }
                }
            }
        }
    }

    private var taskGridColumns: [GridItem] {
        if model.taskFocusSummaries.count == 1 {
            return [GridItem(.flexible())]
        }
        return [GridItem(.adaptive(minimum: 300), spacing: 10)]
    }

    private var distractionBreakdownCard: some View {
        LiquidGlassPanel(radius: 20) {
            VStack(alignment: .leading, spacing: 14) {
                Label(model.t("analytics.distractionBreakdown"), systemImage: "shield.lefthalf.filled.badge.checkmark")
                    .font(.system(size: 15, weight: .bold))

                if model.distractionHistory.isEmpty {
                    EmptyInlineState(
                        symbol: "shield.slash",
                        title: model.t("analytics.noDistractionHistory"),
                        detail: model.t("analytics.noDistractionHistory.detail")
                    )
                } else {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 18) {
                            countList(title: model.t("analytics.byProject"), rows: distractionProjectRows)
                            countList(title: model.t("analytics.byMode"), rows: distractionModeRows)
                        }

                        VStack(spacing: 18) {
                            countList(title: model.t("analytics.byProject"), rows: distractionProjectRows)
                            countList(title: model.t("analytics.byMode"), rows: distractionModeRows)
                        }
                    }
                }
            }
        }
    }

    private func analyticsValue(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(model.theme.mutedText)
            Text(value)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func analyticsBreakdownRow(title: String, detail: String, value: String, progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .lineLimit(2)
                    Text(detail)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(model.theme.mutedText)
                }
                Spacer(minLength: 12)
                VStack(alignment: .trailing, spacing: 3) {
                    Text(value)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(model.theme.primary)
                    Text(ratioPercentText(progress))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(model.theme.mutedText)
                }
            }
            ProgressView(value: progress)
                .tint(model.theme.primary)
        }
        .padding(10)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }

    private func countList(title: String, rows: [AnalyticsCountRow]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(model.theme.mutedText)
            ForEach(rows) { row in
                HStack {
                    Text(row.title)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(2)
                    Spacer(minLength: 10)
                    Text("\(row.count)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(model.theme.strict)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var distractionProjectRows: [AnalyticsCountRow] {
        let grouped = Dictionary(grouping: model.distractionHistory) { event in
            event.projectID?.uuidString ?? "unassigned"
        }
        return grouped.map { key, events in
            AnalyticsCountRow(
                id: key,
                title: events.first?.projectName.isEmpty == false ? events[0].projectName : model.t("projects.unassigned"),
                count: events.count
            )
        }
        .sorted { $0.count == $1.count ? $0.title < $1.title : $0.count > $1.count }
    }

    private var distractionModeRows: [AnalyticsCountRow] {
        Dictionary(grouping: model.distractionHistory, by: \.mode)
            .map { mode, events in
                AnalyticsCountRow(id: mode.rawValue, title: model.timerModeTitle(mode), count: events.count)
            }
            .sorted { $0.count == $1.count ? $0.title < $1.title : $0.count > $1.count }
    }

    private func effectivenessText(_ summary: DailyFocusSummary) -> String {
        guard summary.plannedSeconds > 0 else { return "0%" }
        return ratioPercentText(summary.honestFocusSeconds / summary.plannedSeconds)
    }

    private func ratioPercentText(_ ratio: Double) -> String {
        let clamped = min(1, max(0, ratio))
        if clamped > 0, clamped < 0.01 {
            return "<1%"
        }
        return "\(Int((clamped * 100).rounded()))%"
    }

    private func expansionButton(
        visibleCount: Binding<Int>,
        totalCount: Int,
        pageSize: Int
    ) -> some View {
        let showsAll = visibleCount.wrappedValue >= totalCount
        let remaining = min(pageSize, max(0, totalCount - visibleCount.wrappedValue))
        let title = showsAll
            ? model.t("common.showLess")
            : "\(model.t("common.showMore")) (\(remaining))"

        return Button {
            withAnimation(.easeInOut(duration: model.theme.animationDuration(0.18))) {
                visibleCount.wrappedValue = showsAll
                    ? pageSize
                    : min(totalCount, visibleCount.wrappedValue + pageSize)
            }
        } label: {
            Label(title, systemImage: showsAll ? "chevron.up" : "chevron.down")
                .font(.system(size: 11, weight: .bold))
                .frame(maxWidth: .infinity, minHeight: FocusGlassHitTarget.compact)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(model.theme.mutedText)
        .glassHover(theme: model.theme, radius: 10)
        .accessibilityLabel(title)
    }
}

private struct TaskAnalyticsCard: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    let presentation: TaskAnalyticsPresentation

    private var summary: TaskFocusSummary {
        presentation.summary
    }

    private var kindTitle: String {
        if presentation.isHistorical {
            return model.t("analytics.task.historical")
        }
        return presentation.timingMode.map(model.taskTimingModeTitle) ?? model.t("analytics.task.historical")
    }

    private var focusMetricTitle: String {
        presentation.showsEffectiveness
            ? model.t("analytics.actual")
            : model.t("analytics.task.associatedFocus")
    }

    private var lastFocusText: String {
        summary.lastFocusedAt.formatted(
            Date.FormatStyle(
                date: .abbreviated,
                time: .omitted,
                locale: Locale(identifier: model.language.resolvedCode)
            )
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: presentation.isHistorical ? "clock.arrow.circlepath" : taskSymbol)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(presentation.isHistorical ? model.theme.mutedText : model.theme.primary)
                    .frame(width: 30, height: 30)
                    .background(
                        (presentation.isHistorical ? model.theme.mutedText : model.theme.primary).opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(presentation.title)
                        .font(.system(size: 14, weight: .bold))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(presentation.projectName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(model.theme.mutedText)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Text(kindTitle)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(presentation.isHistorical ? model.theme.mutedText : model.theme.primary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(
                        (presentation.isHistorical ? model.theme.mutedText : model.theme.primary).opacity(0.12),
                        in: Capsule()
                    )
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) {
                    metric(focusMetricTitle, value: summary.honestFocusSeconds.focusClock)
                    metric(model.t("analytics.sessionsShort"), value: "\(summary.sessionsCompleted)")
                    metric(model.t("analytics.distractionsShort"), value: "\(summary.distractionCount)")
                }

                VStack(alignment: .leading, spacing: 8) {
                    metric(focusMetricTitle, value: summary.honestFocusSeconds.focusClock)
                    HStack(spacing: 16) {
                        metric(model.t("analytics.sessionsShort"), value: "\(summary.sessionsCompleted)")
                        metric(model.t("analytics.distractionsShort"), value: "\(summary.distractionCount)")
                    }
                }
            }

            if presentation.showsEffectiveness {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(model.t("analytics.planned")) \(summary.plannedSeconds.focusClock)")
                        Spacer(minLength: 8)
                        Text("\(model.t("analytics.effectiveness")) \(effectivenessText)")
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(model.theme.mutedText)

                    ProgressView(value: summary.effectiveness)
                        .tint(model.theme.primary)
                }
            }

            HStack(spacing: 5) {
                Image(systemName: "calendar")
                Text("\(model.t("analytics.task.lastFocus")) \(lastFocusText)")
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(model.theme.mutedText)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 170, alignment: .topLeading)
        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var taskSymbol: String {
        presentation.timingMode == .checklist ? "checklist.checked" : "timer"
    }

    private var effectivenessText: String {
        let clamped = min(1, max(0, summary.effectiveness))
        if clamped > 0, clamped < 0.01 {
            return "<1%"
        }
        return "\(Int((clamped * 100).rounded()))%"
    }

    private var accessibilityText: String {
        var parts = [
            presentation.title,
            presentation.projectName,
            kindTitle,
            "\(focusMetricTitle) \(summary.honestFocusSeconds.focusClock)",
            "\(summary.sessionsCompleted) \(model.t("analytics.sessionsShort"))",
            "\(summary.distractionCount) \(model.t("analytics.distractionsShort"))",
            "\(model.t("analytics.task.lastFocus")) \(lastFocusText)"
        ]
        if presentation.showsEffectiveness {
            parts.append("\(model.t("analytics.planned")) \(summary.plannedSeconds.focusClock)")
            parts.append("\(model.t("analytics.effectiveness")) \(effectivenessText)")
        }
        return parts.joined(separator: ", ")
    }

    private func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(model.theme.mutedText)
                .lineLimit(1)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(model.theme.text)
                .monospacedDigit()
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AnalyticsCountRow: Identifiable {
    let id: String
    let title: String
    let count: Int
}

private struct AnalyticsWidthPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct StrictModeScreen: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @State private var visibleHistoryCount = 8

    var body: some View {
        VStack(spacing: 18) {
            ViewThatFits(in: .horizontal) {
                content
                VStack(alignment: .leading, spacing: 18) {
                    strictStatusCard
                    strictSummaryCard
                }
            }

            strictHistoryCard
        }
    }

    private var content: some View {
        HStack(alignment: .top, spacing: 18) {
            strictStatusCard
            strictSummaryCard
        }
    }

    private var strictStatusCard: some View {
        LiquidGlassPanel(radius: 22) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    Image(systemName: model.strictModeEnabled ? "shield.checkered" : "shield")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(model.strictModeEnabled ? model.theme.strict : model.theme.mutedText)
                        .frame(width: 42, height: 42)
                        .background(model.theme.strict.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.t("strict.title"))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Text(model.strictModeEnabled ? model.t("strict.active") : model.t("strict.off"))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(model.strictModeEnabled ? model.theme.strict : model.theme.mutedText)
                    }

                    Spacer()

                    Toggle("", isOn: $model.strictModeEnabled)
                        .toggleStyle(GlassCheckboxToggleStyle(theme: model.theme))
                        .labelsHidden()
                }

                Text(model.t("strict.settingsOnly"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(model.theme.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var strictSummaryCard: some View {
        LiquidGlassPanel(radius: 22) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(model.t("strict.rules"))
                        .font(.system(size: 15, weight: .bold))
                    Spacer()
                    Text("\(model.distractionRules.filter(\.isEnabled).count)")
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .foregroundStyle(model.theme.primary)
                }

                if model.distractionRules.isEmpty {
                    EmptyInlineState(
                        symbol: "shield.slash",
                        title: model.t("strict.empty.title"),
                        detail: model.t("strict.empty.detail")
                    )
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("\(model.enabledAppRuleCount) \(model.t("strict.apps"))", systemImage: "app.badge")
                        Label("\(model.enabledSiteRuleCount) \(model.t("strict.sites"))", systemImage: "globe")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(model.theme.mutedText)
                }

                Button {
                    model.selectedSettingsTab = .strictMode
                    model.selectedSidebarItem = .settings
                } label: {
                    Label(model.t("strict.manage"), systemImage: "lock.shield.fill")
                }
                .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))
            }
        }
    }

    private var strictHistoryCard: some View {
        LiquidGlassPanel(radius: 22) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label(model.t("strict.history"), systemImage: "clock.arrow.circlepath")
                        .font(.system(size: 15, weight: .bold))
                    if !model.distractionHistory.isEmpty {
                        CompactCountBadge(value: model.distractionHistory.count, color: model.theme.strict)
                    }
                    Spacer(minLength: 12)
                    if !model.distractionHistory.isEmpty {
                        Button(role: .destructive) {
                            model.clearDistractionHistory()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 13, weight: .bold))
                                .frame(width: FocusGlassHitTarget.compact, height: FocusGlassHitTarget.compact)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(model.theme.strict)
                        .glassHover(theme: model.theme, radius: 10)
                        .help(model.t("strict.history.clear"))
                        .accessibilityLabel(model.t("strict.history.clear"))
                    }
                }

                if model.distractionHistory.isEmpty {
                    EmptyInlineState(
                        symbol: "shield.slash",
                        title: model.t("strict.history.empty"),
                        detail: model.t("strict.history.empty.detail")
                    )
                } else {
                    ForEach(Array(model.distractionHistory.prefix(visibleHistoryCount))) { event in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: actionSymbol(event.action))
                                .foregroundStyle(actionColor(event.action))
                                .frame(width: 30, height: 30)
                                .background(actionColor(event.action).opacity(0.13), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                            VStack(alignment: .leading, spacing: 5) {
                                HStack(alignment: .firstTextBaseline, spacing: 10) {
                                    Text(event.targetLabel)
                                        .font(.system(size: 13, weight: .bold))
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .layoutPriority(1)

                                    Spacer(minLength: 0)

                                    Image(systemName: event.targetKind == .app ? "app.badge" : "globe")
                                        .foregroundStyle(model.theme.mutedText)
                                        .accessibilityLabel(event.targetKind == .app ? model.t("strict.apps") : model.t("strict.sites"))
                                }

                                Text("\(model.actionTitle(event.action)) · \(event.occurredAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(actionColor(event.action))
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(historyContext(event))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(model.theme.mutedText)
                                    .lineLimit(2)

                                if let taskTitle = event.taskTitle, !taskTitle.isEmpty {
                                    Text(taskTitle)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(model.theme.mutedText)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(12)
                        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    if model.distractionHistory.count > 8 {
                        historyExpansionButton
                    }
                }
            }
        }
    }

    private func historyContext(_ event: DistractionEventRecord) -> String {
        let project = event.projectName.isEmpty ? model.t("projects.unassigned") : event.projectName
        return "\(project) · \(model.timerModeTitle(event.mode))"
    }

    private var historyExpansionButton: some View {
        let showsAll = visibleHistoryCount >= model.distractionHistory.count
        let remaining = min(8, max(0, model.distractionHistory.count - visibleHistoryCount))
        let title = showsAll
            ? model.t("common.showLess")
            : "\(model.t("common.showMore")) (\(remaining))"

        return Button {
            withAnimation(.easeInOut(duration: model.theme.animationDuration(0.18))) {
                visibleHistoryCount = showsAll
                    ? 8
                    : min(model.distractionHistory.count, visibleHistoryCount + 8)
            }
        } label: {
            Label(title, systemImage: showsAll ? "chevron.up" : "chevron.down")
                .font(.system(size: 11, weight: .bold))
                .frame(maxWidth: .infinity, minHeight: FocusGlassHitTarget.compact)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(model.theme.mutedText)
        .glassHover(theme: model.theme, radius: 10)
        .accessibilityLabel(title)
    }

    private func actionSymbol(_ action: DistractionAction) -> String {
        switch action {
        case .warn: "exclamationmark.triangle"
        case .hide: "eye.slash"
        case .pauseSession: "pause.circle"
        case .quitAfterOptIn: "xmark.circle"
        }
    }

    private func actionColor(_ action: DistractionAction) -> Color {
        switch action {
        case .warn: model.theme.secondary
        case .hide: model.theme.primary
        case .pauseSession, .quitAfterOptIn: model.theme.strict
        }
    }
}

private struct CompactCountBadge: View {
    let value: Int
    let color: Color

    var body: some View {
        Text("\(value)")
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(color.opacity(0.12), in: Capsule())
    }
}

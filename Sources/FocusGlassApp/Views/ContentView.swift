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

                MainWindowBuildBadge()
                    .padding(.trailing, 18)
                    .padding(.bottom, 14)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .allowsHitTesting(false)
                    .zIndex(1)

                if showsLaunchSequence {
                    FocusGlassLaunchOverlay(theme: model.theme, reduceMotion: accessibilityReduceMotion)
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
        ScrollView {
            VStack(spacing: 22) {
                HeaderView()
                if model.needsPermissionAttention {
                    PermissionBannerView()
                }
                RouteContentView()
                if showsContextRail && model.selectedSidebarItem == .focusToday {
                    FocusContextRailView()
                }
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

        let duration = accessibilityReduceMotion ? Duration.milliseconds(280) : .milliseconds(1180)
        try? await Task.sleep(for: duration)
        withAnimation(.easeInOut(duration: accessibilityReduceMotion ? 0.16 : 0.34)) {
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

    @State private var isRevealed = false
    @State private var isSettled = false

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            Circle()
                .fill(theme.glow.opacity(0.26))
                .frame(width: 380, height: 380)
                .blur(radius: 88)
                .scaleEffect(isRevealed && !reduceMotion ? 1.08 : 0.82)

            VStack(spacing: 22) {
                ZStack {
                    RoundedRectangle(cornerRadius: 42, style: .continuous)
                        .fill(theme.highlight.opacity(0.10))
                        .frame(width: 176, height: 176)
                        .blur(radius: 24)
                        .opacity(isSettled || reduceMotion ? 1 : 0)

                    iconMark
                        .frame(width: 144, height: 144)
                }
                .scaleEffect(isRevealed || reduceMotion ? 1 : 0.84)
                .rotation3DEffect(.degrees(isRevealed || reduceMotion ? 0 : -7), axis: (x: 1, y: 0, z: 0))
                .offset(y: isRevealed || reduceMotion ? 0 : 12)

                Text("FocusGlass")
                    .font(.system(size: 35, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.text)
                    .opacity(isSettled || reduceMotion ? 1 : 0.18)
                    .offset(y: isSettled || reduceMotion ? 0 : 8)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.primary.opacity(0.18),
                                theme.glow.opacity(0.42),
                                theme.highlight.opacity(0.18)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: isSettled || reduceMotion ? 118 : 34, height: 4)
                    .opacity(isSettled || reduceMotion ? 1 : 0.24)
            }
            .shadow(color: theme.glow.opacity(0.20), radius: 26, x: 0, y: 16)
        }
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else {
                isRevealed = true
                isSettled = true
                return
            }

            withAnimation(.spring(duration: 0.72, bounce: 0.16)) {
                isRevealed = true
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(260))
                withAnimation(.easeInOut(duration: 0.34)) {
                    isSettled = true
                }
            }
        }
    }

    private var iconMark: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: theme.backgroundTopHex),
                            Color(hex: theme.backgroundMidHex),
                            Color(hex: theme.backgroundBottomHex)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(theme.primary.opacity(0.08))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(theme.highlight.opacity(0.22), lineWidth: 1.3)
                }

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            theme.highlight.opacity(0.24),
                            theme.elevatedSurface.opacity(0.88),
                            theme.surface.opacity(0.96)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(28)
                .overlay {
                    Circle()
                        .stroke(theme.highlight.opacity(0.28), lineWidth: 1.4)
                        .padding(29)
                }

            ForEach(0..<28, id: \.self) { index in
                Capsule()
                    .fill(theme.text.opacity(index.isMultiple(of: 4) ? 0.20 : 0.10))
                    .frame(width: 2, height: index.isMultiple(of: 4) ? 10 : 6)
                    .offset(y: -47)
                    .rotationEffect(.degrees(Double(index) * (360 / 28)))
                    .opacity(isRevealed || reduceMotion ? 1 : 0)
                    .scaleEffect(isRevealed || reduceMotion ? 1 : 0.72)
            }

            Circle()
                .trim(from: 0.05, to: isSettled || reduceMotion ? 0.82 : (isRevealed ? 0.70 : 0.15))
                .stroke(
                    AngularGradient(
                        colors: [theme.primary.opacity(0.72), theme.primary, theme.glow.opacity(0.94)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-134))
                .padding(22)

            clockHands

            Circle()
                .fill(theme.text)
                .frame(width: 10, height: 10)

            Circle()
                .fill(theme.primary)
                .frame(width: 11, height: 11)
                .overlay {
                    Circle()
                        .stroke(theme.primary.opacity(0.24), lineWidth: 5)
                }
                .offset(x: 35, y: -35)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [.clear, theme.highlight.opacity(0.72), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 72, height: 5)
                .rotationEffect(.degrees(-16))
                .offset(x: isSettled || reduceMotion ? 30 : -24, y: -42)
                .opacity(isSettled || reduceMotion ? 0.82 : 0.18)
        }
    }

    private var clockHands: some View {
        ZStack {
            Capsule()
                .fill(theme.text.opacity(0.94))
                .frame(width: 5, height: 33)
                .offset(y: -14)
                .rotationEffect(.degrees(isRevealed && !reduceMotion ? 0 : -36), anchor: .bottom)

            Capsule()
                .fill(theme.text.opacity(0.94))
                .frame(width: 5, height: 30)
                .offset(y: -13)
                .rotationEffect(.degrees(isRevealed && !reduceMotion ? 118 : 70), anchor: .bottom)
        }
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
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(SidebarItem.allCases) { item in
                    Button {
                        model.selectedSidebarItem = item
                    } label: {
                        Label(model.sidebarTitle(item), systemImage: item.symbolName)
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .foregroundStyle(model.selectedSidebarItem == item ? model.theme.text : model.theme.mutedText)
                    }
                    .buttonStyle(.plain)
                    .glassHover(theme: model.theme, radius: 14, isActive: model.selectedSidebarItem == item)
                    .accessibilityAddTraits(model.selectedSidebarItem == item ? .isSelected : [])
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
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

                timerStack(size: 360, clockSize: 72)
                    .frame(minWidth: 360)

                FocusTaskPanel()
                    .frame(width: 360)
            }

            VStack(spacing: 18) {
                timerStack(size: 318, clockSize: 62)
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

    private func timerStack(size: CGFloat, clockSize: CGFloat) -> some View {
        VStack(spacing: 18) {
            CircularTimerView(
                clockText: model.primaryClockText,
                phase: model.phaseTitle(model.engineSnapshot.activeSegment.phase),
                progress: model.engineSnapshot.progress,
                theme: model.theme,
                statusText: model.statusTitle(model.engineSnapshot.status),
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
            DisclosureGroup(isExpanded: $isNotesExpanded) {
                TextField(model.t("projects.notes.placeholder"), text: activeProjectNotesBinding, axis: .vertical)
                    .textFieldStyle(GlassTextFieldStyle(theme: model.theme))
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(3...7)
                    .padding(.top, 8)
            } label: {
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
            }
            .padding(13)
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
                            .frame(width: 28, height: 28)
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
                ScrollView {
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
            .disabled(!model.canSkipSegment)
            .opacity(model.canSkipSegment ? 1 : 0.42)
            .help(model.t("help.timerSkip"))
        }
    }

    private var primaryTitle: String {
        switch model.engineSnapshot.status {
        case .running: model.t("timer.pause")
        case .paused: model.t("timer.resume")
        case .idle, .completed: model.t("timer.start")
        }
    }
}

private struct FocusTaskCardRow: View {
    @EnvironmentObject private var model: FocusGlassViewModel
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
                    .frame(width: 30, height: 30)
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
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .glassHover(theme: model.theme, radius: 12, isActive: isSelected)
            .help(model.t("tasks.selectForSession"))
            .accessibilityAddTraits(isSelected ? .isSelected : [])

            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil")
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(model.theme.mutedText)
            .opacity(isHovering || isSelected ? 1 : 0.58)
            .glassHover(theme: model.theme, radius: 8)
            .help(model.t("tasks.edit"))
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
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
            withAnimation(.easeInOut(duration: 0.14)) {
                isHovering = hovering
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

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            LiquidGlassPanel(radius: 18, padding: 16) {
                VStack(alignment: .leading, spacing: 13) {
                    HStack {
                        Label(model.presetTitle(model.selectedPreset), systemImage: model.selectedPreset.mode.symbolName)
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
                        Text(model.statusTitle(model.engineSnapshot.status))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(model.theme.primary)
                    }

                    HStack {
                        Text(model.t("timer.nextPhase"))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(model.theme.mutedText)
                        Spacer()
                        Text(model.phaseTitle(model.engineSnapshot.activeSegment.phase))
                            .font(.system(size: 12, weight: .bold))
                    }

                    ProgressView(value: model.engineSnapshot.progress)
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
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 14)], spacing: 14) {
                        ForEach(model.projects) { project in
                            HStack(alignment: .top, spacing: 10) {
                                Button {
                                    model.selectProject(project)
                                } label: {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Circle()
                                                .fill(project.id == model.activeProjectID ? model.theme.primary : model.theme.secondary)
                                                .frame(width: 10, height: 10)
                                            if project.id == model.activeProjectID {
                                                Text(model.t("projects.selected"))
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundStyle(model.theme.primary)
                                            }
                                            Spacer()
                                        }

                                        Text(project.name)
                                            .font(.system(size: 19, weight: .bold, design: .rounded))
                                            .lineLimit(2)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Text(project.detail)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(model.theme.mutedText)
                                            .lineLimit(3)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Text("\(model.tasks(for: project).count) \(model.t("projects.tasks"))")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(model.theme.mutedText)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .glassHover(theme: model.theme, radius: 12, isActive: project.id == model.activeProjectID)
                                .accessibilityAddTraits(project.id == model.activeProjectID ? .isSelected : [])

                                Button {
                                    editingProject = project
                                } label: {
                                    Image(systemName: "pencil")
                                        .frame(width: 28, height: 28)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(model.theme.mutedText)
                                .glassHover(theme: model.theme, radius: 9)
                                .help(model.t("projects.edit"))
                                .accessibilityLabel("\(model.t("projects.edit")): \(project.name)")
                            }
                            .padding(16)
                            .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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

private struct AnalyticsScreen: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    var body: some View {
        VStack(spacing: 18) {
            AnalyticsStripView()

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 18) {
                    plannedActualCard
                    modeEffectivenessCard
                }

                VStack(spacing: 18) {
                    plannedActualCard
                    modeEffectivenessCard
                }
            }

            projectBreakdownCard
            recentSessionsCard
            distractionBreakdownCard
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
                Label(model.t("analytics.recentSessions"), systemImage: "clock.arrow.circlepath")
                    .font(.system(size: 15, weight: .bold))

                if model.recentSessions.isEmpty {
                    EmptyInlineState(
                        symbol: "clock.badge.questionmark",
                        title: model.t("analytics.empty.title"),
                        detail: model.t("analytics.empty.detail")
                    )
                } else {
                    ForEach(Array(model.recentSessions.prefix(8))) { session in
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
                            }
                        }
                        .padding(11)
                        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
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
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(model.theme.primary)
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
        let percentage = Int((min(1, summary.honestFocusSeconds / summary.plannedSeconds) * 100).rounded())
        return "\(percentage)%"
    }
}

private struct AnalyticsCountRow: Identifiable {
    let id: String
    let title: String
    let count: Int
}

private struct StrictModeScreen: View {
    @EnvironmentObject private var model: FocusGlassViewModel

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
                    Spacer()
                    if !model.distractionHistory.isEmpty {
                        Button(model.t("strict.history.clear"), role: .destructive) {
                            model.clearDistractionHistory()
                        }
                        .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))
                    }
                }

                if model.distractionHistory.isEmpty {
                    EmptyInlineState(
                        symbol: "shield.slash",
                        title: model.t("strict.history.empty"),
                        detail: model.t("strict.history.empty.detail")
                    )
                } else {
                    ForEach(Array(model.distractionHistory.prefix(12))) { event in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: actionSymbol(event.action))
                                .foregroundStyle(actionColor(event.action))
                                .frame(width: 30, height: 30)
                                .background(actionColor(event.action).opacity(0.13), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.targetLabel)
                                    .font(.system(size: 13, weight: .bold))
                                    .lineLimit(2)
                                Text("\(model.actionTitle(event.action)) · \(event.occurredAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(model.theme.mutedText)
                                Text(historyContext(event))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(model.theme.mutedText)
                                    .lineLimit(2)
                            }

                            Spacer(minLength: 12)

                            Image(systemName: event.targetKind == .app ? "app.badge" : "globe")
                                .foregroundStyle(model.theme.mutedText)
                                .accessibilityLabel(event.targetKind == .app ? model.t("strict.apps") : model.t("strict.sites"))
                        }
                        .padding(11)
                        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
    }

    private func historyContext(_ event: DistractionEventRecord) -> String {
        let project = event.projectName.isEmpty ? model.t("projects.unassigned") : event.projectName
        let task = event.taskTitle.map { " · \($0)" } ?? ""
        return "\(project) · \(model.timerModeTitle(event.mode))\(task)"
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

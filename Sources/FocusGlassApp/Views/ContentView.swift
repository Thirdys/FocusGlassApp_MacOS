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

                        contentScroll(horizontalPadding: 28, verticalPadding: 26, showsContextRail: true)
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

        let duration = accessibilityReduceMotion ? Duration.milliseconds(280) : .milliseconds(920)
        try? await Task.sleep(for: duration)
        withAnimation(.easeInOut(duration: accessibilityReduceMotion ? 0.16 : 0.34)) {
            showsLaunchSequence = false
        }
    }
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
                iconMark
                    .frame(width: 144, height: 144)
                    .scaleEffect(isRevealed || reduceMotion ? 1 : 0.86)

                Text("FocusGlass")
                    .font(.system(size: 35, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.text)
                    .opacity(isRevealed || reduceMotion ? 1 : 0.22)
            }
            .shadow(color: theme.glow.opacity(0.20), radius: 26, x: 0, y: 16)
        }
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else {
                isRevealed = true
                return
            }

            withAnimation(.spring(duration: 0.72, bounce: 0.16)) {
                isRevealed = true
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

            Circle()
                .trim(from: 0.05, to: isRevealed || reduceMotion ? 0.70 : 0.15)
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
                .fill(theme.highlight.opacity(0.26))
                .frame(width: 42, height: 4)
                .rotationEffect(.degrees(-14))
                .offset(x: -19, y: -36)
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
        if width >= 1320 {
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
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 7) {
                Text(title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(model.theme.mutedText)
            }

            Spacer()

            HStack(spacing: 12) {
                Image(systemName: model.strictModeEnabled ? "shield.checkered" : "shield")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(model.strictModeEnabled ? model.theme.strict : model.theme.mutedText)
                Toggle("", isOn: $model.strictModeEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .help(model.t("help.strictMode"))

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
                                Text(project.detail)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(model.theme.mutedText)
                                    .lineLimit(1)
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
                VStack(alignment: .leading, spacing: 7) {
                    Text(model.t("focus.intent"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(model.theme.mutedText)
                    HStack(spacing: 10) {
                        TextField(model.t("focus.intent.placeholder"), text: $model.intention)
                            .textFieldStyle(.plain)
                            .font(.system(size: 15, weight: .medium))
                        Image(systemName: "pencil")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(model.theme.mutedText)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(.white.opacity(0.10), lineWidth: 1)
                    }
                }

                focusLayout
            }

            AnalyticsStripView()
        }
    }

    private var focusLayout: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 24) {
                ActiveProjectCard()
                    .frame(width: 250)

                Spacer(minLength: 0)

                timerStack(size: 360, clockSize: 72)

                Spacer(minLength: 0)

                FocusStackCard()
                    .frame(width: 286)
            }

            VStack(spacing: 18) {
                timerStack(size: 318, clockSize: 62)
                HStack(alignment: .top, spacing: 16) {
                    ActiveProjectCard()
                    FocusStackCard()
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
        GeometryReader { proxy in
            let compact = proxy.size.width < 760
            let columns = [
                GridItem(.adaptive(minimum: compact ? 150 : 170, maximum: 230), spacing: 10)
            ]

            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                ForEach(model.presets) { preset in
                    modeChip(for: preset)
                }
            }
        }
        .frame(minHeight: 92)
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

private struct ActiveProjectCard: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @State private var editingProject: FocusProject?

    var body: some View {
        LiquidGlassPanel(radius: 18, padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(model.t("focus.activeProject"))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(model.theme.mutedText)
                    GlassSelect(
                        selection: $model.activeProjectID,
                        options: [nil] + model.projects.map(\.id),
                        title: projectTitle,
                        symbol: { $0 == nil ? "tray" : "folder" },
                        minWidth: 218
                    )
                }

                Divider().opacity(0.14)

                if let activeProject = model.activeProjectID.flatMap({ id in model.projects.first { $0.id == id } }) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(activeProject.detail.isEmpty ? model.t("projects.new.detail") : activeProject.detail)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(model.theme.mutedText)
                            .lineLimit(3)

                        HStack(spacing: 8) {
                            Label("\(model.tasks(for: activeProject).count) \(model.t("projects.tasks"))", systemImage: "checklist.unchecked")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(model.theme.mutedText)

                            Spacer()

                            Button {
                                editingProject = activeProject
                            } label: {
                                Label(model.t("projects.edit"), systemImage: "pencil")
                                    .labelStyle(.iconOnly)
                                    .frame(width: 28, height: 28)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(model.theme.mutedText)
                            .glassHover(theme: model.theme, radius: 10)
                            .help(model.t("projects.edit"))
                        }
                    }
                } else {
                    Text(model.t("projects.empty.detail"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(model.theme.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    editingProject = model.addProject()
                } label: {
                    Label(model.t("projects.add"), systemImage: "plus")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(model.theme.mutedText)
                .glassHover(theme: model.theme, radius: 10)
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

    private func projectTitle(_ projectID: UUID?) -> String {
        projectID.flatMap(model.projectName(for:)) ?? model.t("projects.unassigned")
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

private struct FocusStackCard: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @State private var editingTask: FocusTask?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(model.activeProjectID == nil ? model.t("tasks.focusStack") : model.t("tasks.projectTasks"))
                    .font(.system(size: 14, weight: .bold))
                Spacer()
            }

            if model.activeTasks.isEmpty {
                EmptyInlineState(
                    symbol: "checklist.unchecked",
                    title: model.t("tasks.empty.title"),
                    detail: model.t("tasks.empty.detail")
                )
            } else {
                ForEach(model.activeTasks) { task in
                    HStack(spacing: 10) {
                        Button {
                            model.toggleTask(task)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(task.isDone ? model.theme.primary : model.theme.mutedText)
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(task.title)
                                            .font(.system(size: 13, weight: .bold))
                                            .lineLimit(1)
                                        Spacer()
                                        Text(task.estimate.focusClock)
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundStyle(model.theme.mutedText)
                                    }
                                    ProgressView(value: task.completed, total: max(1, task.estimate))
                                        .tint(model.theme.primary)
                                }
                            }
                            .padding(13)
                            .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .glassHover(theme: model.theme, radius: 13)

                        Button {
                            editingTask = task
                        } label: {
                            Image(systemName: "pencil")
                                .frame(width: 30, height: 30)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(model.theme.mutedText)
                        .glassHover(theme: model.theme, radius: 10)
                    }
                }
            }

            Button {
                editingTask = model.addQuickTask()
            } label: {
                Label(model.t("focus.addTask"), systemImage: "plus")
                    .font(.system(size: 12, weight: .bold))
            }
            .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))
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
                        Text("\(model.distractionRules.filter(\.isEnabled).count)")
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

                Text(model.t("tasks.estimate"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(model.theme.mutedText)
                TimeEstimatePicker(seconds: $draft.estimate)

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
                            VStack(alignment: .leading, spacing: 13) {
                                HStack {
                                    Circle()
                                        .fill(project.id == model.activeProjectID ? model.theme.primary : model.theme.secondary)
                                        .frame(width: 10, height: 10)
                                    Spacer()
                                    if project.id == model.activeProjectID {
                                        Text(model.t("projects.selected"))
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(model.theme.primary)
                                    }
                                    Button {
                                        editingProject = project
                                    } label: {
                                        Image(systemName: "pencil")
                                            .font(.system(size: 11, weight: .bold))
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(model.theme.mutedText)
                                    .glassHover(theme: model.theme, radius: 10)
                                }
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(project.name)
                                        .font(.system(size: 19, weight: .bold, design: .rounded))
                                    Text(project.detail)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(model.theme.mutedText)
                                    Text("\(model.tasks(for: project).count) \(model.t("projects.tasks"))")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(model.theme.mutedText)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(16)
                            .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .glassHover(theme: model.theme, radius: 16, isActive: project.id == model.activeProjectID)
                            .onTapGesture {
                                model.selectProject(project)
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

private struct AnalyticsScreen: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    var body: some View {
        VStack(spacing: 18) {
            AnalyticsStripView()
            LiquidGlassPanel(radius: 22) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(model.t("analytics.byProject"))
                        .font(.system(size: 15, weight: .bold))
                    if model.projects.isEmpty {
                        EmptyInlineState(
                            symbol: "chart.xyaxis.line",
                            title: model.t("analytics.empty.title"),
                            detail: model.t("analytics.empty.detail")
                        )
                    }

                    ForEach(model.projects) { project in
                        let seconds = model.sessions(for: project).reduce(0) { $0 + $1.honestFocusSeconds }
                        HStack {
                            Text(project.name)
                                .font(.system(size: 13, weight: .bold))
                            Spacer()
                            Text(seconds.focusClock)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(model.theme.primary)
                        }
                        ProgressView(value: seconds, total: max(1, model.dailySummary.honestFocusSeconds))
                            .tint(model.theme.primary)
                    }

                    let unassignedSeconds = model.unassignedSessions
                        .reduce(0) { $0 + $1.honestFocusSeconds }
                    if unassignedSeconds > 0 {
                        HStack {
                            Text(model.t("projects.unassigned"))
                                .font(.system(size: 13, weight: .bold))
                            Spacer()
                            Text(unassignedSeconds.focusClock)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(model.theme.primary)
                        }
                        ProgressView(value: unassignedSeconds, total: max(1, model.dailySummary.honestFocusSeconds))
                            .tint(model.theme.primary)
                    }
                }
            }
        }
    }
}

private struct StrictModeScreen: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    var body: some View {
        ViewThatFits(in: .horizontal) {
            content
            VStack(alignment: .leading, spacing: 18) {
                strictStatusCard
                strictSummaryCard
            }
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
                        Label("\(model.appRules.count) \(model.t("strict.apps"))", systemImage: "app.badge")
                        Label("\(model.siteRules.count) \(model.t("strict.sites"))", systemImage: "globe")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(model.theme.mutedText)
                }

                Button {
                    model.selectedSidebarItem = .settings
                } label: {
                    Label(model.t("strict.manage"), systemImage: "lock.shield.fill")
                }
                .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))
            }
        }
    }
}

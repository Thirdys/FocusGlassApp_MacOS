import AppKit
import SwiftUI

struct FullscreenFocusView: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @EnvironmentObject private var timerPresentation: FocusTimerPresentationState
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var isHoveringControls = false

    var body: some View {
        GeometryReader { proxy in
            let glowDiameter = min(max(proxy.size.width, proxy.size.height) * 0.72, 860)

            ZStack {
                model.theme.background
                    .ignoresSafeArea()

                Circle()
                    .fill(model.theme.glow.opacity(model.theme.fullscreenGlowIntensity * 0.32))
                    .frame(width: glowDiameter, height: glowDiameter)
                    .blur(radius: glowDiameter * 0.21)
                    .offset(x: proxy.size.width * 0.23, y: -proxy.size.height * 0.24)

                Circle()
                    .fill(model.theme.secondary.opacity(model.theme.fullscreenGlowIntensity * 0.24))
                    .frame(width: glowDiameter * 0.82, height: glowDiameter * 0.82)
                    .blur(radius: glowDiameter * 0.20)
                    .offset(x: -proxy.size.width * 0.24, y: proxy.size.height * 0.24)

                VStack(spacing: model.theme.spacing(24)) {
                    topBar

                    focusWorkspace(in: proxy.size)

                    VStack(spacing: model.theme.spacing(16)) {
                        segmentRail

                        if let message = model.focusGuard.lastDistractionMessage {
                            HStack(spacing: 10) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(model.theme.strict)
                                Text(message)
                                    .font(.system(size: 13, weight: .bold))
                                    .lineLimit(2)
                                    .foregroundStyle(model.theme.text)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 11)
                            .background(model.theme.surface.opacity(model.theme.resolvedSurfaceAlpha), in: Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(model.theme.strict.opacity(0.28), lineWidth: 1)
                            }
                        }
                    }
                    .padding(.bottom, min(34, proxy.size.height * 0.04))
                }
                .padding(.horizontal, min(44, max(22, proxy.size.width * 0.035)))
                .padding(.top, min(30, max(18, proxy.size.height * 0.03)))
            }
        }
        .foregroundStyle(model.theme.text)
        .background(FullscreenWindowAccessor())
        .onAppear {
            model.enterFocusMode()
        }
        .onDisappear {
            model.leaveFocusMode()
        }
        .overlay(alignment: .topLeading) {
            Button("") {
                dismissWindow(id: "focus-mode")
            }
            .keyboardShortcut(.cancelAction)
            .opacity(0)
            .frame(width: 1, height: 1)
        }
    }

    private var topBar: some View {
        HStack {
            Spacer()

            if showsControls {
                HStack(spacing: 10) {
                    Button {
                        model.toggleTimer()
                    } label: {
                        Image(systemName: timerPresentation.snapshot.status == .running ? "pause.fill" : "play.fill")
                            .frame(width: 44, height: 38)
                    }
                    .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .primary))

                    Button {
                        model.resetTimer()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .frame(width: 38, height: 38)
                    }
                    .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .danger))

                    Button {
                        model.skipSegment()
                    } label: {
                        Image(systemName: "forward.end.fill")
                            .frame(width: 38, height: 38)
                    }
                    .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .icon))
                    .disabled(!timerPresentation.canSkipSegment)
                    .opacity(timerPresentation.canSkipSegment ? 1 : 0.42)
                    .help(model.t("help.timerSkip"))

                    Button {
                        dismissWindow(id: "focus-mode")
                    } label: {
                        Image(systemName: "xmark")
                            .frame(width: 38, height: 38)
                    }
                    .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .icon))
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(height: 76)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.18)) {
                isHoveringControls = hovering
            }
        }
    }

    private var showsControls: Bool {
        timerPresentation.snapshot.status != .running || isHoveringControls
    }

    @ViewBuilder
    private func focusWorkspace(in size: CGSize) -> some View {
        let isWide = size.width >= 1080 && size.height >= 680
        let timerSize: CGFloat = if isWide {
            min(470, max(330, min(size.width * 0.38, size.height * 0.52)))
        } else {
            min(360, max(238, min(size.width * 0.56, size.height * 0.38)))
        }

        if isWide {
            HStack(alignment: .center, spacing: min(48, size.width * 0.035)) {
                if !model.activeTasks.isEmpty {
                    taskRail(width: min(420, max(320, size.width * 0.30)), maxHeight: min(300, size.height * 0.32))
                }
                timer(size: timerSize)
            }
            .frame(maxHeight: .infinity)
        } else {
            VStack(spacing: model.theme.spacing(18)) {
                timer(size: timerSize)
                if !model.activeTasks.isEmpty {
                    taskRail(width: min(680, size.width - 44), maxHeight: min(190, size.height * 0.25))
                }
            }
            .frame(maxHeight: .infinity)
        }
    }

    private func timer(size: CGFloat) -> some View {
        CircularTimerView(
            clockText: timerPresentation.primaryClockText,
            phase: model.phaseTitle(timerPresentation.snapshot.activeSegment.phase),
            progress: timerPresentation.snapshot.progress,
            theme: model.theme,
            statusText: model.statusTitle(timerPresentation.snapshot.status),
            size: size,
            clockSize: size * 0.196
        )
        .frame(width: size, height: size)
    }

    private func taskRail(width: CGFloat, maxHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(model.t("tasks.focusStack"))
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(model.theme.mutedText)

            if model.activeTasks.isEmpty {
                EmptyInlineState(
                    symbol: "scope",
                    title: model.t("fullscreen.empty.title"),
                    detail: model.t("fullscreen.empty.detail")
                )
            } else {
                FocusGlassScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(model.activeTasks) { task in
                            Button {
                                model.selectTaskForSession(task)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: model.activeTaskID == task.id ? "target" : "circle")
                                        .foregroundStyle(model.activeTaskID == task.id ? model.theme.primary : model.theme.mutedText)

                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(task.title)
                                            .font(.system(size: 15, weight: .bold))
                                            .lineLimit(5)
                                            .fixedSize(horizontal: false, vertical: true)

                                        if task.timingMode == .timed {
                                            Text(task.estimate.focusClock)
                                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                                .foregroundStyle(model.theme.mutedText)
                                        } else {
                                            Text(model.t("tasks.checklist"))
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundStyle(model.theme.mutedText)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .layoutPriority(1)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 13)
                                .frame(maxWidth: .infinity, minHeight: FocusGlassHitTarget.row, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .background(model.theme.surface.opacity(model.activeTaskID == task.id ? 0.58 : 0.42), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke((model.activeTaskID == task.id ? model.theme.primary : .white).opacity(model.theme.borderOpacity), lineWidth: 1)
                                }
                            }
                            .buttonStyle(.plain)
                            .glassHover(theme: model.theme, radius: 14, isActive: model.activeTaskID == task.id)
                            .help(task.title)
                            .accessibilityLabel(task.title)
                        }
                    }
                    .padding(.trailing, 2)
                }
                .frame(maxHeight: maxHeight)
            }
        }
        .frame(width: width, alignment: .leading)
    }

    private var segmentRail: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                ForEach(Array(timerPresentation.snapshot.preset.segments.enumerated()), id: \.offset) { index, segment in
                    VStack(spacing: 7) {
                        Capsule()
                            .fill(index <= timerPresentation.snapshot.activeSegmentIndex ? model.theme.primary : .white.opacity(0.14))
                            .frame(height: 8)
                        Text(model.phaseTitle(segment.phase))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(index <= timerPresentation.snapshot.activeSegmentIndex ? model.theme.primary : model.theme.mutedText)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: 720)
        }
    }
}

private struct FullscreenWindowAccessor: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            context.coordinator.enterFullscreen(from: view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.enterFullscreen(from: nsView)
        }
    }

    final class Coordinator {
        private var didRequestFullscreen = false

        @MainActor
        func enterFullscreen(from view: NSView) {
            guard !didRequestFullscreen, let window = view.window else { return }
            didRequestFullscreen = true
            if !window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
            }
        }
    }
}

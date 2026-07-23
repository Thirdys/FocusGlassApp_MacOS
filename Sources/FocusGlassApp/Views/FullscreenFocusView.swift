import AppKit
import SwiftUI

struct FullscreenFocusView: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var isHoveringControls = false

    var body: some View {
        ZStack {
            model.theme.background
                .ignoresSafeArea()

            Circle()
                .fill(model.theme.glow.opacity(model.theme.fullscreenGlowIntensity * 0.32))
                .frame(width: 760, height: 760)
                .blur(radius: 160)
                .offset(x: 360, y: -260)

            Circle()
                .fill(model.theme.secondary.opacity(model.theme.fullscreenGlowIntensity * 0.24))
                .frame(width: 620, height: 620)
                .blur(radius: 150)
                .offset(x: -380, y: 260)

            VStack(spacing: 28) {
                topBar

                Spacer(minLength: 18)

                HStack(alignment: .center, spacing: 48) {
                    if !model.activeTasks.isEmpty {
                        taskRail
                    }

                    CircularTimerView(
                        clockText: model.primaryClockText,
                        phase: model.phaseTitle(model.engineSnapshot.activeSegment.phase),
                        progress: model.engineSnapshot.progress,
                        theme: model.theme,
                        statusText: model.statusTitle(model.engineSnapshot.status),
                        size: 470,
                        clockSize: 92
                    )
                }

                Spacer(minLength: 18)

                VStack(spacing: 18) {
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
                        .background(model.theme.surface.opacity(0.44), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(model.theme.strict.opacity(0.28), lineWidth: 1)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 44)
            .padding(.top, 30)
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
                        Image(systemName: model.engineSnapshot.status == .running ? "pause.fill" : "play.fill")
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
                    .disabled(!model.canSkipSegment)
                    .opacity(model.canSkipSegment ? 1 : 0.42)
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
        model.engineSnapshot.status != .running || isHoveringControls
    }

    private var taskRail: some View {
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
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(model.activeTasks) { task in
                            Button {
                                model.selectTaskForSession(task)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: model.activeTaskID == task.id ? "target" : "circle")
                                        .foregroundStyle(model.activeTaskID == task.id ? model.theme.primary : model.theme.mutedText)
                                    Text(task.title)
                                        .font(.system(size: 15, weight: .bold))
                                        .lineLimit(1)
                                    Spacer()
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
                                .padding(.horizontal, 16)
                                .padding(.vertical, 13)
                                .background(model.theme.surface.opacity(model.activeTaskID == task.id ? 0.58 : 0.42), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke((model.activeTaskID == task.id ? model.theme.primary : .white).opacity(model.theme.borderOpacity), lineWidth: 1)
                                }
                            }
                            .buttonStyle(.plain)
                            .glassHover(theme: model.theme, radius: 14, isActive: model.activeTaskID == task.id)
                        }
                    }
                    .padding(.trailing, 2)
                }
                .frame(maxHeight: 260)
            }
        }
        .frame(width: 440, alignment: .leading)
    }

    private var segmentRail: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                ForEach(Array(model.engineSnapshot.preset.segments.enumerated()), id: \.offset) { index, segment in
                    VStack(spacing: 7) {
                        Capsule()
                            .fill(index <= model.engineSnapshot.activeSegmentIndex ? model.theme.primary : .white.opacity(0.14))
                            .frame(height: 8)
                        Text(model.phaseTitle(segment.phase))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(index <= model.engineSnapshot.activeSegmentIndex ? model.theme.primary : model.theme.mutedText)
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

import AppKit
import SwiftUI
import FocusGlassCore

struct MenuBarPanel: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @EnvironmentObject private var timerPresentation: FocusTimerPresentationState
    @Environment(\.openWindow) private var openWindow
    @Environment(\.focusGlassMotion) private var motion

    var openMainWindow: (() -> Void)?
    var openFocusWindow: (() -> Void)?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(model.theme.background)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            model.theme.highlight.opacity(model.theme.highlightAlpha * 0.34),
                            model.theme.surface.opacity(model.theme.menuGlassOpacity * 0.52),
                            Color.black.opacity(model.theme.shadowDepth * 0.28)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))

            VStack(alignment: .leading, spacing: 14) {
                header

                ProgressView(value: timerPresentation.snapshot.progress)
                    .tint(model.theme.primary)
                    .scaleEffect(x: 1, y: 0.62, anchor: .center)

                Button {
                    model.toggleTimer()
                } label: {
                    Label(primaryTitle, systemImage: timerPresentation.snapshot.status == .running ? "pause.fill" : "play.fill")
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .primary))
                .help(primaryTitle)
                .contentTransition(.opacity)
                .animation(motion.animation(.selection), value: timerPresentation.snapshot.status)

                strictStatus

                toolbar
            }
            .padding(16)
        }
        .foregroundStyle(model.theme.text)
        .background(.clear)
        .background(MenuBarWindowAccessor(cornerRadius: 28))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(alignment: .top) {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [.clear, model.theme.highlight.opacity(model.theme.specularOpacity * 0.42), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1.4)
                .padding(.horizontal, 22)
                .padding(.top, 1)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            model.theme.highlight.opacity(model.theme.borderOpacity * 1.22),
                            model.theme.glow.opacity(model.theme.borderOpacity * 0.30),
                            Color.black.opacity(model.theme.shadowDepth * 0.32)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: .black.opacity(model.theme.shadowDepth), radius: 30, x: 0, y: 18)
        .shadow(color: model.theme.glow.opacity(model.theme.specularOpacity * 0.08), radius: 22, x: -4, y: 0)
        .animation(motion.animation(.selection), value: model.strictModeEnabled)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(model.theme.primary.opacity(0.15))
                Image(systemName: model.selectedPreset.mode.symbolName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(model.theme.primary)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text(model.presetTitle(model.selectedPreset))
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)
                Text(model.phaseTitle(timerPresentation.snapshot.activeSegment.phase))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(model.theme.mutedText)
            }

            Spacer()

            Text(timerPresentation.primaryClockText)
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.72)
        }
    }

    private var strictStatus: some View {
        HStack(spacing: 10) {
            Label(model.t("strict.mode"), systemImage: model.strictModeEnabled ? "lock.shield.fill" : "shield")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(model.strictModeEnabled ? model.theme.primary : model.theme.mutedText)
            Spacer()
            Text("\(model.distractionRules.filter(\.isEnabled).count)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(model.theme.text)
            Toggle("", isOn: $model.strictModeEnabled)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
                .frame(width: 48)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            LinearGradient(
                colors: [
                    model.theme.highlight.opacity(model.theme.highlightAlpha * 0.16),
                    model.theme.surface.opacity(model.theme.surfaceAlpha * 0.62),
                    Color.black.opacity(model.theme.shadowDepth * 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 15, style: .continuous)
        )
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(model.theme.highlight.opacity(model.theme.borderOpacity * 0.56), lineWidth: 1)
        }
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            Button {
                if let openFocusWindow {
                    openFocusWindow()
                } else {
                    openWindow(id: "focus-mode")
                    model.openFocusModeFullscreen()
                }
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .icon))
            .help(model.t("help.fullscreen"))

            Button {
                model.resetTimer()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .icon))
            .help(model.t("help.timerReset"))

            Button {
                model.skipSegment()
            } label: {
                Image(systemName: "forward.end.fill")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .icon))
            .disabled(!timerPresentation.canSkipSegment)
            .opacity(timerPresentation.canSkipSegment ? 1 : 0.42)
            .help(model.t("help.timerSkip"))

            Button {
                if let openMainWindow {
                    openMainWindow()
                } else {
                    model.focusMainWindow {
                        openWindow(id: "main")
                    }
                }
            } label: {
                Label(model.t("menu.openApp"), systemImage: "macwindow")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))
            .help(model.t("menu.openApp"))
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

private struct MenuBarWindowAccessor: NSViewRepresentable {
    let cornerRadius: CGFloat

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            configure(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configure(nsView.window)
        }
    }

    private func configure(_ window: NSWindow?) {
        guard let window else { return }
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
        window.contentView?.layer?.cornerRadius = cornerRadius
        window.contentView?.layer?.masksToBounds = true
        window.contentView?.superview?.wantsLayer = true
        window.contentView?.superview?.layer?.backgroundColor = NSColor.clear.cgColor
    }
}

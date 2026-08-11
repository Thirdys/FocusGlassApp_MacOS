import AppKit
import QuartzCore
import SwiftUI

@main
struct FocusGlassApp: App {
    @NSApplicationDelegateAdaptor(FocusGlassApplicationDelegate.self) private var appDelegate
    @StateObject private var model = FocusGlassViewModel()

    var body: some Scene {
        WindowGroup("FocusGlass", id: "main") {
            ContentView()
                .environmentObject(model)
                .environmentObject(model.timerPresentation)
                .preferredColorScheme(model.preferredColorScheme)
                .focusGlassMotionScope(theme: model.theme)
                .focusGlassThemeTransition(model)
                .background(MainWindowAccessor())
                .background(
                    StatusItemInstaller(
                        model: model,
                        timerPresentation: model.timerPresentation,
                        controller: appDelegate.statusItemController
                    )
                )
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                    model.flushPendingThemeSideEffectsBeforeExit()
                }
                .frame(minWidth: 820, minHeight: 620)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1240, height: 820)

        WindowGroup("Focus", id: "focus-mode") {
            FullscreenFocusView()
                .environmentObject(model)
                .environmentObject(model.timerPresentation)
                .preferredColorScheme(model.preferredColorScheme)
                .focusGlassMotionScope(theme: model.theme)
                .focusGlassThemeTransition(model)
                .frame(minWidth: 960, minHeight: 640)
        }
        .windowStyle(.hiddenTitleBar)

        Settings {
            SettingsView()
                .environmentObject(model)
                .environmentObject(model.timerPresentation)
                .preferredColorScheme(model.preferredColorScheme)
                .focusGlassMotionScope(theme: model.theme)
                .focusGlassThemeTransition(model)
                .frame(width: 680, height: 560)
        }
    }
}

@MainActor
private final class FocusGlassApplicationDelegate: NSObject, NSApplicationDelegate {
    let statusItemController = FocusGlassStatusItemController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItemController.prepareStatusItem()
    }
}

private extension View {
    func focusGlassThemeTransition(_ model: FocusGlassViewModel) -> some View {
        modifier(FocusGlassThemeTransitionModifier(model: model))
    }
}

private struct FocusGlassThemeTransitionModifier: ViewModifier {
    @ObservedObject var model: FocusGlassViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.animation(
            FocusGlassMotion(theme: model.theme, reduceMotion: reduceMotion).animation(.emphasis),
            value: model.themeTransitionID
        )
    }
}

private struct MainWindowAccessor: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            configure(view.window, coordinator: context.coordinator)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configure(nsView.window, coordinator: context.coordinator)
        }
    }

    private func configure(_ window: NSWindow?, coordinator: Coordinator) {
        guard let window else { return }
        window.identifier = FocusGlassViewModel.mainWindowIdentifier

#if DEBUG
        if !coordinator.didApplyCaptureSize,
           let contentSize = FocusGlassWindowCapture.contentSize {
            coordinator.didApplyCaptureSize = true
            window.setContentSize(contentSize)
            window.center()
        }
#endif
    }

    final class Coordinator {
        var didApplyCaptureSize = false
    }
}

private enum FocusGlassWindowCapture {
    static let contentSize: NSSize? = {
#if DEBUG
        let prefix = "focusglass-window-size="
        guard let argument = CommandLine.arguments.first(where: { $0.hasPrefix(prefix) }) else {
            return nil
        }
        let parts = argument.dropFirst(prefix.count).split(separator: "x", maxSplits: 1)
        guard parts.count == 2,
              let width = Double(parts[0]),
              let height = Double(parts[1]) else {
            return nil
        }
        return NSSize(
            width: min(1_800, max(820, width)),
            height: min(1_200, max(620, height))
        )
#else
        return nil
#endif
    }()
}

private struct StatusItemInstaller: View {
    @ObservedObject var model: FocusGlassViewModel
    @ObservedObject var timerPresentation: FocusTimerPresentationState
    @Environment(\.openWindow) private var openWindow

    let controller: FocusGlassStatusItemController

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear {
                controller.install(
                    model: model,
                    openMainWindow: {
                        model.focusMainWindow {
                            openWindow(id: "main")
                        }
                    },
                    openFocusWindow: {
                        openWindow(id: "focus-mode")
                        model.openFocusModeFullscreen()
                    }
                )
            }
            .onReceive(timerPresentation.$snapshot) { _ in
                controller.updateTimerTitle(model.menuBarTitle)
            }
    }
}

@MainActor
private final class FocusGlassStatusItemController: NSObject {
    private var statusItem: NSStatusItem?
    private let panel = FocusGlassStatusPanel()
    private weak var model: FocusGlassViewModel?
    private var openMainWindow: (() -> Void)?
    private var openFocusWindow: (() -> Void)?
    private var outsideClickMonitor: Any?
    private var localClickMonitor: Any?
    private var isPanelPresented = false
    private var panelTransitionGeneration = 0
#if DEBUG
    private var didOpenDebugPanel = false
#endif

    override init() {
        super.init()
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
    }

    func prepareStatusItem() {
        guard statusItem == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item
        if let button = item.button {
            button.image = Self.makeTemplateImage()
            button.imagePosition = .imageOnly
            button.imageScaling = .scaleProportionallyDown
            button.toolTip = "FocusGlass"
            button.target = self
            button.action = #selector(togglePanel(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    func install(
        model: FocusGlassViewModel,
        openMainWindow: @escaping () -> Void,
        openFocusWindow: @escaping () -> Void
    ) {
        self.model = model
        self.openMainWindow = openMainWindow
        self.openFocusWindow = openFocusWindow

        prepareStatusItem()
        statusItem?.button?.toolTip = model.menuBarTitle

        updateRootView()

#if DEBUG
        if !didOpenDebugPanel,
           CommandLine.arguments.contains("focusglass-open-status-panel") {
            didOpenDebugPanel = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                guard let self, let button = self.statusItem?.button else { return }
                self.showPanel(relativeTo: button)
            }
        }
#endif
    }

    @objc private func togglePanel(_ sender: NSStatusBarButton) {
        if isPanelPresented {
            hidePanel()
            return
        }

        showPanel(relativeTo: sender)
    }

    private func showPanel(relativeTo sender: NSStatusBarButton) {
        isPanelPresented = true
        panelTransitionGeneration &+= 1
        updateRootView()
        positionPanel(relativeTo: sender)
        let restingOrigin = panel.frame.origin
        panel.alphaValue = reducesMotion ? 1 : 0
        if !reducesMotion {
            panel.setFrameOrigin(NSPoint(x: restingOrigin.x, y: restingOrigin.y + 6))
        }
        panel.orderFrontRegardless()
        panel.makeKey()
        FocusGlassPerformance.menuPanelChanged(isVisible: true)

        if !reducesMotion {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18 * motionDurationScale
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().alphaValue = 1
                panel.animator().setFrameOrigin(restingOrigin)
            }
        }
        installOutsideClickMonitor()
    }

    private func updateRootView() {
        guard let model else { return }
        let rootView = MenuBarPanel(
            openMainWindow: { [weak self] in
                self?.hidePanel()
                self?.openMainWindow?()
            },
            openFocusWindow: { [weak self] in
                self?.hidePanel()
                self?.openFocusWindow?()
            }
        )
        .environmentObject(model)
        .environmentObject(model.timerPresentation)
        .preferredColorScheme(model.preferredColorScheme)
        .focusGlassMotionScope(theme: model.theme)
        .focusGlassThemeTransition(model)
        .frame(width: 360)
        .fixedSize(horizontal: false, vertical: true)

        if let hostingController = panel.contentViewController as? NSHostingController<AnyView> {
            hostingController.rootView = AnyView(rootView)
            hostingController.view.layoutSubtreeIfNeeded()
            resizePanel(toFit: hostingController.view)
        } else {
            let hostingController = NSHostingController(rootView: AnyView(rootView))
            panel.contentViewController = hostingController
            hostingController.view.layoutSubtreeIfNeeded()
            resizePanel(toFit: hostingController.view)
        }
    }

    private func resizePanel(toFit view: NSView) {
        let fittingHeight = max(260, min(520, view.fittingSize.height))
        panel.setContentSize(NSSize(width: 360, height: fittingHeight))
    }

    private func positionPanel(relativeTo button: NSStatusBarButton) {
        guard let buttonWindow = button.window else { return }
        let buttonRect = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let visibleFrame = buttonWindow.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        let panelSize = panel.frame.size
        let proposedX = buttonRect.midX - panelSize.width / 2
        let x = min(
            visibleFrame.maxX - panelSize.width - 8,
            max(visibleFrame.minX + 8, proposedX)
        )
        let y = max(visibleFrame.minY + 8, buttonRect.minY - panelSize.height - 6)
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func installOutsideClickMonitor() {
        removeOutsideClickMonitor()
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            Task { @MainActor in
                self?.hidePanel()
            }
        }
        localClickMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            guard let self,
                  event.window !== self.panel,
                  event.window !== self.statusItem?.button?.window else {
                return event
            }
            self.hidePanel()
            return event
        }
    }

    private func hidePanel() {
        guard isPanelPresented else { return }
        isPanelPresented = false
        panelTransitionGeneration &+= 1
        let transitionGeneration = panelTransitionGeneration
        removeOutsideClickMonitor()
        FocusGlassPerformance.menuPanelChanged(isVisible: false)

        guard !reducesMotion else {
            panel.orderOut(nil)
            panel.alphaValue = 1
            return
        }

        let restingOrigin = panel.frame.origin
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12 * motionDurationScale
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
            panel.animator().setFrameOrigin(NSPoint(x: restingOrigin.x, y: restingOrigin.y + 4))
        } completionHandler: { [weak self] in
            guard let self,
                  self.panelTransitionGeneration == transitionGeneration,
                  !self.isPanelPresented else { return }
            self.panel.orderOut(nil)
            self.panel.alphaValue = 1
            self.panel.setFrameOrigin(restingOrigin)
        }
    }

    private var reducesMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    private var motionDurationScale: Double {
        model?.theme.motionDurationScale ?? 1
    }

    func updateTimerTitle(_ title: String) {
        statusItem?.button?.toolTip = title
    }

    private func removeOutsideClickMonitor() {
        if let outsideClickMonitor {
            NSEvent.removeMonitor(outsideClickMonitor)
            self.outsideClickMonitor = nil
        }
        if let localClickMonitor {
            NSEvent.removeMonitor(localClickMonitor)
            self.localClickMonitor = nil
        }
    }

    private static func makeTemplateImage() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()
        defer {
            image.unlockFocus()
            image.isTemplate = true
        }

        NSColor.black.setStroke()
        NSColor.black.setFill()

        let center = NSPoint(x: 9, y: 9)
        let ring = NSBezierPath()
        ring.appendArc(withCenter: center, radius: 6.1, startAngle: 118, endAngle: -52, clockwise: true)
        ring.lineWidth = 2.1
        ring.lineCapStyle = .round
        ring.stroke()

        let rest = NSBezierPath()
        rest.appendArc(withCenter: center, radius: 6.1, startAngle: -62, endAngle: 104, clockwise: true)
        rest.lineWidth = 1.45
        rest.lineCapStyle = .round
        rest.stroke()

        let face = NSBezierPath(ovalIn: NSRect(x: 4.2, y: 4.2, width: 9.6, height: 9.6))
        face.lineWidth = 1.15
        face.stroke()

        let hands = NSBezierPath()
        hands.move(to: center)
        hands.line(to: NSPoint(x: 9.0, y: 12.0))
        hands.move(to: center)
        hands.line(to: NSPoint(x: 11.85, y: 7.65))
        hands.lineWidth = 1.35
        hands.lineCapStyle = .round
        hands.stroke()

        NSBezierPath(ovalIn: NSRect(x: 8.05, y: 8.05, width: 1.9, height: 1.9)).fill()
        NSBezierPath(ovalIn: NSRect(x: 13.15, y: 13.1, width: 1.65, height: 1.65)).fill()

        return image
    }
}

private final class FocusGlassStatusPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 320),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

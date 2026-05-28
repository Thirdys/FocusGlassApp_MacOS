import AppKit
import SwiftUI

@main
struct FocusGlassApp: App {
    @StateObject private var model = FocusGlassViewModel()
    @State private var statusItemController = FocusGlassStatusItemController()

    var body: some Scene {
        WindowGroup("FocusGlass", id: "main") {
            ContentView()
                .environmentObject(model)
                .preferredColorScheme(model.preferredColorScheme)
                .focusGlassThemeTransition(model)
                .background(MainWindowAccessor())
                .background(StatusItemInstaller(model: model, controller: statusItemController))
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
                .preferredColorScheme(model.preferredColorScheme)
                .focusGlassThemeTransition(model)
                .frame(minWidth: 960, minHeight: 640)
        }
        .windowStyle(.hiddenTitleBar)

        Settings {
            SettingsView()
                .environmentObject(model)
                .preferredColorScheme(model.preferredColorScheme)
                .focusGlassThemeTransition(model)
                .frame(width: 680, height: 560)
        }
    }
}

private extension View {
    func focusGlassThemeTransition(_ model: FocusGlassViewModel) -> some View {
        animation(FocusGlassViewModel.themeTransitionAnimation, value: model.themeTransitionID)
    }
}

private struct MainWindowAccessor: NSViewRepresentable {
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
        window?.identifier = FocusGlassViewModel.mainWindowIdentifier
    }
}

private struct StatusItemInstaller: View {
    @ObservedObject var model: FocusGlassViewModel
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
    }
}

@MainActor
private final class FocusGlassStatusItemController: NSObject {
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private weak var model: FocusGlassViewModel?
    private var openMainWindow: (() -> Void)?
    private var openFocusWindow: (() -> Void)?

    func install(
        model: FocusGlassViewModel,
        openMainWindow: @escaping () -> Void,
        openFocusWindow: @escaping () -> Void
    ) {
        self.model = model
        self.openMainWindow = openMainWindow
        self.openFocusWindow = openFocusWindow

        if statusItem == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            statusItem = item
            if let button = item.button {
                button.image = Self.makeTemplateImage()
                button.imagePosition = .imageOnly
                button.imageScaling = .scaleProportionallyDown
                button.toolTip = model.menuBarTitle
                button.target = self
                button.action = #selector(togglePopover(_:))
                button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            }
            popover.behavior = .transient
        }

        updateRootView()
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
            return
        }

        updateRootView()
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    private func updateRootView() {
        guard let model else { return }
        let rootView = MenuBarPanel(
            openMainWindow: openMainWindow,
            openFocusWindow: openFocusWindow
        )
        .environmentObject(model)
        .preferredColorScheme(model.preferredColorScheme)
        .focusGlassThemeTransition(model)
        .frame(width: 360)

        if let hostingController = popover.contentViewController as? NSHostingController<AnyView> {
            hostingController.rootView = AnyView(rootView)
        } else {
            popover.contentViewController = NSHostingController(rootView: AnyView(rootView))
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

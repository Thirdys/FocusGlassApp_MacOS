import AppKit
import SwiftUI

private struct FocusGlassIsScrollingEnvironmentKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var focusGlassIsScrolling: Bool {
        get { self[FocusGlassIsScrollingEnvironmentKey.self] }
        set { self[FocusGlassIsScrollingEnvironmentKey.self] = newValue }
    }
}

struct FocusGlassScrollView<Content: View>: View {
    @Environment(\.focusGlassIsScrolling) private var parentIsScrolling
    @State private var isScrolling = false

    private let axes: Axis.Set
    private let showsIndicators: Bool
    private let content: Content

    init(
        _ axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.content = content()
    }

    @ViewBuilder
    var body: some View {
        if #available(macOS 15.0, *) {
            scrollView
                .onScrollPhaseChange { _, newPhase in
                    let nextValue = newPhase.isScrolling
                    if isScrolling != nextValue {
                        isScrolling = nextValue
                    }
                }
        } else {
            scrollView
        }
    }

    private var scrollView: some View {
        ScrollView(axes, showsIndicators: showsIndicators) {
            content
                .environment(\.focusGlassIsScrolling, parentIsScrolling || isScrolling)
                .background {
                    if #available(macOS 15.0, *) {
                        EmptyView()
                    } else {
                        FocusGlassLegacyScrollActivityMonitor(isScrolling: $isScrolling)
                            .frame(width: 0, height: 0)
                    }
                }
        }
    }
}

private struct FocusGlassLegacyScrollActivityMonitor: NSViewRepresentable {
    @Binding var isScrolling: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(isScrolling: $isScrolling)
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        context.coordinator.attach(to: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.isScrolling = $isScrolling
        context.coordinator.attach(to: nsView)
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.stopObserving()
    }

    @MainActor
    final class Coordinator: @unchecked Sendable {
        var isScrolling: Binding<Bool>

        private weak var scrollView: NSScrollView?
        private var observers: [NSObjectProtocol] = []
        private var isAttachScheduled = false

        init(isScrolling: Binding<Bool>) {
            self.isScrolling = isScrolling
        }

        func attach(to view: NSView) {
            guard scrollView == nil, !isAttachScheduled else { return }
            isAttachScheduled = true
            DispatchQueue.main.async { [weak self, weak view] in
                guard let self else { return }
                self.isAttachScheduled = false
                guard let scrollView = view?.enclosingScrollView else { return }
                self.observe(scrollView)
            }
        }

        func stopObserving() {
            for observer in observers {
                NotificationCenter.default.removeObserver(observer)
            }
            observers.removeAll()
            scrollView = nil
        }

        private func observe(_ scrollView: NSScrollView) {
            guard self.scrollView !== scrollView else { return }
            stopObserving()
            self.scrollView = scrollView

            observers = [
                NotificationCenter.default.addObserver(
                    forName: NSScrollView.willStartLiveScrollNotification,
                    object: scrollView,
                    queue: .main
                ) { [weak self] _ in
                    Task { @MainActor [weak self] in
                        guard self?.isScrolling.wrappedValue != true else { return }
                        self?.isScrolling.wrappedValue = true
                    }
                },
                NotificationCenter.default.addObserver(
                    forName: NSScrollView.didEndLiveScrollNotification,
                    object: scrollView,
                    queue: .main
                ) { [weak self] _ in
                    Task { @MainActor [weak self] in
                        guard self?.isScrolling.wrappedValue != false else { return }
                        self?.isScrolling.wrappedValue = false
                    }
                }
            ]
        }
    }
}

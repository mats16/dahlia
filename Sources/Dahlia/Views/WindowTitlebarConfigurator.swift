import AppKit
import SwiftUI

/// SwiftUI ウィンドウのタイトルバー区切り線を AppKit 側で補正する。
struct WindowTitlebarConfigurator: NSViewRepresentable {
    func makeNSView(context _: Context) -> NSView {
        ConfiguratorView()
    }

    func updateNSView(_ nsView: NSView, context _: Context) {
        (nsView as? ConfiguratorView)?.applyWindowConfiguration()
    }
}

private final class ConfiguratorView: NSView {
    private var hasScheduledDeferredApply = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        applyWindowConfiguration()
    }

    override func layout() {
        super.layout()
        scheduleDeferredWindowConfiguration()
    }

    func applyWindowConfiguration() {
        applyWindowConfigurationImmediately()
        scheduleDeferredWindowConfiguration()
    }

    private func applyWindowConfigurationImmediately() {
        guard let window else { return }
        guard needsConfiguration(window: window) else { return }
        window.titlebarSeparatorStyle = .none
        configureSplitViewItems(in: window.contentViewController)
    }

    private func needsConfiguration(window: NSWindow) -> Bool {
        if window.titlebarSeparatorStyle != .none { return true }
        return hasMisconfiguredSplitViewItems(in: window.contentViewController)
    }

    private func hasMisconfiguredSplitViewItems(in viewController: NSViewController?) -> Bool {
        guard let viewController else { return false }
        if let splitVC = viewController as? NSSplitViewController {
            if splitVC.splitViewItems.contains(where: { $0.titlebarSeparatorStyle != .none }) {
                return true
            }
        }
        return viewController.children.contains { hasMisconfiguredSplitViewItems(in: $0) }
    }

    private func scheduleDeferredWindowConfiguration() {
        guard !hasScheduledDeferredApply else { return }
        hasScheduledDeferredApply = true

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.hasScheduledDeferredApply = false
            self.applyWindowConfigurationImmediately()
        }
    }

    private func configureSplitViewItems(in viewController: NSViewController?) {
        guard let viewController else { return }

        if let splitViewController = viewController as? NSSplitViewController {
            for item in splitViewController.splitViewItems where item.titlebarSeparatorStyle != .none {
                item.titlebarSeparatorStyle = .none
            }
        }

        for child in viewController.children {
            configureSplitViewItems(in: child)
        }
    }
}

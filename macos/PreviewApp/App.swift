import SwiftUI
import AppKit

@main
struct InsideYourComputerPreviewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            PreviewHost()
                .background(Color.black)
                .ignoresSafeArea()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 960, height: 720)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var keyMonitor: Any?
    private var isLocking = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            self?.lockMacAndExit()
            return nil
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            guard let window = NSApp.windows.first else { return }

            window.backgroundColor = .black
            window.isOpaque = true
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.collectionBehavior = [
                .fullScreenPrimary,
                .canJoinAllSpaces,
                .stationary
            ]

            if !window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
            }

            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
        }
    }

    private func lockMacAndExit() {
        guard !isLocking else { return }
        isLocking = true

        for window in NSApp.windows {
            for view in window.contentView?.subviews ?? [] {
                (view as? FaithfulRendererView)?.stop()
            }
        }

        let cgSession = "/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession"

        if FileManager.default.isExecutableFile(atPath: cgSession) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: cgSession)
            process.arguments = ["-suspend"]
            try? process.run()
        } else {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
            process.arguments = ["displaysleepnow"]
            try? process.run()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            NSApp.terminate(nil)
        }
    }
}

struct PreviewHost: NSViewRepresentable {
    func makeNSView(context: Context) -> FaithfulRendererView {
        FaithfulRendererView(frame: .zero, bundle: .main, terminateOnInput: false)
    }

    func updateNSView(_ nsView: FaithfulRendererView, context: Context) {}
}

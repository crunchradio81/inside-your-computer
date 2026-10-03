import AppKit
import ScreenSaver

@objc(InsideYourComputerScreenSaverView)
final class InsideYourComputerScreenSaverView: ScreenSaverView {
    private static let moduleName = "com.crunchradio.InsideYourComputer.ScreenSaver"
    private var renderer: FaithfulRendererView!
    private var settingsSheet: NSWindow?
    private var soundCheckbox: NSButton?

    private var defaults: ScreenSaverDefaults? {
        ScreenSaverDefaults(forModuleWithName: Self.moduleName)
    }

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        configureRenderer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureRenderer()
    }

    private func configureRenderer() {
        animationTimeInterval = 0.125
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor

        let bundle = Bundle(for: InsideYourComputerScreenSaverView.self)
        renderer = FaithfulRendererView(frame: bounds, bundle: bundle, terminateOnInput: false)
        renderer.autoresizingMask = [.width, .height]
        renderer.soundsEnabled = defaults?.object(forKey: "soundsEnabled") as? Bool ?? true
        addSubview(renderer)
    }

    override func startAnimation() {
        super.startAnimation()
        renderer?.soundsEnabled = defaults?.object(forKey: "soundsEnabled") as? Bool ?? true
        renderer?.reset()
    }

    override func stopAnimation() {
        renderer?.stop()
        super.stopAnimation()
    }

    override func animateOneFrame() {
        // The shared renderer owns the tuned 8 Hz timer.
    }

    override var hasConfigureSheet: Bool { true }

    override var configureSheet: NSWindow? {
        if let settingsSheet { return settingsSheet }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 220),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Inside your Computer Options"

        let content = NSView(frame: window.contentView!.bounds)
        content.autoresizingMask = [.width, .height]

        let title = NSTextField(labelWithString: "Inside your Computer")
        title.font = NSFont.systemFont(ofSize: 22, weight: .bold)
        title.frame = NSRect(x: 28, y: 158, width: 360, height: 30)
        content.addSubview(title)

        let subtitle = NSTextField(labelWithString: "Microsoft Plus! for Windows 95 tribute — native macOS port")
        subtitle.textColor = .secondaryLabelColor
        subtitle.frame = NSRect(x: 28, y: 132, width: 365, height: 22)
        content.addSubview(subtitle)

        let checkbox = NSButton(checkboxWithTitle: "Play original screensaver sounds", target: nil, action: nil)
        checkbox.state = (defaults?.object(forKey: "soundsEnabled") as? Bool ?? true) ? .on : .off
        checkbox.frame = NSRect(x: 28, y: 82, width: 300, height: 24)
        content.addSubview(checkbox)
        soundCheckbox = checkbox

        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancelSettings(_:)))
        cancel.frame = NSRect(x: 230, y: 24, width: 80, height: 32)
        content.addSubview(cancel)

        let ok = NSButton(title: "OK", target: self, action: #selector(saveSettings(_:)))
        ok.keyEquivalent = "\r"
        ok.frame = NSRect(x: 318, y: 24, width: 80, height: 32)
        content.addSubview(ok)

        window.contentView = content
        settingsSheet = window
        return window
    }

    @objc private func saveSettings(_ sender: Any?) {
        let enabled = soundCheckbox?.state == .on
        defaults?.set(enabled, forKey: "soundsEnabled")
        defaults?.synchronize()
        renderer?.soundsEnabled = enabled
        if let sheet = settingsSheet { NSApp.endSheet(sheet) }
    }

    @objc private func cancelSettings(_ sender: Any?) {
        if let sheet = settingsSheet { NSApp.endSheet(sheet) }
    }
}

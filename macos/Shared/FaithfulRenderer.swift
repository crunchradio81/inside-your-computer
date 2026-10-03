import AppKit
import AVFoundation

final class FaithfulRendererView: NSView {
    private let movementAdvanceDivisor: Int = 2
    private let automaticSoundGap: TimeInterval = 4.0
    private let sameSoundGap: TimeInterval = 6.0
    private var pacingTick: Int = 0
    private var lastSoundByNumber: [Int: TimeInterval] = [:]

    private struct Actor {
        let resourceID: Int
        let frames: [NSImage]
        let delayTicks: Int
        let motion: [(dx: CGFloat, dy: CGFloat, frame: Int)]
        let sound: Int
        var x: CGFloat
        var y: CGFloat
        var tick: Int = 0
        var frameIndex: Int = 0
    }

    private let logicalHeight: CGFloat = 480
    private var visibleLogicalWidth: CGFloat = 640
    private let baseTick: TimeInterval = 0.125
    private let resourceBundle: Bundle
    private let terminateOnInput: Bool

    private var timer: Timer?
    private var board: NSImage?
    private var actors: [Actor] = []
    private var audioPlayer: AVAudioPlayer?
    private var lastSoundTime: TimeInterval = 0
    private var globalTick = 0
    private var nextAmbientSoundTick = 48
    private var nextAmbientSoundNumber = 1

    var soundsEnabled = true

    init(frame frameRect: NSRect, bundle: Bundle, terminateOnInput: Bool) {
        self.resourceBundle = bundle
        self.terminateOnInput = terminateOnInput
        super.init(frame: frameRect)
        configure()
    }

    required init?(coder: NSCoder) {
        self.resourceBundle = .main
        self.terminateOnInput = false
        super.init(coder: coder)
        configure()
    }

    deinit {
        stop()
    }

    override var acceptsFirstResponder: Bool { terminateOnInput }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard terminateOnInput else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.window?.makeFirstResponder(self)
        }
    }

    override func keyDown(with event: NSEvent) {
        if terminateOnInput { NSApp.terminate(nil) }
        else { super.keyDown(with: event) }
    }

    override func mouseDown(with event: NSEvent) {
        if terminateOnInput { NSApp.terminate(nil) }
        else { super.mouseDown(with: event) }
    }

    private func configure() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        board = loadImage(name: "Board")
        actors = makeActors()
        start()
    }

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: baseTick, repeats: true) { [weak self] _ in
            self?.advanceAnimation()
        }
        if let timer { RunLoop.main.add(timer, forMode: .common) }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        audioPlayer?.stop()
        audioPlayer = nil
    }

    func reset() {
        stop()
        globalTick = 0
        nextAmbientSoundTick = 48
        nextAmbientSoundNumber = 1
        actors = makeActors()
        start()
        needsDisplay = true
    }

    private func makeActors() -> [Actor] {
        let specs: [(Int, Int, CGFloat, CGFloat, Int, CGFloat, CGFloat)] = [
            (8802, 2,  1,  1, 1, -120,  45),
            (8803, 1,  1, -1, 2,  120, 460),
            (8804, 1, -2,  0, 3,  700, 300),
            (8805, 1, -1, -2, 4,  580, 520),
            (8806, 1,  0,  2, 5,  310,-100),
            (8807, 1,  0, -3, 6,  475, 560),
            (8808, 1,  2, -2, 7, -120, 430)
        ]

        return specs.compactMap { rid, delay, dx, dy, sound, x, y in
            let frames = (0..<12).compactMap {
                loadImage(name: String(format: "frame_%02d", $0), subdirectory: "Sprites/\(rid)")
            }
            guard frames.count == 12 else { return nil }
            let motion = (0..<12).map { (dx: dx, dy: dy, frame: $0) }
            return Actor(resourceID: rid, frames: frames, delayTicks: delay, motion: motion, sound: sound, x: x, y: y)
        }
    }

    private func advanceAnimation() {
        globalTick &+= 1
        pacingTick &+= 1

        let advanceMotion = (pacingTick % movementAdvanceDivisor == 0)

        if advanceMotion {
            for index in actors.indices {
                actors[index].tick &+= 1
                guard actors[index].tick >= actors[index].delayTicks else { continue }
                actors[index].tick = 0

                let step = actors[index].motion[actors[index].frameIndex]
                actors[index].x += step.dx
                actors[index].y += step.dy
                actors[index].frameIndex = (actors[index].frameIndex + 1) % actors[index].frames.count

                let image = actors[index].frames[actors[index].frameIndex]
                let margin = max(image.size.width, image.size.height) + 30
                var wrapped = false

                if actors[index].x > visibleLogicalWidth + margin {
                    actors[index].x = -image.size.width
                    wrapped = true
                } else if actors[index].x < -image.size.width - margin {
                    actors[index].x = visibleLogicalWidth + 10
                    wrapped = true
                }

                if actors[index].y > logicalHeight + margin {
                    actors[index].y = -image.size.height
                    wrapped = true
                } else if actors[index].y < -image.size.height - margin {
                    actors[index].y = logicalHeight + 10
                    wrapped = true
                }

                if wrapped {
                    playSound(actors[index].sound)
                }
            }
        }

        if globalTick >= nextAmbientSoundTick {
            playSound(nextAmbientSoundNumber)

            nextAmbientSoundNumber += 1
            if nextAmbientSoundNumber > 8 {
                nextAmbientSoundNumber = 1
            }

            nextAmbientSoundTick = globalTick + Int.random(in: 96...144)
        }

        needsDisplay = true
    }

    private func playSound(_ number: Int) {
        guard soundsEnabled else { return }

        let now = ProcessInfo.processInfo.systemUptime

        guard audioPlayer?.isPlaying != true else { return }

        guard lastSoundTime == 0 || (now - lastSoundTime) >= automaticSoundGap else {
            return
        }

        if let previous = lastSoundByNumber[number],
           (now - previous) < sameSoundGap {
            return
        }

        guard let url = resourceURL(name: "Sound\(number)", ext: "wav") else {
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0.85
            player.prepareToPlay()
            player.play()

            audioPlayer = player
            lastSoundTime = now
            lastSoundByNumber[number] = now
        } catch {
            NSLog("InsideYourComputer: sound error: %@", error.localizedDescription)
        }
    }

    private func resourceURL(name: String, ext: String, subdirectory: String? = nil) -> URL? {
        let base = subdirectory.map { "RendererResources/\($0)" } ?? "RendererResources"
        return resourceBundle.url(forResource: name, withExtension: ext, subdirectory: base)
    }

    private func loadImage(name: String, subdirectory: String? = nil) -> NSImage? {
        guard let url = resourceURL(name: name, ext: "png", subdirectory: subdirectory) else {
            NSLog("InsideYourComputer: missing image %@", name)
            return nil
        }
        return NSImage(contentsOf: url)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.black.setFill()
        bounds.fill()

        guard let context = NSGraphicsContext.current else { return }
        context.imageInterpolation = .none

        let scale = bounds.height / logicalHeight
        guard scale > 0 else { return }

        visibleLogicalWidth = bounds.width / scale

        context.saveGraphicsState()
        let cg = context.cgContext
        cg.translateBy(x: 0, y: 0)
        cg.scaleBy(x: scale, y: scale)
        cg.interpolationQuality = .none

        drawBoardTiled()
        drawActors()

        context.restoreGraphicsState()
    }

    private func drawBoardTiled() {
        guard let board else { return }
        let tileW = board.size.width
        let tileH = board.size.height
        guard tileW > 0, tileH > 0 else { return }

        var y: CGFloat = 0
        while y < logicalHeight {
            var x: CGFloat = 0
            while x < visibleLogicalWidth {
                board.draw(
                    in: NSRect(x: x, y: y, width: tileW, height: tileH),
                    from: .zero,
                    operation: .copy,
                    fraction: 1,
                    respectFlipped: true,
                    hints: [.interpolation: NSImageInterpolation.none.rawValue]
                )
                x += tileW
            }
            y += tileH
        }
    }

    private func drawActors() {
        for actor in actors {
            guard !actor.frames.isEmpty else { continue }
            let image = actor.frames[actor.frameIndex]
            image.draw(
                in: NSRect(x: actor.x, y: actor.y, width: image.size.width, height: image.size.height),
                from: .zero,
                operation: .sourceOver,
                fraction: 1,
                respectFlipped: true,
                hints: [.interpolation: NSImageInterpolation.none.rawValue]
            )
        }
    }
}

import AppKit
import Combine

class OverlayWindow: NSWindow, AnimationEngineDelegate {
    private let overlayContentView: OverlayContentView
    private let animationEngine = AnimationEngine()
    private let settings = AppSettings.shared
    private var cancellables = Set<AnyCancellable>()
    private var localFlagsMonitor: Any?
    private var globalFlagsMonitor: Any?

    init(contentRect: NSRect) {
        overlayContentView = OverlayContentView(frame: contentRect)

        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        level = .floating
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        acceptsMouseMovedEvents = true
        collectionBehavior = [.canJoinAllSpaces, .stationary]
        isReleasedWhenClosed = false
        contentView = overlayContentView

        animationEngine.delegate = self
        applySpriteScale()
        loadSprite()
        updateEngineBounds()
        animationEngine.start()
        observeSettings()
        startOptionKeyMonitor()
    }

    private func observeSettings() {
        // Pokemon or shiny changed: reload sprite
        settings.$selectedPokemon
            .combineLatest(settings.$isShiny, settings.$selectedPokemonGen)
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _, _ in
                self?.loadSprite()
            }
            .store(in: &cancellables)

        // Rect dimensions changed: resize and reposition window
        settings.$rectWidth
            .combineLatest(settings.$rectHeight, settings.$rectX, settings.$rectY)
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] width, height, x, y in
                guard let self else { return }
                let newFrame = NSRect(x: x, y: y, width: width, height: height)
                self.setFrame(newFrame, display: true)
                self.overlayContentView.frame = NSRect(origin: .zero, size: newFrame.size)
                self.updateEngineBounds()
            }
            .store(in: &cancellables)

        // Visibility changed
        settings.$isVisible
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] visible in
                if visible {
                    self?.orderFront(nil)
                } else {
                    self?.orderOut(nil)
                }
            }
            .store(in: &cancellables)

        // Sprite scale changed
        settings.$spriteScale
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.applySpriteScale()
                self?.updateEngineBounds()
            }
            .store(in: &cancellables)
    }

    private func applySpriteScale() {
        let size = 48.0 * settings.spriteScale
        overlayContentView.spriteView.setFrameSize(NSSize(width: size, height: size))
    }

    private func loadSprite() {
        let isWalking = animationEngine.isWalking
        if let image = SpriteLoader.loadSprite(
            name: settings.selectedPokemon,
            gen: settings.selectedPokemonGen,
            isShiny: settings.isShiny,
            isWalking: isWalking
        ) {
            overlayContentView.updateSpriteImage(image)
        }
    }

    private func updateEngineBounds() {
        let spriteSize = overlayContentView.spriteView.frame.size
        let contentRect = self.contentRect(forFrameRect: frame)
        let insetRect = CGRect(
            x: 0,
            y: 0,
            width: contentRect.width - spriteSize.width,
            height: contentRect.height - spriteSize.height
        )
        animationEngine.updateBounds(insetRect)
    }

    private func startOptionKeyMonitor() {
        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let optionHeld = event.modifierFlags.contains(.option)
            self?.overlayContentView.setHighlightVisible(optionHeld)
            return event
        }
        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let optionHeld = event.modifierFlags.contains(.option)
            self?.overlayContentView.setHighlightVisible(optionHeld)
        }
    }

    deinit {
        if let monitor = localFlagsMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = globalFlagsMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // MARK: - AnimationEngineDelegate

    func animationEngineDidUpdatePosition(_ position: CGPoint, facingLeft: Bool) {
        overlayContentView.updateSpritePosition(NSPoint(x: position.x, y: position.y))
        if facingLeft {
            let w = overlayContentView.spriteView.frame.width
            overlayContentView.spriteView.layer?.setAffineTransform(
                CGAffineTransform(translationX: w, y: 0).scaledBy(x: -1, y: 1)
            )
        } else {
            overlayContentView.spriteView.layer?.setAffineTransform(.identity)
        }
    }

    func animationEngineDidChangeState(isWalking: Bool) {
        loadSprite()
    }
}

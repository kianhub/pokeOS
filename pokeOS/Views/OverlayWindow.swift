import AppKit
import Combine

class PokemonSprite: AnimationEngineDelegate {
    let pokemon: SelectedPokemon
    let spriteView: SpriteImageView
    let animationEngine = AnimationEngine()
    private let settings = AppSettings.shared

    init(pokemon: SelectedPokemon, spriteView: SpriteImageView) {
        self.pokemon = pokemon
        self.spriteView = spriteView
        animationEngine.delegate = self
    }

    func applyScale() {
        let size = 48.0 * settings.spriteScale
        spriteView.setFrameSize(NSSize(width: size, height: size))
    }

    func loadSprite() {
        if let image = SpriteLoader.loadSprite(
            name: pokemon.name,
            gen: pokemon.gen,
            isShiny: settings.isShiny,
            isWalking: animationEngine.isWalking
        ) {
            spriteView.updateSprite(image: image)
        }
    }

    func randomizePosition(in contentRect: NSRect) {
        let size = 48.0 * settings.spriteScale
        let maxX = max(0, contentRect.width - size)
        let maxY = max(0, contentRect.height - size)
        animationEngine.position = CGPoint(
            x: Double.random(in: 0...maxX),
            y: Double.random(in: 0...maxY)
        )
    }

    // MARK: - AnimationEngineDelegate

    func animationEngineDidUpdatePosition(_ position: CGPoint, facingLeft: Bool) {
        spriteView.frame.origin = NSPoint(x: position.x, y: position.y)
        if facingLeft {
            let w = spriteView.frame.width
            spriteView.layer?.setAffineTransform(
                CGAffineTransform(translationX: w, y: 0).scaledBy(x: -1, y: 1)
            )
        } else {
            spriteView.layer?.setAffineTransform(.identity)
        }
    }

    func animationEngineDidChangeState(isWalking: Bool) {
        loadSprite()
    }
}

class OverlayWindow: NSWindow {
    private let overlayContentView: OverlayContentView
    private(set) var sprites: [String: PokemonSprite] = [:]
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

        observeSettings()
        startModifierKeyMonitor()
    }

    // MARK: - Sprite management

    func addPokemon(_ pokemon: SelectedPokemon) {
        guard sprites[pokemon.name] == nil else { return }
        let spriteView = overlayContentView.addSpriteView()
        let sprite = PokemonSprite(pokemon: pokemon, spriteView: spriteView)
        sprites[pokemon.name] = sprite
        sprite.applyScale()
        sprite.loadSprite()
        sprite.randomizePosition(in: frame)
        updateEngineBounds(for: sprite)
        sprite.animationEngine.start()
    }

    func removePokemon(named name: String) {
        guard let sprite = sprites.removeValue(forKey: name) else { return }
        sprite.animationEngine.stop()
        overlayContentView.removeSpriteView(sprite.spriteView)
    }

    func removeAllPokemon() {
        for (_, sprite) in sprites {
            sprite.animationEngine.stop()
        }
        sprites.removeAll()
        overlayContentView.removeAllSpriteViews()
    }

    func stopAllAnimations() {
        for (_, sprite) in sprites {
            sprite.animationEngine.stop()
        }
    }

    // MARK: - Settings observation

    private func observeSettings() {
        settings.$isShiny
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.sprites.values.forEach { $0.loadSprite() }
            }
            .store(in: &cancellables)

        settings.$rectWidth
            .combineLatest(settings.$rectHeight, settings.$rectX, settings.$rectY)
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] width, height, x, y in
                guard let self else { return }
                let newFrame = NSRect(x: x, y: y, width: width, height: height)
                self.setFrame(newFrame, display: true)
                self.overlayContentView.frame = NSRect(origin: .zero, size: newFrame.size)
                self.sprites.values.forEach { self.updateEngineBounds(for: $0) }
            }
            .store(in: &cancellables)

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

        settings.$spriteScale
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.sprites.values.forEach {
                    $0.applyScale()
                    self.updateEngineBounds(for: $0)
                }
            }
            .store(in: &cancellables)
    }

    private func updateEngineBounds(for sprite: PokemonSprite) {
        let spriteSize = sprite.spriteView.frame.size
        let contentRect = self.contentRect(forFrameRect: frame)
        let insetRect = CGRect(
            x: 0,
            y: 0,
            width: contentRect.width - spriteSize.width,
            height: contentRect.height - spriteSize.height
        )
        sprite.animationEngine.updateBounds(insetRect)
    }

    private func startModifierKeyMonitor() {
        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let modifierHeld = event.modifierFlags.isSuperset(of: [.shift, .control])
            self?.overlayContentView.setHighlightVisible(modifierHeld)
            return event
        }
        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let modifierHeld = event.modifierFlags.isSuperset(of: [.shift, .control])
            self?.overlayContentView.setHighlightVisible(modifierHeld)
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
}

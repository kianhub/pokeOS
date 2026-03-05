import AppKit

class OverlayWindow: NSWindow, AnimationEngineDelegate {
    private let overlayContentView: OverlayContentView
    private let animationEngine = AnimationEngine()

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
        collectionBehavior = [.canJoinAllSpaces, .stationary]
        isReleasedWhenClosed = false
        contentView = overlayContentView

        animationEngine.delegate = self
        loadInitialSprite()
        updateEngineBounds()
        animationEngine.start()
    }

    private func loadInitialSprite() {
        if let image = SpriteLoader.loadSprite(name: "pikachu", gen: 1, isShiny: false, isWalking: false) {
            overlayContentView.updateSpriteImage(image)
            let spriteSize = overlayContentView.spriteView.frame.size
            let centerX = (frame.width - spriteSize.width) / 2
            let centerY = (frame.height - spriteSize.height) / 2
            overlayContentView.updateSpritePosition(NSPoint(x: centerX, y: centerY))
            animationEngine.position = CGPoint(x: centerX, y: centerY)
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

    // MARK: - AnimationEngineDelegate

    func animationEngineDidUpdatePosition(_ position: CGPoint, facingLeft: Bool) {
        overlayContentView.updateSpritePosition(NSPoint(x: position.x, y: position.y))
        if facingLeft {
            overlayContentView.spriteView.layer?.setAffineTransform(CGAffineTransform(scaleX: -1, y: 1))
        } else {
            overlayContentView.spriteView.layer?.setAffineTransform(.identity)
        }
    }

    func animationEngineDidChangeState(isWalking: Bool) {
        if let image = SpriteLoader.loadSprite(name: "pikachu", gen: 1, isShiny: false, isWalking: isWalking) {
            overlayContentView.updateSpriteImage(image)
        }
    }
}

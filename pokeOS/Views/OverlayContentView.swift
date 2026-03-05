import AppKit

class OverlayContentView: NSView {
    let spriteView = SpriteImageView()
    private let highlightView = NSView()
    var isModifierHeld = false

    private enum ResizeEdge {
        case none
        case top, bottom, left, right
        case topLeft, topRight, bottomLeft, bottomRight
    }

    private let edgeThreshold: CGFloat = 8
    private var activeResizeEdge: ResizeEdge = .none
    private var resizeStartFrame: NSRect = .zero
    private var resizeStartMouse: NSPoint = .zero

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupHighlightView()
        addSubview(spriteView)
        setupTrackingArea()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHighlightView()
        addSubview(spriteView)
        setupTrackingArea()
    }

    private func setupHighlightView() {
        highlightView.wantsLayer = true
        highlightView.layer?.backgroundColor = NSColor.systemRed.withAlphaComponent(0.15).cgColor
        highlightView.layer?.cornerRadius = 8
        highlightView.layer?.borderColor = NSColor.systemRed.withAlphaComponent(0.3).cgColor
        highlightView.layer?.borderWidth = 1.5
        highlightView.isHidden = true
        addSubview(highlightView)
    }

    private func setupTrackingArea() {
        let area = NSTrackingArea(
            rect: .zero,
            options: [.mouseMoved, .activeAlways, .inVisibleRect, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
    }

    override func layout() {
        super.layout()
        highlightView.frame = bounds
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let localPoint = convert(point, from: superview)
        if spriteView.frame.contains(localPoint) {
            return spriteView
        }
        if isModifierHeld && edgeAt(localPoint) != .none {
            return self
        }
        return nil
    }

    // MARK: - Edge detection

    private func edgeAt(_ point: NSPoint) -> ResizeEdge {
        let t = edgeThreshold
        let nearLeft = point.x < t
        let nearRight = point.x > bounds.width - t
        let nearBottom = point.y < t
        let nearTop = point.y > bounds.height - t

        if nearTop && nearLeft { return .topLeft }
        if nearTop && nearRight { return .topRight }
        if nearBottom && nearLeft { return .bottomLeft }
        if nearBottom && nearRight { return .bottomRight }
        if nearTop { return .top }
        if nearBottom { return .bottom }
        if nearLeft { return .left }
        if nearRight { return .right }
        return .none
    }

    private func cursorFor(_ edge: ResizeEdge) -> NSCursor {
        switch edge {
        case .left, .right: return .resizeLeftRight
        case .top, .bottom: return .resizeUpDown
        case .topLeft, .bottomRight: return .crosshair
        case .topRight, .bottomLeft: return .crosshair
        case .none: return .arrow
        }
    }

    // MARK: - Mouse events

    override func mouseMoved(with event: NSEvent) {
        guard isModifierHeld else {
            NSCursor.arrow.set()
            super.mouseMoved(with: event)
            return
        }
        let local = convert(event.locationInWindow, from: nil)
        let edge = edgeAt(local)
        cursorFor(edge).set()
    }

    override func mouseExited(with event: NSEvent) {
        NSCursor.arrow.set()
    }

    override func mouseDown(with event: NSEvent) {
        guard isModifierHeld else {
            super.mouseDown(with: event)
            return
        }
        let local = convert(event.locationInWindow, from: nil)
        let edge = edgeAt(local)
        if edge != .none {
            activeResizeEdge = edge
            resizeStartFrame = window?.frame ?? .zero
            resizeStartMouse = NSEvent.mouseLocation
        } else {
            super.mouseDown(with: event)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard activeResizeEdge != .none, let window = window else {
            super.mouseDragged(with: event)
            return
        }

        let currentMouse = NSEvent.mouseLocation
        let dx = currentMouse.x - resizeStartMouse.x
        let dy = currentMouse.y - resizeStartMouse.y
        let minSize: CGFloat = 80

        var newFrame = resizeStartFrame

        switch activeResizeEdge {
        case .right:
            newFrame.size.width = max(minSize, resizeStartFrame.width + dx)
        case .left:
            let newWidth = max(minSize, resizeStartFrame.width - dx)
            newFrame.origin.x = resizeStartFrame.maxX - newWidth
            newFrame.size.width = newWidth
        case .top:
            newFrame.size.height = max(minSize, resizeStartFrame.height + dy)
        case .bottom:
            let newHeight = max(minSize, resizeStartFrame.height - dy)
            newFrame.origin.y = resizeStartFrame.maxY - newHeight
            newFrame.size.height = newHeight
        case .topRight:
            newFrame.size.width = max(minSize, resizeStartFrame.width + dx)
            newFrame.size.height = max(minSize, resizeStartFrame.height + dy)
        case .topLeft:
            let newWidth = max(minSize, resizeStartFrame.width - dx)
            newFrame.origin.x = resizeStartFrame.maxX - newWidth
            newFrame.size.width = newWidth
            newFrame.size.height = max(minSize, resizeStartFrame.height + dy)
        case .bottomRight:
            newFrame.size.width = max(minSize, resizeStartFrame.width + dx)
            let newHeight = max(minSize, resizeStartFrame.height - dy)
            newFrame.origin.y = resizeStartFrame.maxY - newHeight
            newFrame.size.height = newHeight
        case .bottomLeft:
            let newWidth = max(minSize, resizeStartFrame.width - dx)
            newFrame.origin.x = resizeStartFrame.maxX - newWidth
            newFrame.size.width = newWidth
            let newHeight = max(minSize, resizeStartFrame.height - dy)
            newFrame.origin.y = resizeStartFrame.maxY - newHeight
            newFrame.size.height = newHeight
        case .none:
            break
        }

        window.setFrame(newFrame, display: true)
        self.frame = NSRect(origin: .zero, size: newFrame.size)
    }

    override func mouseUp(with event: NSEvent) {
        if activeResizeEdge != .none, let window = window {
            let settings = AppSettings.shared
            settings.rectX = window.frame.origin.x
            settings.rectY = window.frame.origin.y
            settings.rectWidth = window.frame.width
            settings.rectHeight = window.frame.height
            activeResizeEdge = .none
        } else {
            super.mouseUp(with: event)
        }
    }

    // MARK: - Public

    func setHighlightVisible(_ visible: Bool) {
        isModifierHeld = visible
        highlightView.isHidden = !visible
        if !visible {
            NSCursor.arrow.set()
        }
    }

    func updateSpritePosition(_ point: NSPoint) {
        spriteView.frame.origin = point
    }

    func updateSpriteImage(_ image: NSImage) {
        spriteView.updateSprite(image: image)
    }
}

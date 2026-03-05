import AppKit

class SpriteImageView: NSImageView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        imageScaling = .scaleProportionallyUpOrDown
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        imageScaling = .scaleProportionallyUpOrDown
        wantsLayer = true
    }

    convenience init() {
        self.init(frame: NSRect(x: 0, y: 0, width: 48, height: 48))
    }

    func updateSprite(image: NSImage) {
        self.image = image
        self.animates = true
    }

    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.isSuperset(of: [.shift, .control]) {
            window?.performDrag(with: event)
            if let windowFrame = window?.frame {
                AppSettings.shared.rectX = windowFrame.origin.x
                AppSettings.shared.rectY = windowFrame.origin.y
            }
        } else {
            super.mouseDown(with: event)
        }
    }
}

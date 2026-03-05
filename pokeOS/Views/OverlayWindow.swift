import AppKit
import SwiftUI

class OverlayWindow: NSWindow {
    init(contentRect: NSRect) {
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
        contentView = NSHostingView(rootView: Color.red.opacity(0.3))
    }
}

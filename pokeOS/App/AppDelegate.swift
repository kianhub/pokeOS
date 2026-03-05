import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindow: OverlayWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let screen = NSScreen.main else { return }
        let windowSize = NSSize(width: 400, height: 300)
        let origin = NSPoint(
            x: screen.frame.midX - windowSize.width / 2,
            y: screen.frame.midY - windowSize.height / 2
        )
        let frame = NSRect(origin: origin, size: windowSize)
        overlayWindow = OverlayWindow(contentRect: frame)
        overlayWindow?.makeKeyAndOrderFront(nil)
    }
}

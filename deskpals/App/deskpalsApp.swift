import SwiftUI

@main
struct deskpalsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(settings: AppSettings.shared)
        } label: {
            if let nsImage = NSImage(named: "MenuBarIcon") {
                let _ = {
                    nsImage.size = NSSize(width: 18, height: 18)
                    nsImage.isTemplate = true
                }()
                Image(nsImage: nsImage)
            }
        }
        .menuBarExtraStyle(.window)
    }
}

import AppKit
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    // Shared mode: single window with all Pokemon
    private var sharedWindow: OverlayWindow?
    // Separate mode: one window per Pokemon
    private var separateWindows: [String: OverlayWindow] = [:]
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReply:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )

        let settings = AppSettings.shared
        rebuildWindows()

        settings.$selectedPokemonList
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.syncPokemon() }
            .store(in: &cancellables)

        settings.$separateWindows
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.rebuildWindows() }
            .store(in: &cancellables)
    }

    private func makeFrame() -> NSRect {
        let s = AppSettings.shared
        return NSRect(x: s.rectX, y: s.rectY, width: s.rectWidth, height: s.rectHeight)
    }

    // MARK: - Rebuild (mode switch)

    private func rebuildWindows() {
        tearDownAll()
        let settings = AppSettings.shared

        if settings.separateWindows {
            for pokemon in settings.selectedPokemonList {
                let window = OverlayWindow(contentRect: makeFrame())
                window.addPokemon(pokemon)
                separateWindows[pokemon.name] = window
                if settings.isVisible { window.makeKeyAndOrderFront(nil) }
            }
        } else {
            let window = OverlayWindow(contentRect: makeFrame())
            sharedWindow = window
            for pokemon in settings.selectedPokemonList {
                window.addPokemon(pokemon)
            }
            if settings.isVisible { window.makeKeyAndOrderFront(nil) }
        }
    }

    // MARK: - Sync (add/remove Pokemon without rebuilding)

    private func syncPokemon() {
        let settings = AppSettings.shared
        let list = settings.selectedPokemonList

        if settings.separateWindows {
            let currentNames = Set(separateWindows.keys)
            let newNames = Set(list.map(\.name))

            for name in currentNames.subtracting(newNames) {
                if let window = separateWindows.removeValue(forKey: name) {
                    window.stopAllAnimations()
                    window.orderOut(nil)
                }
            }
            for pokemon in list where !currentNames.contains(pokemon.name) {
                let window = OverlayWindow(contentRect: makeFrame())
                window.addPokemon(pokemon)
                separateWindows[pokemon.name] = window
                if settings.isVisible { window.makeKeyAndOrderFront(nil) }
            }
        } else if let window = sharedWindow {
            let currentNames = Set(window.sprites.keys)
            let newNames = Set(list.map(\.name))

            for name in currentNames.subtracting(newNames) {
                window.removePokemon(named: name)
            }
            for pokemon in list where !currentNames.contains(pokemon.name) {
                window.addPokemon(pokemon)
            }
        }
    }

    private func tearDownAll() {
        sharedWindow?.stopAllAnimations()
        sharedWindow?.orderOut(nil)
        sharedWindow = nil

        for (_, window) in separateWindows {
            window.stopAllAnimations()
            window.orderOut(nil)
        }
        separateWindows.removeAll()
    }

    // MARK: - URL scheme

    @objc private func handleURLEvent(_ event: NSAppleEventDescriptor, withReply reply: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString),
              url.scheme == "pokeos",
              let host = url.host else {
            return
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []
        let settings = AppSettings.shared

        switch host {
        case "pokemon":
            if let name = queryItems.first(where: { $0.name == "name" })?.value,
               let genString = queryItems.first(where: { $0.name == "gen" })?.value,
               let gen = Int(genString) {
                let pokemon = PokemonData(name: name, gen: gen)
                settings.togglePokemon(pokemon)
            }
            if let shinyString = queryItems.first(where: { $0.name == "shiny" })?.value {
                settings.isShiny = (shinyString == "true")
            }

        case "toggle":
            settings.isVisible.toggle()

        case "resize":
            if let widthString = queryItems.first(where: { $0.name == "width" })?.value,
               let width = Double(widthString) {
                settings.rectWidth = width
            }
            if let heightString = queryItems.first(where: { $0.name == "height" })?.value,
               let height = Double(heightString) {
                settings.rectHeight = height
            }

        case "move":
            if let xString = queryItems.first(where: { $0.name == "x" })?.value,
               let x = Double(xString) {
                settings.rectX = x
            }
            if let yString = queryItems.first(where: { $0.name == "y" })?.value,
               let y = Double(yString) {
                settings.rectY = y
            }

        default:
            break
        }
    }
}

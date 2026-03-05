import Foundation
import Combine
import ServiceManagement

struct SelectedPokemon: Codable, Equatable, Hashable, Identifiable {
    let name: String
    let gen: Int
    var id: String { name }
}

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var selectedPokemonList: [SelectedPokemon] {
        didSet { persistPokemonList() }
    }
    @Published var isShiny: Bool {
        didSet { UserDefaults.standard.set(isShiny, forKey: "isShiny") }
    }
    @Published var rectWidth: Double {
        didSet { UserDefaults.standard.set(rectWidth, forKey: "rectWidth") }
    }
    @Published var rectHeight: Double {
        didSet { UserDefaults.standard.set(rectHeight, forKey: "rectHeight") }
    }
    @Published var rectX: Double {
        didSet { UserDefaults.standard.set(rectX, forKey: "rectX") }
    }
    @Published var rectY: Double {
        didSet { UserDefaults.standard.set(rectY, forKey: "rectY") }
    }
    @Published var isVisible: Bool {
        didSet { UserDefaults.standard.set(isVisible, forKey: "isVisible") }
    }
    @Published var spriteScale: Double {
        didSet { UserDefaults.standard.set(spriteScale, forKey: "spriteScale") }
    }
    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Launch at login failed: \(error)")
            }
        }
    }

    @Published var separateWindows: Bool {
        didSet { UserDefaults.standard.set(separateWindows, forKey: "separateWindows") }
    }

    static let maxPokemon = 10

    private init() {
        let defaults = UserDefaults.standard

        defaults.register(defaults: [
            "isShiny": false,
            "rectWidth": 400.0,
            "rectHeight": 300.0,
            "rectX": 100.0,
            "rectY": 100.0,
            "isVisible": true,
            "spriteScale": 2.0,
            "launchAtLogin": false,
            "separateWindows": false
        ])

        // Migrate from single selectedPokemon to list
        if let data = defaults.data(forKey: "selectedPokemonList"),
           let list = try? JSONDecoder().decode([SelectedPokemon].self, from: data),
           !list.isEmpty {
            self.selectedPokemonList = list
        } else if let name = defaults.string(forKey: "selectedPokemon") {
            let gen = defaults.integer(forKey: "selectedPokemonGen")
            self.selectedPokemonList = [SelectedPokemon(name: name, gen: gen == 0 ? 1 : gen)]
        } else {
            self.selectedPokemonList = [SelectedPokemon(name: "pikachu", gen: 1)]
        }

        self.isShiny = defaults.bool(forKey: "isShiny")
        self.rectWidth = defaults.double(forKey: "rectWidth")
        self.rectHeight = defaults.double(forKey: "rectHeight")
        self.rectX = defaults.double(forKey: "rectX")
        self.rectY = defaults.double(forKey: "rectY")
        self.isVisible = defaults.object(forKey: "isVisible") == nil ? true : defaults.bool(forKey: "isVisible")
        self.spriteScale = defaults.double(forKey: "spriteScale") == 0 ? 2.0 : defaults.double(forKey: "spriteScale")
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        self.separateWindows = defaults.bool(forKey: "separateWindows")
    }

    private func persistPokemonList() {
        if let data = try? JSONEncoder().encode(selectedPokemonList) {
            UserDefaults.standard.set(data, forKey: "selectedPokemonList")
        }
    }

    func isSelected(_ pokemon: PokemonData) -> Bool {
        selectedPokemonList.contains { $0.name == pokemon.name }
    }

    func togglePokemon(_ pokemon: PokemonData) {
        if let index = selectedPokemonList.firstIndex(where: { $0.name == pokemon.name }) {
            if selectedPokemonList.count > 1 {
                selectedPokemonList.remove(at: index)
            }
        } else if selectedPokemonList.count < AppSettings.maxPokemon {
            selectedPokemonList.append(SelectedPokemon(name: pokemon.name, gen: pokemon.gen))
        }
    }
}

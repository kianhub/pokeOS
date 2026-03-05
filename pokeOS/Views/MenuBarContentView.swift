import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var settings: AppSettings
    @State private var searchText = ""

    private let pokemonList: [PokemonData] = SpriteLoader.loadPokemonList()

    private var filteredPokemon: [PokemonData] {
        if searchText.isEmpty {
            return pokemonList
        }
        return pokemonList.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 12) {
            TextField("Search Pokemon...", text: $searchText)
                .textFieldStyle(.roundedBorder)

            List(filteredPokemon) { pokemon in
                Button {
                    settings.selectedPokemon = pokemon.name
                    settings.selectedPokemonGen = pokemon.gen
                } label: {
                    HStack {
                        Text(pokemon.displayName)
                        Spacer()
                        Text("Gen \(pokemon.gen)")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        if settings.selectedPokemon == pokemon.name {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .frame(height: 200)

            Divider()

            HStack {
                Toggle("Shiny", isOn: $settings.isShiny)
                Spacer()
                Toggle("Show Pokemon", isOn: $settings.isVisible)
            }

            Divider()

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Overlay Width: \(Int(settings.rectWidth))")
                        .font(.caption)
                    Stepper("", value: $settings.rectWidth, in: 200...2000, step: 50)
                        .labelsHidden()
                }
                Spacer()
                VStack(alignment: .leading, spacing: 6) {
                    Text("Overlay Height: \(Int(settings.rectHeight))")
                        .font(.caption)
                    Stepper("", value: $settings.rectHeight, in: 200...2000, step: 50)
                        .labelsHidden()
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Sprite Scale: \(settings.spriteScale, specifier: "%.1f")x")
                    .font(.caption)
                Slider(value: $settings.spriteScale, in: 1...5, step: 0.5)
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("System")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 280)
    }
}

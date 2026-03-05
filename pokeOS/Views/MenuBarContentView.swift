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
            HStack {
                TextField("Search Pokemon...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                Text("\(settings.selectedPokemonList.count)/\(AppSettings.maxPokemon)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            List(filteredPokemon) { pokemon in
                Button {
                    settings.togglePokemon(pokemon)
                } label: {
                    HStack {
                        Text(pokemon.displayName)
                        Spacer()
                        Text("Gen \(pokemon.gen)")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        if settings.isSelected(pokemon) {
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

            Toggle("Separate Windows", isOn: $settings.separateWindows)

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

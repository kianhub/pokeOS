<div align='center'>

# pokeOS

![pokeOS-showcase](https://github.com/user-attachments/assets/7f472b1e-4f7a-47ef-bda1-cb8f28378d3c)

</div>

<p align="center">

A native macOS menu bar app that puts an animated Pokemon sprite on your desktop as a virtual pet. The sprite walks, idles, and bounces around a transparent overlay window that floats above all your other windows. Inspired by [vscode-pokemon](https://github.com/jakobhoeg/vscode-pokemon), but at the OS level — your Pokemon companion follows you everywhere, not just in your editor.

</p>
<div align="center">
  
![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5-orange)
![Pokemon](https://img.shields.io/badge/Pokemon-565-red)

</div>

---

## Features

- **565 Pokemon** from Generations 1–4 with animated sprites
- **Shiny variants** for every Pokemon
- **Physics-based movement** — walking, idling, wall bouncing, smooth acceleration, and vertical bobbing
- **Transparent overlay** — always-on-top window with click-through support (clicks pass through to apps below)
- **Menu bar UI** — searchable Pokemon list, shiny toggle, size/scale sliders, visibility toggle
- **Shift+Ctrl+Drag** to reposition the overlay anywhere on screen
- **Launch at Login** support
- **URL scheme** (`pokeos://`) for scripting and automation
- **Raycast extension** for quick control without touching the menu bar
- **No network required** — all sprites are bundled in the app
- **No Dock icon** — lives entirely in the menu bar

---

## Getting Started

### Prerequisites

- **macOS 13.0** (Ventura) or later
- **Xcode 15.0+** with Swift 5
- **Node.js 16+** (only if you want the Raycast extension)
- **Raycast** (only for the Raycast extension)

### Building the App

**From Xcode (recommended):**

```bash
open pokeOS.xcodeproj
```

Then press **Cmd+R** to build and run.

**From the command line:**

```bash
xcodebuild -project pokeOS.xcodeproj -scheme pokeOS build
```

To run the built app outside Xcode, sign it ad-hoc:

```bash
codesign --force --deep --sign - build/Release/pokeOS.app
open build/Release/pokeOS.app
```

### First Launch

1. The app appears as an icon in your **menu bar** (no Dock icon)
2. A transparent overlay window appears with **Pikachu** walking around
3. Click the menu bar icon to open settings
4. Pick a different Pokemon, toggle shiny mode, resize the area, or adjust the sprite scale

---

## Usage

### Menu Bar Controls

Click the pokeOS menu bar icon to access:

| Setting | Description |
|---------|-------------|
| **Pokemon Picker** | Searchable list of 565 Pokemon with generation indicators |
| **Shiny Toggle** | Switch between normal and shiny sprite variants |
| **Width / Height** | Resize the overlay area (200–2000px) |
| **Sprite Scale** | Scale the sprite from 1x to 5x |
| **Show / Hide** | Toggle overlay visibility |
| **Launch at Login** | Start pokeOS automatically on login |

### Repositioning

Hold **Shift+Ctrl** and **drag** the overlay window to move it anywhere on screen. The position is saved automatically.

### URL Scheme

Control pokeOS from Terminal, scripts, or other apps using the `pokeos://` URL scheme:

```bash
# Change Pokemon
open "pokeos://pokemon?name=charizard&gen=1"
open "pokeos://pokemon?name=umbreon&gen=2&shiny=true"

# Toggle visibility
open "pokeos://toggle"

# Resize overlay
open "pokeos://resize?width=600&height=400"

# Reposition overlay
open "pokeos://move?x=200&y=300"
```

---

## Raycast Extension

The included Raycast extension provides three commands for quick access:

| Command | Description | Type |
|---------|-------------|------|
| **Change Pokemon** | Searchable list with shiny toggle dropdown | List view |
| **Toggle Visibility** | One-click show/hide | No-view (instant) |
| **Resize Pokemon Area** | Form to set width and height | Form view |

### Setting Up the Raycast Extension

```bash
cd pokeos-raycast
npm install
npm run dev    # Development mode with hot reload
```

This opens the extension in Raycast in development mode. The commands will appear in Raycast's command palette.

**Available scripts:**

```bash
npm run build  # Production build
npm run dev    # Development mode
npm run lint   # Lint check
```

> The Raycast extension communicates with the main app via the `pokeos://` URL scheme, so the main app must be running.

---

## Architecture

```
pokeOSApp (@main)
  └── MenuBarExtra (.window style)
        └── MenuBarContentView (SwiftUI settings UI)

AppDelegate (NSApplicationDelegate)
  ├── OverlayWindow (transparent, borderless, floating)
  │     ├── OverlayContentView (click-through via hitTest)
  │     │     └── SpriteImageView (animated GIF)
  │     └── AnimationEngine (60fps movement & physics)
  ├── AppSettings (ObservableObject, UserDefaults persistence)
  └── URL Scheme Handler (pokeos://)

Raycast Extension (TypeScript)
  └── Commands → open pokeos:// URLs → AppDelegate handles
```

**Data flow:** Settings changes in the menu bar UI publish via Combine. The overlay window observes these changes and updates the sprite, position, size, or visibility in real time. The animation engine ticks at 60fps, driving position updates with velocity-based physics.

**Click-through:** The overlay content view overrides `hitTest(_:)` to return `nil` for empty areas. This means clicks pass through to windows below, but you can still interact with the sprite itself.

---

## Project Structure

```
pokeOS/
├── pokeOS.xcodeproj/
├── pokeOS/
│   ├── App/
│   │   ├── pokeOSApp.swift              # Entry point, MenuBarExtra
│   │   └── AppDelegate.swift            # Window management, URL scheme
│   ├── Models/
│   │   ├── AppSettings.swift            # Settings persistence (UserDefaults)
│   │   └── PokemonData.swift            # Pokemon model (name, generation)
│   ├── Views/
│   │   ├── OverlayWindow.swift          # Transparent floating NSWindow
│   │   ├── OverlayContentView.swift     # Click-through NSView
│   │   ├── SpriteImageView.swift        # Animated GIF display
│   │   └── MenuBarContentView.swift     # SwiftUI menu bar interface
│   ├── Services/
│   │   ├── SpriteLoader.swift           # Loads bundled sprites
│   │   └── AnimationEngine.swift        # Movement physics engine
│   └── Resources/
│       ├── Info.plist
│       ├── pokemon.json                 # 565 Pokemon (name + generation)
│       └── Sprites/
│           ├── gen1/   (153 Pokemon)
│           ├── gen2/   (132 Pokemon)
│           ├── gen3/   (138 Pokemon)
│           └── gen4/   (142 Pokemon)
│               └── [pokemon_name]/
│                   ├── default_idle_8fps.gif
│                   ├── default_walk_8fps.gif
│                   ├── shiny_idle_8fps.gif
│                   └── shiny_walk_8fps.gif
├── pokeos-raycast/
│   ├── package.json
│   ├── tsconfig.json
│   └── src/
│       ├── change-pokemon.tsx
│       ├── toggle-visibility.tsx
│       └── resize-window.tsx
└── PLAN.md
```

---

## Settings Reference

All settings persist across launches via UserDefaults.

| Setting | Default | Range |
|---------|---------|-------|
| `selectedPokemon` | `pikachu` | Any of the 565 bundled Pokemon |
| `selectedPokemonGen` | `1` | 1–4 |
| `isShiny` | `false` | — |
| `rectWidth` | `400` | 200–2000 px |
| `rectHeight` | `300` | 200–2000 px |
| `rectX` | `100` | Any screen coordinate |
| `rectY` | `100` | Any screen coordinate |
| `isVisible` | `true` | — |
| `spriteScale` | `2.0` | 1.0–5.0x |
| `launchAtLogin` | `false` | — |

---

## Sprite Credits

All Pokemon sprites are sourced from [jakobhoeg/vscode-pokemon](https://github.com/jakobhoeg/vscode-pokemon). Each Pokemon has four animated GIF variants at 8fps: default idle, default walk, shiny idle, and shiny walk.

This repository is inspired by [jakobhoeg/vscode-pokemon](https://github.com/jakobhoeg/vscode-pokemon).

### Sprite Sources
- Pokemon Sprites: © The Pokémon Company / Nintendo / Game Freak
- The sprites are used for non-commercial, fan project purposes only
- Original sprite artwork belongs to the respective copyright holders

### Acknowledgments
- All sprites are property of their original creators
- This repository is a fan project and is not affiliated with Nintendo, The Pokémon Company, or Game Freak

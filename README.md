<div align='center'>

# deskpals

![pally](assets/deskpals-pally.png)

</div>

<p align="center">

A native macOS menu bar app that puts animated sprite companions on your desktop. Ships with 565 Pokemon sprites and supports custom characters — add any GIF you like. Run up to 10 sprites at once, each in shared or separate windows. Inspired by [vscode-pokemon](https://github.com/jakobhoeg/vscode-pokemon), but at the OS level — your companions follow you everywhere, not just in your editor.

</p>
<div align="center">

![deskpals-showcase](https://github.com/user-attachments/assets/7f472b1e-4f7a-47ef-bda1-cb8f28378d3c)

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5-orange)
![Pokemon](https://img.shields.io/badge/Pokemon-565-red)

</div>

---

## Features

- **565 Pokemon** from Generations 1–4 with animated sprites
- **Multi-sprite support** — run up to 10 Pokemon on your desktop at once
- **Shared or separate windows** — all sprites in one overlay, or each in its own window
- **Shiny variants** for every Pokemon
- **Custom sprites** — add any character as an animated GIF
- **Physics-based movement** — walking, idling, wall bouncing, smooth acceleration, and vertical bobbing
- **Transparent overlay** — always-on-top window with click-through support (clicks pass through to apps below)
- **Menu bar UI** — searchable Pokemon list, shiny toggle, size/scale sliders, visibility toggle
- **Shift+Ctrl+Drag** to reposition the overlay anywhere on screen
- **Launch at Login** support
- **URL scheme** (`deskpals://`) for scripting and automation
- **[Raycast extension](https://www.raycast.com/kian/deskpals)** for quick control without touching the menu bar
- **No network required** — all sprites are bundled in the app
- **No Dock icon** — lives entirely in the menu bar

---

## Download

Download the latest release from the [Releases page](https://github.com/kian/deskpals/releases).

> **Note:** The app is ad-hoc signed. On first launch, right-click the app and select **Open** to bypass Gatekeeper.

---

## Getting Started

### Prerequisites

- **macOS 13.0** (Ventura) or later
- **Xcode 15.0+** with Swift 5

### Building the App

**From Xcode (recommended):**

```bash
open deskpals.xcodeproj
```

Then press **Cmd+R** to build and run.

**From the command line:**

```bash
xcodebuild -project deskpals.xcodeproj -scheme deskpals build
```

To run the built app outside Xcode, sign it ad-hoc:

```bash
codesign --force --deep --sign - build/Release/deskpals.app
open build/Release/deskpals.app
```

### First Launch

1. The app appears as an icon in your **menu bar** (no Dock icon)
2. A transparent overlay window appears with **Pikachu** walking around
3. Click the menu bar icon to open settings
4. Pick Pokemon (up to 10 at once), toggle shiny mode, resize the area, or adjust the sprite scale

---

## Usage

### Menu Bar Controls

Click the deskpals menu bar icon to access:

| Setting | Description |
|---------|-------------|
| **Pokemon Picker** | Searchable list of 565 Pokemon — click to toggle on/off (up to 10 active) |
| **Shiny Toggle** | Switch between normal and shiny sprite variants |
| **Separate Windows** | Give each sprite its own overlay window instead of sharing one |
| **Width / Height** | Resize the overlay area (200–2000px) |
| **Sprite Scale** | Scale the sprite from 1x to 5x |
| **Show / Hide** | Toggle overlay visibility |
| **Open Sprites Folder** | Open the custom sprites directory with a reload button |
| **Launch at Login** | Start deskpals automatically on login |

### Repositioning

Hold **Shift+Ctrl** and **drag** the overlay window to move it anywhere on screen. The position is saved automatically.

### URL Scheme

Control deskpals from Terminal, scripts, or other apps using the `deskpals://` URL scheme:

```bash
# Toggle a Pokemon on/off (adds if not active, removes if already active)
open "deskpals://pokemon?name=charizard&gen=1"
open "deskpals://pokemon?name=umbreon&gen=2&shiny=true"

# Toggle visibility
open "deskpals://toggle"

# Resize overlay
open "deskpals://resize?width=600&height=400"

# Reposition overlay
open "deskpals://move?x=200&y=300"
```

---

## Raycast Extension

A companion [Raycast extension](https://www.raycast.com/kian/deskpals) is available for quick control without touching the menu bar:

| Command | Description | Type |
|---------|-------------|------|
| **Change Sprite** | Searchable list of all 565 Pokemon with shiny toggle | List view |
| **Toggle Visibility** | One-click show/hide | No-view (instant) |
| **Resize Area** | Form to set overlay width and height | Form view |

Install it from the [Raycast Store](https://www.raycast.com/kian/deskpals) or search "deskpals" in Raycast.

> The Raycast extension communicates with the main app via the `deskpals://` URL scheme, so deskpals must be running.

---

## Adding Your Own Custom Sprites

You can add **any character or sprite** to deskpals — it doesn't have to be a Pokemon! Here's how:

### What You Need

- **One or more animated GIF files** of your character (pixel art works best)
- Each GIF should be small (around 32x32 to 64x64 pixels)
- Transparent backgrounds are recommended so the sprite blends with your desktop

### Step-by-Step Guide

**1. Open the Custom Sprites folder**

Click the deskpals menu bar icon, then click **"Open Sprites Folder"**. This opens a folder on your Mac where custom sprites live.

> The folder is located at `~/Library/Application Support/deskpals/CustomSprites/`

**2. Create a folder for your character**

Inside the Custom Sprites folder, create a **new folder** with your character's name. Use lowercase letters, no spaces (use hyphens or underscores instead).

```
CustomSprites/
  └── my-character/
```

**3. Add your GIF files**

Put your animated GIFs inside the folder. The naming convention is:

| File | Required? | Description |
|------|-----------|-------------|
| `default_idle_8fps.gif` | **Yes** | Standing still animation |
| `default_walk_8fps.gif` | No | Walking animation |
| `shiny_idle_8fps.gif` | No | Alternate "shiny" idle |
| `shiny_walk_8fps.gif` | No | Alternate "shiny" walk |

Only `default_idle_8fps.gif` is required. If a walk animation is missing, the idle one is used instead. If shiny variants are missing, the default ones are used.

Your folder should look like this:

```
CustomSprites/
  └── my-character/
        ├── default_idle_8fps.gif    (required)
        ├── default_walk_8fps.gif    (optional)
        ├── shiny_idle_8fps.gif      (optional)
        └── shiny_walk_8fps.gif      (optional)
```

**4. Reload in deskpals**

Click the **reload button** (circular arrow icon) next to "Open Sprites Folder" in the menu bar. Your custom character will now appear in the list labeled **"Custom"** in purple.

**5. Select your character**

Find your character in the Pokemon list and click it to toggle it on. It will start walking around your desktop!

### Tips

- **GIF frame rate:** The `8fps` in the filename is just a naming convention — your GIFs can be any frame rate
- **Sprite size:** The sprite is displayed at 48x48 points by default, scaled by your Sprite Scale setting (1x–5x)
- **Multiple characters:** Add as many custom sprite folders as you like
- **Sharing sprites:** To share a custom sprite with someone, just send them the folder — they drop it into their own Custom Sprites folder

### Example: Adding a Custom Cat Sprite

```bash
# 1. Open the folder (or navigate manually)
open ~/Library/Application\ Support/deskpals/CustomSprites/

# 2. Create a folder for your sprite
mkdir my-cat

# 3. Copy your GIFs into it
cp cat_idle.gif my-cat/default_idle_8fps.gif
cp cat_walk.gif my-cat/default_walk_8fps.gif

# 4. Click the reload button in deskpals menu bar
# 5. Select "My-cat" from the list — done!
```

---

## Architecture

```
deskpalsApp (@main)
  └── MenuBarExtra (.window style)
        └── MenuBarContentView (SwiftUI settings UI)

AppDelegate (NSApplicationDelegate)
  ├── Shared mode: single OverlayWindow with all sprites
  ├── Separate mode: one OverlayWindow per sprite
  │     ├── OverlayContentView (click-through via hitTest)
  │     │     └── SpriteImageView (animated GIF)
  │     └── AnimationEngine (60fps movement & physics)
  ├── AppSettings (ObservableObject, UserDefaults persistence)
  └── URL Scheme Handler (deskpals://)

Raycast Extension (TypeScript)
  └── Commands → open deskpals:// URLs → AppDelegate handles
```

**Data flow:** Settings changes in the menu bar UI publish via Combine. The overlay window observes these changes and updates the sprite, position, size, or visibility in real time. The animation engine ticks at 60fps, driving position updates with velocity-based physics.

**Click-through:** The overlay content view overrides `hitTest(_:)` to return `nil` for empty areas. This means clicks pass through to windows below, but you can still interact with the sprite itself.

---

## Project Structure

```
deskpals/
├── deskpals.xcodeproj/
├── deskpals/
│   ├── App/
│   │   ├── deskpalsApp.swift              # Entry point, MenuBarExtra
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
├── scripts/
│   └── build-release.sh         # Build & package for distribution
└── assets/
    └── deskpals-icon.icon/      # App icon
```

---

## Settings Reference

All settings persist across launches via UserDefaults.

| Setting | Default | Range |
|---------|---------|-------|
| `selectedPokemonList` | `[pikachu (gen 1)]` | Up to 10 Pokemon (JSON-encoded) |
| `isShiny` | `false` | — |
| `separateWindows` | `false` | — |
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

# NEON SLICE

**Cut, ride and rock in the neon city.**

A cyberpunk social action game for Roblox where street gangs compete in parkour with katanas. Players are "Riders" who glide across rails at incredible speeds, slicing through neon blocks and collecting energy to capture city districts.

## Features

- **Slash-casual gameplay** — Swipe to slice neon blocks flying towards you (Fruit Ninja meets Subway Surfers)
- **Auto-runner on rails** — 3-lane procedural track with increasing speed
- **District battles** — City map with 5 districts that guilds can capture
- **3v3 Raid system** — Compete in timed raid runs for territory control
- **Katana shop** — Unlock and equip katanas with unique colors, trails, and effects
- **Neon cyberpunk aesthetics** — Purple/blue/pink synthwave visuals with bloom and atmosphere
- **Combo system** — Chain slices for score multipliers up to x8
- **Persistent data** — Player progress saved via DataStoreService
- **Full HUD** — Score, combo, energy bar, speed indicator, and results screen
- **Loading screen** — Animated cyberpunk loading sequence

## Getting Started

### Prerequisites

- [Roblox Studio](https://www.roblox.com/create) (free)
- [Rojo](https://rojo.space/) (free, for syncing files to Studio)

### Setup

1. **Install Rojo** — Get the [Rojo VS Code extension](https://marketplace.visualstudio.com/items?itemName=evaera.vscode-rojo) or the standalone CLI.

2. **Install the Rojo Roblox Studio plugin** — In Roblox Studio, install the Rojo plugin from the Plugin Manager or download it from [rojo.space](https://rojo.space/).

3. **Clone this repository:**
   ```bash
   git clone https://github.com/bhopmaster656-cmd/memetric-game.git
   cd memetric-game
   ```

4. **Start the Rojo server:**
   ```bash
   rojo serve
   ```

5. **Connect from Roblox Studio:**
   - Open Roblox Studio and create a new Baseplate place (or open an existing one).
   - Click the **Rojo** plugin button in the toolbar.
   - Click **Connect** to sync the project files into Studio.

6. **Play!** — Press the Play button in Roblox Studio to test the game.

### Alternative: Build a place file

```bash
rojo build -o NeonSlice.rbxlx
```

Then open `NeonSlice.rbxlx` directly in Roblox Studio.

## Project Structure

```
default.project.json          — Rojo project configuration
src/
├── ReplicatedStorage/        — Shared modules (Config, BlockTypes, KatanaData, etc.)
├── ReplicatedFirst/          — Loading screen (runs before everything else)
├── ServerScriptService/      — Server scripts (GameManager, BlockSpawner, TrackSystem, etc.)
├── StarterPlayer/
│   └── StarterPlayerScripts/ — Client scripts (SliceController, CameraController, etc.)
└── StarterGui/               — GUI scripts (MainMenu, HUD, ShopGui, DistrictMapGui, RaidUI)
```

## Controls

| Action              | Input                  |
| ------------------- | ---------------------- |
| Slice blocks        | Click + drag / swipe   |
| Open Katana Shop    | Press **B**            |
| Open District Map   | Press **M**            |
| Open Raid Menu      | Press **R**            |
| End current run     | Click **END RUN** button |

## Customization

- **Sound assets:** Replace the `rbxassetid://0` placeholders in `MusicController.client.lua` and `KatanaData.lua` with your own Roblox audio asset IDs.
- **Add katanas:** Edit `src/ReplicatedStorage/KatanaData.lua` to add new katana definitions.
- **Add districts:** Edit `src/ReplicatedStorage/DistrictData.lua` to create new city areas.
- **Tune gameplay:** Adjust speeds, scoring, and spawn rates in `src/ReplicatedStorage/Config.lua`.

## License

See [LICENSE](LICENSE) for details.

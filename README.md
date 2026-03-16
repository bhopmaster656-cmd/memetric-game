# NEON SLICE

**Cut, ride and rock in the neon city.**

> 🇷🇺 **[Инструкция на русском (SETUP_RU.md)](SETUP_RU.md)** — подробная пошаговая инструкция по запуску игры.

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

## Quick Start

### Option A: Download pre-built file (easiest — no tools needed)

1. Download [**NeonSlice.rbxlx**](NeonSlice.rbxlx) directly from this repository (click the link, then click **Download**)
2. Open it in [Roblox Studio](https://www.roblox.com/create) → Press **▶ Play**

> ℹ️ The file is automatically rebuilt by GitHub Actions whenever the source code changes.

### Option B: Build it yourself with Rojo

1. Install [Roblox Studio](https://www.roblox.com/create) (free) and [Rojo](https://github.com/rojo-rbx/rojo/releases)
2. Install the Rojo plugin in Studio: run `rojo plugin install`
3. Build the game file:
   ```bash
   git clone https://github.com/bhopmaster656-cmd/memetric-game.git
   cd memetric-game
   rojo build default.project.json -o NeonSlice.rbxlx
   ```
   **Or use the helper scripts:** `scripts\build.bat` (Windows) / `./scripts/build.sh` (Mac/Linux)
4. Open `NeonSlice.rbxlx` in Roblox Studio → Press **▶ Play**

That's it! 🎉

---

## Alternative: Live Sync (for development)

If you want to edit files and see changes instantly in Studio:

```bash
rojo serve
```

Then in Roblox Studio: create a new Baseplate → click the **Rojo** plugin → click **Connect**.

Helper scripts: `scripts\serve.bat` (Windows) or `./scripts/serve.sh` (Mac/Linux).

## Project Structure

```
default.project.json          — Rojo project configuration
aftman.toml                   — Automatic Rojo version management
Makefile                      — Build commands (make build, make serve)
scripts/                      — Helper scripts for Windows/Mac/Linux
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

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `rojo: command not found` | Download Rojo from [releases](https://github.com/rojo-rbx/rojo/releases) and add to PATH |
| Rojo plugin won't connect | Make sure `rojo serve` is running, check that port 34872 is not blocked |
| No sounds in game | Replace `rbxassetid://0` placeholders with real audio asset IDs |
| DataStore errors in Studio | Go to Game Settings → Security → Enable Studio Access to API Services |
| Character doesn't move | Press **▶ START RUN** in the main menu — movement is automatic |

## License

See [LICENSE](LICENSE) for details.

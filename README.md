# 🎣 Memetric Fishing – Roblox Game Template

A fully featured fishing game template built with brainrot-style collectibles.
All core systems are complete and ready to customize.

## Features

- **9 Brainrot Collectible Templates** – Normal, Golden, Diamond rarities (easily expandable)
- **Complete Fishing System** – Cast, reel, rarity roll, and reward
- **Quest System** – Daily & repeatable quests with custom objectives
- **Rebirth System** – Reset for permanent stat bonuses
- **Spin / Wheel System** – Daily spin for coins, boosts, and rare collectibles
- **VIP System** – Gamepass perks: bonus luck, extra rewards
- **Shop / Pack System** – Purchasable packs and gamepasses
- **Economy System** – Balanced coin earnings from all activities

---

## Getting Started

### Prerequisites

| Tool | Purpose | Install |
|------|---------|---------|
| [Roblox Studio](https://www.roblox.com/create) | Run and publish the game | Download from roblox.com |
| [Aftman](https://github.com/LPGhatguy/aftman/releases) | Toolchain manager (installs Rojo) | See below |

### 1 – Install Aftman

**Windows (PowerShell)**
```powershell
# Download and run the installer from https://github.com/LPGhatguy/aftman/releases
# Then add it to PATH when prompted, or run:
aftman self-install
```

**macOS / Linux**
```bash
# Download the binary from https://github.com/LPGhatguy/aftman/releases
# then make it executable and place it on PATH, e.g.:
chmod +x aftman
sudo mv aftman /usr/local/bin/
aftman self-install
```

### 2 – Install Rojo via Aftman

Clone this repository, then run:
```bash
aftman install
```

This reads `aftman.toml` and installs Rojo 7.4.4 automatically.
Verify: `rojo --version` should print `rojo 7.4.4`.

### 3a – Build the place file (one-shot)

```bash
rojo build default.project.json -o MemetricFishing.rbxlx
# or using the Makefile shortcut:
make build
```

Open `MemetricFishing.rbxlx` in Roblox Studio and press **Play** to test.

### 3b – Live-sync with Roblox Studio (recommended while editing)

```bash
rojo serve
# or: make serve
```

In Roblox Studio open the **Rojo** plugin panel and click **Connect** to the default
address (`localhost:34872`). All Lua file saves in your editor will be instantly
reflected in Studio.

---

## Project Structure

```
src/
  ReplicatedStorage/Modules/      – Shared ModuleScripts (config + logic)
  ServerScriptService/            – Server Scripts & ModuleScripts
  StarterGui/                     – Client LocalScripts (UI)
  StarterPlayerScripts/           – Client LocalScripts (input)
```

### Rojo name → Roblox class mapping

| File suffix | Roblox class |
|-------------|-------------|
| `*.server.lua` | `Script` (runs on server, **cannot** be `require()`d) |
| `*.client.lua` | `LocalScript` (runs on each client) |
| `*.lua` | `ModuleScript` (shared library, loaded via `require()`) |

---

## Customization

| File | What to change |
|------|---------------|
| `src/ReplicatedStorage/Modules/RarityConfig.lua` | Add / replace brainrot templates and rarities |
| `src/ReplicatedStorage/Modules/GameConfig.lua` | Economy rates, rebirth bonuses, VIP perks |
| `src/ReplicatedStorage/Modules/QuestConfig.lua` | Quest objectives and rewards |
| `src/ReplicatedStorage/Modules/ShopConfig.lua` | Purchasable packs and gamepass prices |

After building, replace placeholder **3-D models** and **UI images** inside Roblox Studio,
then set real **GamePass** and **DevProduct** IDs in `GameConfig.lua`.

---

## CI / CD

Every push triggers a GitHub Actions build (`.github/workflows/build.yml`).
When you publish a **GitHub Release**, the workflow attaches `MemetricFishing.rbxlx`
as a release asset automatically.

---

## Key Bindings (in-game)

| Key | Action |
|-----|--------|
| **E** | Cast rod / reel in |
| **I** | Toggle inventory |
| **Q** | Toggle quest panel |
| **X** | Toggle daily spin |
| **R** | Toggle rebirth dialog |
| **P** | Toggle shop |

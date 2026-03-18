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

## Project Structure

```
src/
  ReplicatedStorage/Modules/      – Shared Lua modules
  ReplicatedStorage/RemoteEvents/ – RemoteEvent/Function instances
  ServerScriptService/            – Server-side scripts
  StarterGui/                     – UI client scripts
  StarterPlayerScripts/           – Player client scripts
```

## Building

Requires [Rojo](https://rojo.space/) (pinned via `aftman.toml`).

```bash
# Install Aftman toolchain manager, then:
aftman install
rojo build default.project.json -o MemetricFishing.rbxlx
# or live-sync:
rojo serve
```

## Customization

1. Edit `src/ReplicatedStorage/Modules/RarityConfig.lua` to add/replace brainrot templates
2. Edit `src/ReplicatedStorage/Modules/GameConfig.lua` to tune economy & rarities
3. Edit `src/ReplicatedStorage/Modules/QuestConfig.lua` for quest objectives
4. Edit `src/ReplicatedStorage/Modules/ShopConfig.lua` for packs & gamepasses
5. Replace 3-D models / UI assets inside Roblox Studio after building

# NEON WARDROBE

**Genre:** Social Hub / Competitive Style Simulator / Mini-games  
**Visual style:** Cyberpunk-kawaii — neon signs, pastel tones, grunge textures, cute characters

---

## How to open

1. Install **Roblox Studio** (free at [roblox.com/create](https://www.roblox.com/create))
2. Double-click `NeonWardrobe.rbxlx` — Studio opens it automatically
3. Press **Play** (F5) to test the game locally, or **Publish** to upload it to Roblox

---

## Game concept

Players enter **NEON WARDROBE**, a massive neon-lit multi-floor nightclub / mall.  
The goal is to earn **Reputation** as a style icon and unlock higher floors.

### Three floors
| Floor | Name | Rep required |
|-------|------|--------------|
| 1 | **Main Club** — open to everyone, Battle Zone, Style Shop | 0 |
| 2 | **VIP Zone** — exclusive boutique, lounge | 100 |
| 3 | **Celebrity Floor** — top players only, Hall of Fame | 500 |

### Look Battle (core mechanic)
Walk up to any player and press **CHALLENGE**.  
A 15-second mini-game starts:
* A random **theme** is shown (e.g. *"Cosmic Rave"*, *"90s Villain"*)
* Press **emote buttons** to impress the crowd
* Nearby players vote for their favourite look
* Winner gains **+25 Rep** and **+50 NeonCoins**

### Dynamic Mood system
Every player has a **Mood** (Cool, Fierce, Happy, Cute, Angry, Mysterious).  
Open **OUTFIT** → select a mood → your character glows with the matching neon colour.  
Mood affects which zones you can interact with.

### Elevator
Use the **ELEVATOR** button (or press **E** near a lift panel) to travel between floors.  
Higher floors require the corresponding Reputation threshold.

### Economy — NeonCoins
* Starting coins: **100**
* Win a battle: **+50 coins**
* Lose a battle: **+10 coins** (consolation)
* Vote as spectator: **+3 Rep**

---

## File structure (inside `NeonWardrobe.rbxlx`)

```
Workspace
└── SpawnLocation          — players spawn on Floor 1

Lighting                   — night sky, bloom, colour correction, purple fog

ReplicatedStorage
├── Modules
│   ├── GameConfig         — all tunable constants (rep thresholds, battle duration…)
│   └── MoodData           — outfit items catalogue
└── RemoteEvents           — StartBattle · BattleResult · UpdateCurrency
                             UnlockFloor · UpdateMood · RequestElevator

ServerScriptService
├── WorldBuilder           — procedurally builds the 3-floor neon building
├── GameManager            — player data, leaderstats, currency and reputation
├── BattleSystem           — Look Battle logic, voting, cooldowns
└── ProgressionSystem      — elevator validation and teleport, floor-unlock announcements

StarterPlayerScripts
└── MainClient             — all client logic: HUD, Battle UI, Outfit panel, Elevator UI

StarterGui
├── MainHUD                — HUD container (populated by MainClient)
├── BattleUI               — Battle panel container
└── ElevatorUI             — Elevator panel container
```

---

## Customisation

All game-balance numbers live in `ReplicatedStorage > Modules > GameConfig`:

```lua
FLOOR_REQUIREMENTS    = { [2]=100, [3]=500 }   -- Rep needed per floor
BATTLE_DURATION       = 15                      -- seconds
BATTLE_WIN_REPUTATION = 25
STARTING_CURRENCY     = 100
BATTLE_THEMES         = { "Cosmic Rave", ... }  -- add your own themes here
```

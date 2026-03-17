# CityLife – Roblox City RPG

A life-simulation city game for Roblox built with Lua and the Rojo workflow.
The RBXLX game file is generated from the Lua source files in `src/` using a Python script.

---

## 🎮 Game Overview

**CityLife** is a large open-world city where players can:

| Feature | Description |
|---|---|
| 🧑‍💼 **Jobs** | Firefighter, Police, Doctor, Teacher, Mechanic, Plumber, Deputy, Mayor, Chef, Construction Worker |
| 🏠 **Real Estate** | Buy/sell Studio Apartments, Houses, Mansions, and Land Plots |
| 🏪 **Businesses** | Open and operate Auto Repair Shops, Car Dealerships, Restaurants, Gas Stations, and more |
| 🔨 **Auctions** | List properties or businesses on the Auction House; bid against other players |
| 💸 **Economy** | Earn salary every minute, collect passive business income, pay property taxes |
| 🏙️ **City Map** | Civic District, Residential District, Commercial District, Industrial District, Park District, Dealership Row |
| 💰 **Monetization** | Cash Packs (Developer Products) and Game Passes (Premium Citizen, VIP Resident, Business Tycoon) |

---

## 📁 Project Structure

```
CityLife.rbxlx               ← Game file (open in Roblox Studio)
default.project.json         ← Rojo project configuration
aftman.toml                  ← Rojo toolchain pinning
Makefile                     ← make build to rebuild via Rojo
scripts/
  generate_rbxlx.py          ← Python generator (no Rojo required)
src/
  ServerScriptService/
    DataStore.server.lua     ← Player data persistence
    JobSystem.server.lua     ← Jobs, teams, salary
    PropertySystem.server.lua ← Buy/sell homes and land
    BusinessSystem.server.lua ← Open/close businesses, passive income
    AuctionSystem.server.lua  ← Auction house
    TaxSystem.server.lua      ← Periodic property/business taxes
    CityBuilder.server.lua    ← Procedural city map generation
    Monetization.server.lua   ← Developer Products & Game Passes
  ReplicatedStorage/
    Modules/
      GameConfig.lua         ← Central configuration (jobs, prices, tax rates)
      RemoteEvents.lua       ← Shared Remote Events / Functions
  StarterGui/
    MainHUD.client.lua       ← HUD (cash, job, notification system)
    JobMenu.client.lua       ← Job selection UI
    PropertyMenu.client.lua  ← Real estate market UI
    BusinessMenu.client.lua  ← Business market UI
    AuctionMenu.client.lua   ← Auction house UI
    ShopMenu.client.lua      ← Robux store (cash packs, game passes)
  StarterPlayer/StarterPlayerScripts/
    PlayerController.client.lua ← Character nameplate, proximity job prompts
```

---

## Getting Started

### Option A – Use the pre-built RBXLX (recommended)
1. Clone or download this repository.
2. Open **`CityLife.rbxlx`** in Roblox Studio.
3. Publish to Roblox and enter your real Developer Product / Game Pass IDs in `src/ReplicatedStorage/Modules/GameConfig.lua`.

### Option B – Rebuild with the Python generator
```bash
python3 scripts/generate_rbxlx.py
# Outputs: CityLife.rbxlx
```

### Option C – Live editing with Rojo
```bash
# Install aftman first: https://github.com/LPGhatguy/aftman
aftman install
rojo serve default.project.json
# Then in Roblox Studio, connect to the Rojo server
```

---

## Monetization Setup

1. Open your Roblox game in the Creator Dashboard.
2. Create Developer Products for each Cash Pack.
3. Create Game Passes for Premium Citizen, VIP Resident, Business Tycoon.
4. Replace the `id = 0` placeholder values in `GameConfig.lua` with the real asset IDs.

---

## Economy at a Glance

| Item | Price | Tax / Cycle |
|---|---|---|
| Studio Apartment | $10,000 | 2% |
| Apartment | $50,000 | 1.8% |
| House | $150,000 | 1.5% |
| Mansion | $500,000 | 1.2% |
| Auto Repair Shop | $75,000 | 5% of revenue |
| Car Dealership | $200,000 | 6% of revenue |
| Restaurant | $100,000 | 5% of revenue |

Salary is paid every **60 seconds**. Property/business taxes are collected every **5 minutes**.

---

## License

See [LICENSE](LICENSE).

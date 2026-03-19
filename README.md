# Neon Gravity 🌆⚡

A cyberpunk gravity-flip auto-runner game. Inspired by Mad Dex but built around a unique
gravity-control mechanic. No installs required — runs entirely in the browser.

## 🎮 Story

Distant future. The megacity is split into two tiers: the **Upper Spheres** (floating islands)
and the **Lower Levels** (industrial slums). The experimental **Gravitron** reactor has gone
rogue and is tearing the city apart. Kay, a young repair technician, must climb through the
chaos to rescue his sister trapped in the Upper Spheres — while dodging the **Architect** AI
that sees the disaster as "natural selection."

## 🕹️ Controls

| Key | Action |
|-----|--------|
| `Space` / `↑` / `W` | Jump |
| `Shift` / `Z` | **Flip gravity** — Kay runs on ceilings too |
| `X` / `Q` | Throw gravity anchor (first press) / Pull to anchor (second press) |
| `R` | Restart current level |

## ⚙️ Core Mechanics

* **Gravity Flip** — the core mechanic. Switch between floor and ceiling gravity at any
  moment. Your neon outline turns **red** (gravity pulls down) or **blue** (gravity pulls up).
* **Gravity Anchors** — throw a magnetic sphere. It sticks to any surface. Press again to
  instantly pull yourself to it. Two anchors per section; restore them at glowing **terminals**.
* **Destructible Bridges** — run across a crumbling bridge and it collapses behind you.
* **Drones** — enemy robots that always match your gravity direction.
* **Ghost Run** — a semi-transparent replay of your last attempt (Celeste-style).

## 💡 Hazards

| Hazard | Description |
|--------|-------------|
| Spikes | Instant death on contact |
| Lasers | Flash on/off — time your crossing |
| Red Fields | Deadly energy barriers |
| Blue Fields | Teleport portals |
| Gravity Waves | Zones that fight your current gravity |

## 🗺️ Levels

1. **Нижние Уровни (Lower Depths)** — Tutorial: gaps, spikes, first lasers.
2. **Индустриальные Трущобы (Industrial Slums)** — Dense laser grids and patrolling drones.
3. **Верхние Сферы (Upper Spheres)** — Hardest gauntlet; reach the Architect's stronghold.

## 🚀 Running

```bash
# No build step — just open in a browser
open index.html
# or serve locally:
python3 -m http.server 8080
```

Then visit `http://localhost:8080`.

## 📂 Project Layout

```
index.html        Entry point
css/style.css     Cyberpunk neon UI styles
js/game.js        Complete game engine (physics, AI, rendering, levels)
```

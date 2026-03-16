# 🏰 Средневековый Город — Градостроительный Симулятор

An HTML5 medieval city-building simulator built with Canvas 2D. No framework dependencies — pure vanilla JavaScript.

## Features

- **Free-form building placement** — no grid; place buildings anywhere on the map
- **Procedural terrain** — islands with grass, forests, water, hills and mountains using fractional Brownian motion noise
- **14 building types** across 5 categories (Housing, Food, Industry, Commerce, Civic)
- **Deep resident simulation** — named NPCs with skills, families, careers, happiness and personal dreams
- **Resource production chains** — Food → Wood/Stone → Tools → Goods → Gold
- **Season cycle** — Spring, Summer, Autumn, Winter with visual changes
- **Random events system** — 10 moral dilemmas with multiple choices and consequences
- **Laws & decrees** — 5 policy options affecting economy and citizen happiness
- **Marriage & inheritance** — residents form families; children inherit parent skills
- **Road drawing** — freehand road placement
- **Pan & zoom camera** — mouse drag + scroll wheel, pinch-to-zoom on mobile

## How to Play

1. Open `index.html` in a modern browser (Chrome/Firefox/Edge).
2. Select a building from the left panel.
3. Click on the map to place it.
4. Watch your residents move in and start working.
5. Manage resources, respond to events, pass laws.

## Controls

| Action | Control |
|--------|---------|
| Pan camera | Left-click drag or middle-click drag |
| Zoom | Mouse wheel |
| Place building | Select from left panel → left-click on map |
| Draw road | Click "🛤️ Дорога" → click and drag |
| Demolish | Click "💣 Снос" → click a building |
| Inspect building | Click a building |
| Inspect resident | Click on a moving dot |
| Rename city | Click the city name in the top bar |
| Pause / speed | ⏸️ and speed buttons (top right of HUD) |

## Project Structure

```
index.html          Main game page
css/
  style.css         Dark medieval theme
js/
  constants.js      Building definitions, resources, game config
  utils.js          Math helpers, noise, event emitter
  names.js          Medieval name tables for residents
  world.js          Procedural terrain generation
  building.js       Building class & manager
  resident.js       Resident NPC simulation
  economy.js        Resources, taxes, law upkeep
  events.js         Random event pool & system
  renderer.js       Canvas 2D rendering (terrain, buildings, residents)
  ui.js             UI panels, tabs, dialogs, notifications
  input.js          Mouse / touch input handling
  game.js           Main game loop & orchestration
```

## Technology

- **HTML5 Canvas 2D** — rendering
- **Vanilla JavaScript (ES6+)** — game logic
- **No external dependencies**


# НЕО СИТИ: ЭПОХА ИИ — Neo City: AI Era

A browser-based idle merge city-builder set in a futuristic AI-powered metropolis.  
Merge identical buildings to unlock more advanced structures, grow your city's passive income, and reach the ultimate **Нео-Центр** (Neo Core).

## How to Play

1. **Buy a building** — spend credits on a **Нано-Под** from the shop.
2. **Collect idle income** — every building generates credits per second automatically.
3. **Drag & drop to merge** — drag one building onto an identical-tier building to combine them into the next tier.
4. **Complete quests** — each quest rewards bonus credits and unlocks the next challenge.
5. **Reach Нео-Центр (tier 10)** — the ultimate goal!

### Controls
| Action | Input |
|---|---|
| Buy building | Click **Купить здание** or press **Space** |
| Move building | Drag it to an empty cell |
| Merge buildings | Drag onto an identical-tier building |
| New game | Click **🔄 Новая игра** (with confirmation) |

## Building Tiers

| # | Name | Income/s |
|---|---|---|
| 1 | Нано-Под | 1 |
| 2 | Дата-Узел | 4 |
| 3 | Нейро-Ячейка | 12 |
| 4 | Квантум-Хаб | 36 |
| 5 | Голо-Башня | 108 |
| 6 | ИИ-Ядро | 324 |
| 7 | Кибер-Нексус | 972 |
| 8 | Тех-Шпиль | 2 916 |
| 9 | Сингулярность | 8 748 |
| 10 | Нео-Центр | 26 244 |

## Running Locally

No build step required — pure HTML/CSS/JavaScript.

```bash
# Any static file server works, e.g.:
python3 -m http.server 8080
# Then open http://localhost:8080
```

Or simply open `index.html` in a browser.

## Screenshots

| Empty city | First buildings | Higher tiers |
|---|---|---|
| ![start](https://github.com/user-attachments/assets/367b0d04-52ac-4e92-b5b9-5f1d9c06fbc0) | ![buildings](https://github.com/user-attachments/assets/cd5adcd6-15b0-4e90-97a7-e56d453d2e4c) | ![highertiers](https://github.com/user-attachments/assets/5cdf9729-5869-4c3b-a148-42da4e31b224) |

## Project Structure

```
index.html          — Main game page
css/style.css       — Cyberpunk/neon theme styles
js/config.js        — Building definitions & game constants
js/utils.js         — Number formatting & math helpers
js/particles.js     — Merge sparks & floating income text
js/renderer.js      — Canvas rendering (grid + 10 building types)
js/grid.js          — Grid state, move & merge logic
js/game.js          — Main game loop, income ticks, save/load
js/ui.js            — DOM updates (shop, quest bar, toasts)
js/main.js          — Entry point & responsive canvas sizing
```

## Technical Notes

- **No dependencies** — vanilla JS + HTML5 Canvas
- **Auto-save** — game state persisted to `localStorage` every 15 s
- **Responsive** — canvas cell size scales to viewport width
- **Touch support** — drag & merge works on mobile devices

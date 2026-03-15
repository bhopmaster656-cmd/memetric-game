# NEON WARDROBE

**Жанр / Genre:** Социальный хаб / Social Hub · Соревновательный симулятор стиля / Style Simulator  
**Стиль / Visual style:** Cyberpunk-kawaii — neon signs, pastel tones, grunge textures, cute characters

---

## 🚀 Как запустить игру (пошаговая инструкция) / How to run the game

### Шаг 1 — Скачать и установить Roblox Studio

1. Откройте браузер и перейдите на **https://create.roblox.com**
2. Нажмите кнопку **"Start Creating"** (Начать создавать).
3. Если у вас нет аккаунта Roblox — зарегистрируйтесь бесплатно.
4. После входа нажмите **"Download Studio"** — скачается установщик.
5. Запустите установщик и дождитесь завершения установки.  
   *(Roblox Studio полностью бесплатен.)*

---

### Шаг 2 — Открыть файл игры

#### Способ А — двойной клик (самый простой)
1. Найдите файл **`NeonWardrobe.rbxlx`** в папке проекта.
2. Дважды кликните по нему — Roblox Studio откроет игру автоматически.

#### Способ Б — через меню Roblox Studio
1. Откройте Roblox Studio.
2. В левом верхнем углу нажмите **File → Open from File…**
3. Выберите файл `NeonWardrobe.rbxlx` и нажмите **Открыть**.

> 💡 **Скачать файл с GitHub:**  
> Если вы видите это на GitHub — нажмите на `NeonWardrobe.rbxlx` в списке файлов,  
> затем нажмите кнопку **⬇ Download raw file** (справа сверху) и сохраните на компьютер.

---

### Шаг 3 — Запустить и протестировать локально

После открытия файла в Studio:

| Действие | Клавиша / Кнопка |
|---|---|
| Тест в одиночку (Play Solo) | **F5** или кнопка ▶ **Play** на панели сверху |
| Остановить тест | **Shift+F5** или кнопка ⏹ **Stop** |
| Тест с несколькими игроками | Кнопка **▶ Play** → вкладка **Test** → **Local Server** |

**Что увидите при запуске:**
- Персонаж появится на зелёной платформе (Floor 1 — Main Club).
- Снизу экрана появятся кнопки **CHALLENGE**, **OUTFIT**, **ELEVATOR**.
- В Output (вид → Output) должны появиться строки:
  ```
  [WorldBuilder] NEON WARDROBE built successfully!
  [GameManager] Initialised!
  [BattleSystem] Initialised!
  [ProgressionSystem] Initialised!
  [MainClient] NEON WARDROBE client ready!
  ```

#### Тест Look Battle с несколькими игроками (локально)
1. Панель **Test** → нажмите **▶ Start** рядом с «Local Server».
2. Studio запустит сервер + несколько клиентских окон.
3. В клиентском окне подойдите к другому персонажу и нажмите **CHALLENGE**.

---

### Шаг 4 — Опубликовать игру на Roblox (чтобы играли другие)

1. В Studio: **File → Publish to Roblox…**
2. Нажмите **Create new experience** и заполните:
   - **Name:** `NEON WARDROBE`
   - **Description:** опишите игру
   - **Genre:** Social
3. Нажмите **Create** → затем **Publish**.
4. Откройте **Game Settings → Permissions** и выберите **Public**, чтобы игра стала доступна всем.
5. Скопируйте ссылку вида `https://www.roblox.com/games/XXXXXXXXX` и поделитесь с друзьями!

---

### ❓ Частые проблемы (Troubleshooting)

| Проблема | Решение |
|---|---|
| Studio не открывает `.rbxlx` по двойному клику | Установите Studio заново с [create.roblox.com](https://create.roblox.com), чтобы перепривязать расширение файла |
| Пустой экран при запуске, нет здания | Откройте **View → Output** — посмотрите ошибки. Убедитесь, что скрипты не отключены (Disabled=false) |
| Кнопка CHALLENGE не реагирует | Нужен второй игрок в радиусе 25 studs. Используйте Local Server test для проверки |
| Лифт пишет «LOCKED» | Нужна репутация: Floor 2 → 100 Rep, Floor 3 → 500 Rep. Выигрывайте батлы! |
| Ошибка «attempt to index nil value '_G.GameManager'» | GameManager стартует позже других скриптов. Просто нажмите **Stop** и снова **Play** |

---

## Управление в игре

| Кнопка | Действие |
|---|---|
| **CHALLENGE** | Бросить вызов ближайшему игроку (Look Battle) |
| **OUTFIT** | Открыть меню настроения/стиля (6 Mood-цветов) |
| **ELEVATOR** | Открыть лифт для перемещения между этажами |
| **E** (возле лифта) | Вызвать лифт с помощью ProximityPrompt |
| Кнопки голосования | Появляются во время чужого батла — голосуй за лучший образ! |

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

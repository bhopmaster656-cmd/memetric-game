# 🏙️ Evergreen County — Roblox Life Simulator

**Evergreen County** — это симулятор жизни для Roblox: открытый мир, живая экономика, профессии, строительство, сезоны и выживание. Проект собирается с помощью [Rojo](https://rojo.space/) и открывается в Roblox Studio.

---

## 📋 Содержание

1. [Способ 1 — Скачать готовый файл (просто и быстро)](#способ-1--скачать-готовый-файл-просто-и-быстро)
2. [Способ 2 — Собрать из исходного кода](#способ-2--собрать-из-исходного-кода)
3. [Открытие в Roblox Studio](#открытие-в-roblox-studio)
4. [Тестирование игры](#тестирование-игры)
5. [Публикация на Roblox](#публикация-на-roblox)
6. [Как играть — краткое руководство](#как-играть--краткое-руководство)
7. [Структура проекта](#структура-проекта)

---

## Способ 1 — Скачать готовый файл (просто и быстро)

> Этот способ **не требует установки никаких инструментов**. Достаточно только Roblox Studio.

**Шаг 1.** Перейди на страницу репозитория на GitHub:
```
https://github.com/bhopmaster656-cmd/memetric-game
```

**Шаг 2.** Нажми на вкладку **Actions** (верхнее меню репозитория).

**Шаг 3.** В списке слева выбери воркфлоу **"Build EvergreenCounty.rbxlx"**.

**Шаг 4.** Кликни на самый последний (верхний) запуск со статусом ✅ (зелёная галочка).

**Шаг 5.** Прокрути страницу вниз до раздела **Artifacts** и скачай файл **`EvergreenCounty-rbxlx`**.

**Шаг 6.** Распакуй архив — внутри будет файл `EvergreenCounty.rbxlx`.

**Шаг 7.** Перейди к разделу [Открытие в Roblox Studio](#открытие-в-roblox-studio) ниже.

---

## Способ 2 — Собрать из исходного кода

> Используй этот способ, если хочешь вносить правки в скрипты и сразу видеть результат.

### 2.1 Требования

| Инструмент | Где скачать | Примечание |
|---|---|---|
| **Roblox Studio** | https://www.roblox.com/create | Бесплатно, нужна учётная запись Roblox |
| **Aftman** (менеджер инструментов) | https://github.com/LPGhatguy/aftman/releases | Скачай `aftman-x86_64-windows.zip` для Windows |
| **Git** (опционально) | https://git-scm.com/downloads | Только если хочешь клонировать репо |

### 2.2 Установка Aftman

**Windows:**

1. Скачай `aftman-x86_64-windows.zip` со страницы [релизов Aftman](https://github.com/LPGhatguy/aftman/releases).
2. Распакуй архив в любую папку, например `C:\aftman\`.
3. Добавь эту папку в **PATH**:
   - Нажми `Win + R`, введи `sysdm.cpl` → вкладка **Дополнительно** → **Переменные среды**.
   - В разделе **Системные переменные** найди `Path`, нажми **Изменить**, добавь `C:\aftman\`.
4. Открой новый терминал (PowerShell или cmd) и выполни:
   ```powershell
   aftman --version
   ```
   Должна появиться версия Aftman.

**macOS / Linux:**

```bash
# скачай и установи
curl -L https://github.com/LPGhatguy/aftman/releases/latest/download/aftman-x86_64-linux.zip -o /tmp/aftman.zip
unzip /tmp/aftman.zip -d ~/.aftman
export PATH="$PATH:$HOME/.aftman"
aftman --version
```

### 2.3 Скачать исходный код

**Вариант A — через Git:**
```bash
git clone https://github.com/bhopmaster656-cmd/memetric-game.git
cd memetric-game
```

**Вариант B — через браузер:**
1. На странице репозитория нажми зелёную кнопку **Code** → **Download ZIP**.
2. Распакуй архив, зайди в папку `memetric-game-main`.

### 2.4 Установить Rojo через Aftman

В папке проекта (где лежит файл `aftman.toml`) выполни:

```bash
aftman install
```

Aftman прочитает файл `aftman.toml` и автоматически установит **Rojo 7.4.4**.

Проверь установку:
```bash
rojo --version
# Должно вывести: rojo 7.4.4
```

### 2.5 Собрать файл `.rbxlx`

```bash
# Вариант через make (рекомендуется):
make build

# Или вручную:
rojo build default.project.json -o EvergreenCounty.rbxlx
```

После выполнения в папке проекта появится файл **`EvergreenCounty.rbxlx`**.

---

## Открытие в Roblox Studio

**Шаг 1.** Убедись, что **Roblox Studio** установлена и ты вошёл в свой аккаунт Roblox.
> Скачать: https://www.roblox.com/create → кнопка **Start Creating** → установи Roblox Studio.

**Шаг 2.** Открой файл двойным кликом:

- Дважды кликни на **`EvergreenCounty.rbxlx`** — Studio откроет его автоматически.

**Или** через меню Studio:
- Открой Roblox Studio → **File** → **Open from File...** → выбери `EvergreenCounty.rbxlx`.

**Шаг 3.** Studio загрузит игру. В панели **Explorer** (справа) ты увидишь всю структуру:
```
📁 Workspace
📁 ReplicatedStorage
   📁 Modules
   📁 RemoteEvents
📁 ServerScriptService
   📄 GameInit
   📄 PlayerDataManager
   📄 EconomyManager
   📄 WeatherManager
   ... и другие скрипты
📁 StarterGui
   📁 HUD
   📁 MainMenu
   📁 ShopGui
   ...
📁 StarterPlayer
   📁 StarterPlayerScripts
   📁 StarterCharacterScripts
```

---

## Тестирование игры

### Запуск одиночного теста (Solo Play)

1. В верхней панели Studio нажми кнопку **▶ Play** (или `F5`).
2. Studio откроет окно игры — ты будешь играть как обычный игрок.
3. Проверь:
   - Появился ли главный экран (MainMenu).
   - Работает ли HUD (шкалы голода, жажды, энергии, здоровья).
   - Открываются ли меню (Shop, Profession, Building, Market).
4. Чтобы остановить тест — нажми **⏹ Stop** (или `Shift+F5`).

### Запуск многопользовательского теста (Team Test)

1. В верхней панели нажми стрелку рядом с **▶ Play** → выбери **Start Server and Player(s)**.
2. Откроются два окна: одно — сервер, другое — клиент-игрок.
3. Это позволяет проверить взаимодействие сервера и клиента (экономику, профессии, рынок).

### Просмотр ошибок

- Открой **Output** (меню **View** → **Output**) — там выводятся все ошибки скриптов.
- Если видишь красные строки — это ошибки Lua. Кликни на ошибку, чтобы перейти к нужному скрипту.

---

## Публикация на Roblox

> Чтобы опубликовать игру, нужно войти в Roblox Studio под своим аккаунтом.

**Шаг 1.** В Studio: **File** → **Publish to Roblox As...**

**Шаг 2.** Заполни:
- **Name**: `Evergreen County`
- **Description**: описание игры
- **Genre**: Town and City
- **Playable devices**: выбери нужные (рекомендую Computer + Phone)

**Шаг 3.** Нажми **Create** — игра будет загружена на Roblox.

**Шаг 4.** Настройки игры (через roblox.com):
- Перейди на https://www.roblox.com/develop
- Найди свою игру → **Settings** (⚙)
- **Access**: установи **Public** чтобы игра была доступна всем
- **Gear** → **Configure this Place** → включи **Allow HTTP Requests** (нужно для API)

**Шаг 5.** Включи **DataStore** (для сохранения данных игроков):
- В Studio: **File** → **Game Settings** → вкладка **Security**
- Включи **Enable Studio Access to API Services**

**Шаг 6.** После каждого изменения скриптов обновляй игру:
```
File → Publish to Roblox  (Ctrl+P / Cmd+P)
```

---

## Как играть — краткое руководство

### Первый запуск
1. При входе в игру появится **Главное меню** — нажми **Играть**.
2. Твой персонаж появится в **Жилом районе (Suburbs)**.
3. Первоначально у тебя есть **велосипед** и немного денег.

### Основные механики

| Что делать | Как |
|---|---|
| Следи за статами | HUD вверху экрана показывает Здоровье, Голод, Жажду, Энергию |
| Поесть / попить | Нажми **Shop** в HUD → купи еду/воду → нажми **Use** в инвентаре |
| Выбрать профессию | Нажми **Profession** в HUD → выбери профессию |
| Купить предметы | Нажми **Shop** → выбери категорию → нажми **Buy** |
| Торговый рынок | Нажми **Market** → выставляй или покупай у других игроков |
| Строительство | Нажми **Build** в HUD → выбери предмет → кликай на участок |
| Транспорт | Подойди к велосипеду / машине → нажми **E** для посадки |
| Сезоны и погода | Автоматически меняются. Следи за температурой в HUD |

### Профессии
- **🪨 Шахтёр** — добывай руду в шахте (Промышленная зона)
- **🌾 Фермер** — арендуй поле, сажай культуры, собирай урожай
- **⭐ Шериф** — патрулируй город, арестовывай преступников
- **🔧 Механик** — ремонтируй машины других игроков
- **🏗️ Строитель** — принимай заказы на строительство
- **👨‍🍳 Повар** — готовь еду с временными баффами
- **🆓 Безработный** — подбирай мусор, случайные подработки

### Репутация
- **Зелёная (0–100)**: скидки в магазинах, доступ к лицензиям
- **Красная (-100–0)**: магазины отказывают в обслуживании, полиция атакует

### Экономика
- Цены **зависят от игроков**: много продавцов пшеницы → цена падает
- Раз в час платится **налог** на недвижимость
- В **банке** можно взять кредит или хранить деньги безопасно

---

## Структура проекта

```
memetric-game/
├── default.project.json        # Rojo конфигурация
├── aftman.toml                 # Инструменты (Rojo 7.4.4)
├── Makefile                    # make build / make serve
├── src/
│   ├── ReplicatedStorage/
│   │   ├── GameConfig.lua      # Константы игры
│   │   └── Modules/
│   │       ├── CharacterStats.lua
│   │       ├── EconomyModule.lua
│   │       ├── ItemData.lua
│   │       ├── ProfessionData.lua
│   │       └── WeatherModule.lua
│   ├── ServerScriptService/
│   │   ├── GameInit.server.lua
│   │   ├── PlayerDataManager.server.lua
│   │   ├── EconomyManager.server.lua
│   │   ├── WeatherManager.server.lua
│   │   ├── ProfessionManager.server.lua
│   │   ├── CriminalSystem.server.lua
│   │   ├── VehicleManager.server.lua
│   │   ├── BuildingManager.server.lua
│   │   ├── NPCManager.server.lua
│   │   └── TaxManager.server.lua
│   ├── StarterPlayer/
│   │   ├── StarterPlayerScripts/
│   │   │   ├── CharacterController.client.lua
│   │   │   ├── VehicleClient.client.lua
│   │   │   └── SoundManager.client.lua
│   │   └── StarterCharacterScripts/
│   │       └── StatsMonitor.client.lua
│   └── StarterGui/
│       ├── HUD/Script.client.lua
│       ├── MainMenu/Script.client.lua
│       ├── ShopGui/Script.client.lua
│       ├── ProfessionGui/Script.client.lua
│       ├── BuildingGui/Script.client.lua
│       └── MarketGui/Script.client.lua
```

---

## ❓ Частые вопросы

**Q: Файл `.rbxlx` не открывается двойным кликом?**
> Убедись, что Roblox Studio установлена. Если не помогает — открой Studio вручную через **File → Open from File**.

**Q: Ошибки "DataStore is not accessible" в Output?**
> Включи API: Studio → **File → Game Settings → Security → Enable Studio Access to API Services**.

**Q: Как обновить игру после изменения скриптов?**
> Либо пересобери `make build` и открой новый `.rbxlx`, либо используй `rojo serve` + плагин Rojo в Studio для живого обновления без пересборки.

**Q: Как использовать `rojo serve` (живое обновление)?**
> 1. Установи плагин Rojo в Studio: https://rojo.space/docs/installation/
> 2. В терминале: `make serve` (или `rojo serve default.project.json`)
> 3. В Studio: кнопка Rojo (в Plugins) → **Connect** — изменения в скриптах обновятся мгновенно.

---

*Проект собирается с помощью [Rojo 7.4.4](https://rojo.space/) и инструмента [Aftman](https://github.com/LPGhatguy/aftman).*

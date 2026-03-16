# 🎮 NEON SLICE — Как запустить игру (пошаговая инструкция)

Эта инструкция поможет вам запустить игру **NEON SLICE** в Roblox Studio с нуля, даже если вы никогда не работали с Rojo.

---

## 📋 Что вам понадобится

1. **Roblox Studio** (бесплатно) — [скачать здесь](https://www.roblox.com/create)
2. **Rojo** (бесплатно) — инструмент для синхронизации файлов с Roblox Studio

---

## 🚀 Способ 1: Самый простой (Rojo CLI + Studio)

### Шаг 1: Установите Roblox Studio

1. Перейдите на [roblox.com/create](https://www.roblox.com/create)
2. Скачайте и установите **Roblox Studio**
3. Войдите в свой аккаунт Roblox

### Шаг 2: Установите Rojo

#### Вариант A: Через Aftman (рекомендуется)

1. Установите [Aftman](https://github.com/LPGhatguy/aftman/releases) — скачайте `.exe` для Windows
2. Откройте командную строку (Win+R → `cmd` → Enter)
3. Выполните команды:
   ```bash
   cd путь/к/папке/memetric-game
   aftman install
   ```
   Это автоматически установит Rojo нужной версии.

#### Вариант B: Скачать Rojo напрямую

1. Перейдите на [github.com/rojo-rbx/rojo/releases](https://github.com/rojo-rbx/rojo/releases)
2. Скачайте последнюю версию для вашей ОС:
   - Windows: `rojo-X.X.X-win64.zip`
   - Mac: `rojo-X.X.X-macos.zip`
3. Распакуйте архив
4. Добавьте папку с `rojo.exe` в переменную PATH, или положите `rojo.exe` прямо в папку проекта

### Шаг 3: Установите плагин Rojo в Roblox Studio

1. Откройте Roblox Studio
2. Перейдите в **Plugins** → **Manage Plugins**
3. Найдите **Rojo** и установите его
4. ИЛИ: в командной строке выполните:
   ```bash
   rojo plugin install
   ```
   Это автоматически установит плагин.

### Шаг 4: Соберите и запустите игру

#### Способ A: Живая синхронизация (для разработки)

1. Откройте командную строку в папке проекта:
   ```bash
   cd путь/к/папке/memetric-game
   ```

2. Запустите сервер Rojo:
   ```bash
   rojo serve
   ```
   Вы увидите сообщение: `Rojo server listening on port 34872`

3. Откройте Roblox Studio → создайте новый **Baseplate** проект

4. В Roblox Studio нажмите на кнопку **Rojo** в панели плагинов

5. Нажмите **Connect** — файлы из проекта синхронизируются в Studio

6. Нажмите **▶ Play** чтобы играть!

#### Способ B: Собрать файл и открыть (самый простой)

1. Откройте командную строку в папке проекта:
   ```bash
   cd путь/к/папке/memetric-game
   ```

2. Соберите файл игры:
   ```bash
   rojo build default.project.json -o NeonSlice.rbxlx
   ```

3. Откройте файл `NeonSlice.rbxlx` двойным кликом — он откроется в Roblox Studio

4. Нажмите **▶ Play** чтобы играть!

---

## 🚀 Способ 2: Использование скриптов (Windows)

В папке `scripts/` есть готовые скрипты:

### Собрать файл игры:
```bash
scripts\build.bat
```
Создаст файл `NeonSlice.rbxlx` — откройте его в Roblox Studio.

### Запустить live-сервер:
```bash
scripts\serve.bat
```
Затем подключитесь через плагин Rojo в Studio.

---

## 🚀 Способ 3: Использование скриптов (Mac/Linux)

### Собрать файл игры:
```bash
chmod +x scripts/build.sh
./scripts/build.sh
```

### Запустить live-сервер:
```bash
chmod +x scripts/serve.sh
./scripts/serve.sh
```

---

## 🚀 Способ 4: Через Makefile

Если у вас установлен `make`:

```bash
make build    # Собрать файл NeonSlice.rbxlx
make serve    # Запустить live-сервер Rojo
make clean    # Удалить собранные файлы
make help     # Показать все доступные команды
```

---

## 🎮 Управление в игре

| Действие            | Клавиша / Ввод         |
| ------------------- | ---------------------- |
| Разрезать блоки     | Клик + перетаскивание  |
| Открыть магазин     | Клавиша **B**          |
| Открыть карту       | Клавиша **M**          |
| Открыть меню рейдов | Клавиша **R**          |
| Завершить забег     | Кнопка **END RUN**     |

---

## ❓ Частые проблемы

### «Rojo не найден» / «rojo is not recognized»
- Убедитесь, что `rojo.exe` находится в PATH или в папке проекта
- Попробуйте перезапустить командную строку после установки

### «Плагин Rojo не подключается»
- Убедитесь, что сервер Rojo запущен (`rojo serve`)
- Проверьте, что плагин Rojo установлен в Studio (Plugins → Manage Plugins)
- Убедитесь, что порт 34872 не заблокирован файрволом

### «Нет звуков в игре»
- Звуковые ассеты используют заглушки (`rbxassetid://0`). Замените их на реальные ID ваших аудио-ассетов в файлах:
  - `src/StarterPlayer/StarterPlayerScripts/MusicController.client.lua`
  - `src/ReplicatedStorage/KatanaData.lua`

### «DataStore не работает»
- DataStore работает только в опубликованных играх на Roblox
- В Studio для тестирования данные хранятся в памяти (это нормально)
- Чтобы включить DataStore в Studio: **Game Settings → Security → Enable Studio Access to API Services**

### «Персонаж не двигается»
- Это нормально! Движение управляется автоматически при начале забега
- Нажмите **▶ START RUN** в главном меню

---

## 🔧 Настройка игры

### Изменить скорость, очки и другие параметры:
Откройте `src/ReplicatedStorage/Config.lua`

### Добавить новые катаны:
Откройте `src/ReplicatedStorage/KatanaData.lua`

### Добавить новые районы:
Откройте `src/ReplicatedStorage/DistrictData.lua`

### Добавить звуки:
1. Загрузите аудиофайлы на Roblox через [Creator Dashboard](https://create.roblox.com/dashboard/creations?activeTab=Audio)
2. Скопируйте ID ассетов
3. Замените `rbxassetid://0` на `rbxassetid://ВАШИ_ID` в соответствующих файлах

---

## 📁 Структура проекта

```
memetric-game/
├── default.project.json          — Конфигурация Rojo (маппинг файлов → Roblox Studio)
├── aftman.toml                   — Автоматическая установка Rojo
├── Makefile                      — Команды сборки (make build, make serve)
├── scripts/                      — Скрипты для Windows/Mac/Linux
│   ├── build.bat / build.sh      — Собрать .rbxlx файл
│   └── serve.bat / serve.sh      — Запустить live-сервер
└── src/
    ├── ReplicatedStorage/        — Общие модули (Config, BlockTypes, KatanaData...)
    ├── ReplicatedFirst/          — Экран загрузки
    ├── ServerScriptService/      — Серверные скрипты (GameManager, TrackSystem...)
    ├── StarterPlayer/
    │   └── StarterPlayerScripts/ — Клиентские скрипты (SliceController, Camera...)
    └── StarterGui/               — Интерфейс (MainMenu, HUD, ShopGui...)
```

/**
 * Main game – orchestrates all subsystems and runs the game loop.
 */

class Game {
    constructor() {
        /* ── City meta ─────────────────────────────────────────────────── */
        this.cityName = 'Мой Город';
        this.day      = 1;
        this.tickAcc  = 0;
        this.paused   = false;
        this.speed    = 1;       // 1 | 2 | 4
        this.lastTime = 0;
        this.running  = false;

        /* ── Subsystems ────────────────────────────────────────────────── */
        this.world           = new World(CONFIG.worldWidth, CONFIG.worldHeight, CONFIG.tileSize);
        this.buildingManager = new BuildingManager();
        this.residentManager = new ResidentManager();
        this.economy         = new Economy();
        this.eventSystem     = new EventSystem();
        this.roadManager     = new RoadManager();

        /* ── Renderer / UI / Input ──────────────────────────────────────── */
        this.canvas   = document.getElementById('gameCanvas');
        this.renderer = new Renderer(this.canvas, this.world);
        this.ui       = new UI(this);
        this.input    = new InputHandler(this.canvas, this.renderer, this);

        /* ── Shared render state ───────────────────────────────────────── */
        this.selectedBuildingId = null;
        this.ghost     = null;
        this.roadPreview = null;

        /* ── Season ─────────────────────────────────────────────────────── */
        this._dayOfYear = 0;

        /* ── Bindings ───────────────────────────────────────────────────── */
        window.addEventListener('resize', () => {
            this.renderer.resize();
            this.renderer.invalidateTerrain();
        });

        this._init();
    }

    /* ── Init ──────────────────────────────────────────────────────────── */

    _init() {
        // Generate world
        this.world.generate();

        // Place the starting Town Hall near the start tile
        const { col, row } = this.world.startTile;
        const px = col * CONFIG.tileSize;
        const py = row * CONFIG.tileSize;
        const th = this.buildingManager.place('townhall', px, py, this.world);
        if (th) th.constructed = true;

        // Spawn initial residents
        for (let i = 0; i < 6; i++) {
            const r = this.residentManager.spawn(i % 2 === 0, [], []);
            // Place near town hall
            r.x = px + rnd(-60, 60);
            r.y = py + rnd(-60, 60);
            r.targetX = r.x; r.targetY = r.y;
        }

        // Centre camera on town hall
        this.renderer.centerOn(px + 40, py + 40);
        this.renderer.zoom = 1.4;

        // Assign initial jobs/housing
        this.residentManager.assignHousing(this.buildingManager);
        this.residentManager.assignJobs(this.buildingManager);

        // Welcome notification
        setTimeout(() => {
            this.ui.notify('Добро пожаловать! Выберите постройку и кликните на карту.', 'success');
        }, 800);

        // Build initial UI
        this.ui.updateHUD();
        this.ui.updateRightPanel();
        this.ui._renderBuildingList();
    }

    /* ── Game loop ──────────────────────────────────────────────────────── */

    start() {
        this.running  = true;
        this.lastTime = performance.now();
        requestAnimationFrame(t => this._loop(t));
    }

    _loop(timestamp) {
        if (!this.running) return;
        const rawDt  = Math.min((timestamp - this.lastTime) / 1000, 0.1);
        this.lastTime = timestamp;
        const dt      = this.paused ? 0 : rawDt * this.speed;

        this._update(dt);
        this._render(timestamp);

        requestAnimationFrame(t => this._loop(t));
    }

    _update(dt) {
        if (dt === 0) return;

        // Resident simulation
        this.residentManager.tick(dt, this.buildingManager, this.economy);

        // Building production
        this.buildingManager.tick(dt, this.economy, this.residentManager);

        // Day counter
        this.tickAcc += dt;
        if (this.tickAcc >= CONFIG.ticksPerDay / 60) {
            this.tickAcc = 0;
            this._onNewDay();
        }

        // Check for pending events (only when no dialog is currently showing)
        const eventDialog = document.getElementById('event-dialog');
        if (!this.paused && eventDialog && eventDialog.style.display !== 'flex') {
            const triggered = this.eventSystem.tick(this.day, this.residentManager.count());
            if (triggered && this.eventSystem.hasPending()) {
                this.ui.showEvent(this.eventSystem.next());
            }
        }

        // Periodic housekeeping
        if (Math.floor(this.tickAcc * 10) % 5 === 0) {
            this.residentManager.assignJobs(this.buildingManager);
            this.residentManager.assignHousing(this.buildingManager);
        }

        // Update UI
        this.ui.update();
    }

    _onNewDay() {
        this.day++;
        this._dayOfYear = (this._dayOfYear + 1) % 360;

        // Season
        const seasons = ['winter','spring','spring','spring','summer','summer',
                         'summer','autumn','autumn','autumn','winter','winter'];
        const newSeason = seasons[Math.floor(this._dayOfYear / 30)];
        if (newSeason !== this.world.season) {
            this.world.setSeason(newSeason);
            this.renderer.invalidateTerrain();
            this.ui.notify(`Наступила ${this._seasonName(newSeason)}!`, 'info');
        }

        // Daily upkeep
        this.economy.dailyUpkeep();
        this.economy.snapshot();

        // Marriage & birth
        this.residentManager.tryMarriage(this.day);
        this.residentManager.tryBirth(this.day, this.buildingManager);

        // Happiness adjustment from economy
        const mod = this.economy.happinessModifier() +
                    this.buildingManager.totalHappinessBonus() * 0.1;
        for (const r of this.residentManager.alive()) {
            r.happiness = clamp(r.happiness + mod * 0.3, 0, 100);
        }

        // Low happiness warning
        const avgH = this.residentManager.averageHappiness();
        if (avgH < CONFIG.minHappinessAlert) {
            this.ui.notify('⚠️ Жители недовольны! Счастье упало ниже 30%.', 'warn');
        }

        // Gold scarcity
        if (this.economy.get('gold') < 0) {
            this.ui.notify('⚠️ Казна пуста! Нужно срочно пополнить бюджет.', 'warn');
        }

        // Refresh UI every 5 days
        if (this.day % 5 === 0) {
            this.ui.updateRightPanel();
            this.ui.refreshBuildingList();
        }
    }

    _seasonName(s) {
        return { spring:'весна', summer:'лето', autumn:'осень', winter:'зима' }[s] || s;
    }

    /* ── Render ─────────────────────────────────────────────────────────── */

    _render(time) {
        const state = {
            buildings: this.buildingManager.getAll(),
            roads:     this.roadManager.getAll(),
            residents: this.residentManager.getAll(),
            selectedBuildingId: this.selectedBuildingId,
            ghost:     this.ghost,
            roadPreview: this.roadPreview,
        };
        this.renderer.render(state, time);
    }

    /* ── Actions ────────────────────────────────────────────────────────── */

    tryPlace(type, x, y) {
        const def = BUILDING_DEFS[type];
        if (!def) return;

        // Check resources
        if (!this.economy.has(def.cost)) {
            this.ui.notify('Недостаточно ресурсов для строительства!', 'warn');
            return;
        }

        const b = this.buildingManager.place(type, x, y, this.world);
        if (!b) {
            this.ui.notify('Нельзя построить здесь!', 'warn');
            return;
        }

        // Deduct cost
        this.economy.spend(def.cost);
        this.ui.notify(`🏗️ ${def.name} начали строить!`, 'success');
        this.ui.refreshBuildingList();
        this.ui.updateHUD();

        // Immediately try to assign workers/housing for the new building
        this.residentManager.assignJobs(this.buildingManager);
        this.residentManager.assignHousing(this.buildingManager);
    }

    demolish(id) {
        const b = this.buildingManager.getById(id);
        if (!b) return;
        // Return partial resources
        const def = b.def;
        if (def.cost.wood)  this.economy.add('wood',  Math.floor((def.cost.wood  || 0) * CONFIG.demolishRefundWood));
        if (def.cost.stone) this.economy.add('stone', Math.floor((def.cost.stone || 0) * CONFIG.demolishRefundStone));
        if (def.cost.gold)  this.economy.add('gold',  Math.floor((def.cost.gold  || 0) * CONFIG.demolishRefundGold));

        // Evict residents
        for (const rid of [...b.residents, ...b.workers]) {
            const r = this.residentManager.getById(rid);
            if (r) {
                r.homeBuildingId = null;
                r.workBuildingId = null;
                r.career = 'idle';
                r.happiness -= 15;
            }
        }
        this.buildingManager.remove(id);
        this.ui.notify(`${def.emoji} ${def.name} снесена.`, 'info');
    }

    addRoad(points) {
        const road = this.roadManager.add(points);
        if (road) {
            const cost = Math.floor(points.length * CONFIG.roadCost);
            this.economy.sub('gold', cost);
            this.ui.notify(`🛤️ Дорога проложена. Стоимость: ${cost} 🪙`, 'info');
        }
    }

    togglePause() {
        this.paused = !this.paused;
    }

    cycleSpeed() {
        const speeds = [1, 2, 4];
        const idx    = speeds.indexOf(this.speed);
        this.speed   = speeds[(idx + 1) % speeds.length];
    }
}

/* ─── Bootstrap ────────────────────────────────────────────────────────────── */

window.addEventListener('DOMContentLoaded', () => {
    window.game = new Game();
    game.start();
});

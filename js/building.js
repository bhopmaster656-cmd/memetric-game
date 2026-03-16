/**
 * Building class and BuildingManager.
 */

class Building {
    constructor(type, x, y) {
        this.id        = nextId();
        this.type      = type;
        this.def       = BUILDING_DEFS[type];
        this.x         = x;
        this.y         = y;
        this.w         = this.def.size.w;
        this.h         = this.def.size.h;
        this.workers   = [];       // resident IDs
        this.residents = [];       // resident IDs (for housing)
        this.level     = 1;
        this.tickAcc   = 0;        // accumulator for production ticks
        this.active    = true;
        this.constructed = false;  // build progress
        this.buildProgress = 0;    // 0–100
        this.buildTime  = this._calcBuildTime();
        this.name      = this.def.name;
        this.happiness  = this.def.happinessBonus || 0;
        this.animOffset = Math.random() * Math.PI * 2;
    }

    _calcBuildTime() {
        const cost = this.def.cost;
        return Math.max(20, (cost.wood || 0) + (cost.stone || 0) * 1.5 + (cost.tools || 0) * 2);
    }

    get cx() { return this.x + this.w / 2; }
    get cy() { return this.y + this.h / 2; }

    /** Advance construction */
    advanceBuild(dt) {
        if (this.constructed) return;
        this.buildProgress += dt * (100 / this.buildTime);
        if (this.buildProgress >= 100) {
            this.buildProgress = 100;
            this.constructed   = true;
        }
    }

    /** Add a worker resident ID */
    addWorker(id) {
        if (!this.def.maxWorkers) return false;
        if (this.workers.length >= this.def.maxWorkers) return false;
        this.workers.push(id);
        return true;
    }

    /** Add a housing resident ID */
    addResident(id) {
        if (!this.def.maxResidents) return false;
        if (this.residents.length >= this.def.maxResidents) return false;
        this.residents.push(id);
        return true;
    }

    removeResident(id) {
        this.residents = this.residents.filter(r => r !== id);
        this.workers   = this.workers.filter(r => r !== id);
    }

    get workerCount()   { return this.workers.length; }
    get maxWorkers()    { return this.def.maxWorkers || 0; }
    get residentCount() { return this.residents.length; }
    get maxResidents()  { return this.def.maxResidents || 0; }

    isFull()      { return this.workers.length >= (this.def.maxWorkers || 0); }
    isHousingFull() { return this.residents.length >= (this.def.maxResidents || 0); }

    /** Bounds check */
    contains(px, py) {
        return px >= this.x && px <= this.x + this.w &&
               py >= this.y && py <= this.y + this.h;
    }

    overlaps(ox, oy, ow, oh, margin) {
        return rectOverlap(this.x, this.y, this.w, this.h, ox, oy, ow, oh, margin || 6);
    }

    serialize() {
        return {
            id: this.id, type: this.type, x: this.x, y: this.y,
            level: this.level, workers: this.workers.slice(),
            residents: this.residents.slice(), constructed: this.constructed,
            buildProgress: this.buildProgress,
        };
    }
}

/* ─────────────────────────────────────────────────────────────────────────── */

class BuildingManager extends EventEmitter {
    constructor() {
        super();
        this.buildings = [];
        this._byId     = {};
    }

    add(building) {
        this.buildings.push(building);
        this._byId[building.id] = building;
        this.emit('added', building);
        return building;
    }

    remove(id) {
        const b = this._byId[id];
        if (!b) return;
        this.buildings = this.buildings.filter(x => x.id !== id);
        delete this._byId[id];
        this.emit('removed', b);
    }

    getById(id)   { return this._byId[id] || null; }
    getAll()      { return this.buildings; }
    getByType(t)  { return this.buildings.filter(b => b.type === t); }

    getAt(px, py) {
        return this.buildings.find(b => b.contains(px, py)) || null;
    }

    /** Can we place [type] at (x,y) without overlapping others? */
    canPlace(type, x, y, excludeId) {
        const def = BUILDING_DEFS[type];
        if (!def) return false;
        const { w, h } = def.size;
        for (const b of this.buildings) {
            if (b.id === excludeId) continue;
            if (b.overlaps(x, y, w, h, 8)) return false;
        }
        return true;
    }

    /** Try to place a building; returns the Building or null */
    place(type, x, y, world) {
        const def = BUILDING_DEFS[type];
        if (!def) return null;
        if (!world.isBuildable(x, y, def.size.w, def.size.h)) return null;
        if (!this.canPlace(type, x, y)) return null;
        // Unique constraint
        if (def.unique && this.getByType(type).length > 0) return null;

        const b = new Building(type, x, y);
        return this.add(b);
    }

    /** Buildings that produce resources each tick */
    tick(dt, economy, residentManager) {
        for (const b of this.buildings) {
            if (!b.constructed) {
                b.advanceBuild(dt);
                continue;
            }
            if (!b.active) continue;

            const def = b.def;

            // Housing: accumulate tax per resident
            if (def.maxResidents && b.residents.length > 0) {
                const tax = def.taxPerResident * b.residents.length * dt * 0.01;
                economy.add('gold', tax);
            }

            // Production buildings need workers
            if (def.produces && b.workers.length > 0) {
                b.tickAcc += dt;
                if (b.tickAcc >= (def.interval || 20)) {
                    b.tickAcc = 0;

                    // Skill multiplier from workers
                    let skillMult = 0;
                    const career    = BUILDING_TO_CAREER[b.type];
                    const skillName = (CAREERS[career] && CAREERS[career].skill) || 'farming';
                    for (const wid of b.workers) {
                        const res = residentManager.getById(wid);
                        if (res) skillMult += res.getSkill(skillName);
                    }
                    skillMult = 1 + skillMult / (b.workers.length || 1);

                    // Consume inputs
                    let canProduce = true;
                    if (def.consumes) {
                        for (const [res, amt] of Object.entries(def.consumes)) {
                            if (economy.get(res) < amt) { canProduce = false; break; }
                        }
                        if (canProduce) {
                            for (const [res, amt] of Object.entries(def.consumes)) {
                                economy.sub(res, amt);
                            }
                        }
                    }

                    if (canProduce) {
                        for (const [res, amt] of Object.entries(def.produces)) {
                            economy.add(res, Math.round(amt * skillMult));
                        }
                    }
                }
            }
        }
    }

    /** Total happiness bonus from all civic buildings */
    totalHappinessBonus() {
        return this.buildings
            .filter(b => b.constructed)
            .reduce((sum, b) => sum + (b.def.happinessBonus || 0), 0);
    }

    serialize() { return this.buildings.map(b => b.serialize()); }
}

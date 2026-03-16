/**
 * Economy manager – resources, taxes, upkeep.
 */

class Economy extends EventEmitter {
    constructor() {
        super();
        this.res = {
            gold: CONFIG.initialGold,
            food: CONFIG.initialResources.food,
            wood: CONFIG.initialResources.wood,
            stone: CONFIG.initialResources.stone,
            tools: CONFIG.initialResources.tools,
            goods: CONFIG.initialResources.goods,
        };
        this.maxStorage = {
            gold: Infinity, food: 500, wood: 500,
            stone: 500, tools: 300, goods: 200,
        };
        this.laws       = {};      // active law ids
        this.taxRate    = 1.0;     // multiplier
        this.tradeLog   = [];      // recent transactions
        this.income     = 0;       // gold earned this day
        this.expenses   = 0;       // gold spent this day
        this.dayStart   = { ...this.res };
    }

    get(name)     { return this.res[name] || 0; }
    add(name, amt) {
        if (amt <= 0) return;
        this.res[name] = Math.min(this.maxStorage[name] || Infinity, (this.res[name] || 0) + amt);
        if (name === 'gold') this.income += amt;
    }
    sub(name, amt) {
        if (amt <= 0) return;
        this.res[name] = Math.max(0, (this.res[name] || 0) - amt);
        if (name === 'gold') this.expenses += amt;
    }
    has(costs) {
        for (const [k, v] of Object.entries(costs))
            if (this.get(k) < v) return false;
        return true;
    }
    spend(costs) {
        if (!this.has(costs)) return false;
        for (const [k, v] of Object.entries(costs)) this.sub(k, v);
        return true;
    }

    snapshot() { this.dayStart = { ...this.res }; this.income = 0; this.expenses = 0; }

    /** Daily upkeep: law costs */
    dailyUpkeep() {
        for (const [lid, active] of Object.entries(this.laws)) {
            if (!active) continue;
            const def = LAW_DEFS[lid];
            if (def?.upkeep) this.sub('gold', def.upkeep.gold || 0);
        }

        // Market tariff daily income
        if (this.laws['market_tariff']) this.add('gold', CONFIG.marketTariffDailyIncome);

        // Emit for UI
        this.emit('upkeep');
    }

    enableLaw(id) {
        if (!LAW_DEFS[id]) return false;
        this.laws[id] = true;
        const def = LAW_DEFS[id];
        if (def.cost) this.spend(def.cost);
        this.emit('law_changed', id, true);
        return true;
    }
    disableLaw(id) {
        this.laws[id] = false;
        this.emit('law_changed', id, false);
    }
    isLawActive(id) { return !!this.laws[id]; }

    /** Get school bonus */
    getSchoolBonus() { return this.isLawActive('education') ? 0.3 : 0; }

    /** Happiness modifier from economy */
    happinessModifier() {
        let mod = 0;
        if (this.get('food') < 20) mod -= 15;
        if (this.get('food') > 200) mod += 5;
        if (this.get('goods') > 50) mod += 8;
        if (this.laws['support_poor']) mod += 10;
        if (this.laws['festival']) mod += 5;
        return mod;
    }

    serialize() { return { res: { ...this.res }, laws: { ...this.laws }, taxRate: this.taxRate }; }
}

/* ─── Road system ─────────────────────────────────────────────────────────── */
class Road {
    constructor(points) {
        this.id     = nextId();
        this.points = points.slice();   // [{x,y}, ...]
    }

    getBounds() {
        let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
        for (const p of this.points) {
            minX = Math.min(minX, p.x); minY = Math.min(minY, p.y);
            maxX = Math.max(maxX, p.x); maxY = Math.max(maxY, p.y);
        }
        return { minX, minY, maxX, maxY };
    }

    serialize() { return { id: this.id, points: this.points.slice() }; }
}

class RoadManager {
    constructor() { this.roads = []; }
    add(points) {
        if (points.length < 2) return null;
        const r = new Road(points);
        this.roads.push(r);
        return r;
    }
    remove(id) { this.roads = this.roads.filter(r => r.id !== id); }
    getAll()   { return this.roads; }
    serialize() { return this.roads.map(r => r.serialize()); }
}

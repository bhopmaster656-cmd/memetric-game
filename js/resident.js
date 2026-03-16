/**
 * Resident (citizen) simulation.
 * Each resident has identity, skills, family relationships, career and happiness.
 */

class Resident {
    constructor(female, parentIds) {
        this.id        = nextId();
        this.female    = female;
        parentIds      = parentIds || [];

        const profile  = generateName(female);
        this.firstName = profile.firstName;
        this.lastName  = profile.lastName;
        this.nickname  = profile.nickname;
        this.dream     = profile.dream;
        this.trait     = profile.trait;
        this.backstory = profile.backstory;

        this.age       = rndInt(16, 45);
        this.birthday  = rndInt(1, 360);

        // Skills: 0–1, seeded by random (parents boost at birth via manager)
        this.skills = {
            farming: rnd(0.05, 0.3), hunting: rnd(0.05, 0.3),
            fishing: rnd(0.05, 0.3), logging: rnd(0.05, 0.3),
            mining:  rnd(0.05, 0.3), smithing: rnd(0.05, 0.3),
            trading: rnd(0.05, 0.3), innkeeping: rnd(0.05, 0.3),
            building: rnd(0.05, 0.3), scholarship: rnd(0.05, 0.3),
            governance: rnd(0.05, 0.3), religion: rnd(0.05, 0.3),
        };

        // Family
        this.parentIds  = parentIds.slice();
        this.spouseId   = null;
        this.childIds   = [];

        // Career
        this.career     = 'idle';
        this.homeBuildingId = null;
        this.workBuildingId = null;

        // Movement (world coords)
        this.x          = 0;
        this.y          = 0;
        this.targetX    = 0;
        this.targetY    = 0;
        this.speed      = rnd(30, 60);
        this.state      = 'idle'; // idle | walking | working | home | eating

        // Stats
        this.happiness  = rnd(60, 90);
        this.hunger     = 0;        // 0–100
        this.wealth     = rndInt(0, 50);
        this.alive      = true;

        // Thoughts for UI
        this.thought    = '';
        this._thoughtTimer = 0;

        // Animation
        this.animTimer  = Math.random() * Math.PI * 2;
        this.color      = this._pickColor();
    }

    _pickColor() {
        const palette = this.female
            ? ['#e899b8','#c878d8','#e8b8d8','#a878c8']
            : ['#4888c8','#2868a8','#68a8e8','#8898c8'];
        return pick(palette);
    }

    getSkill(name) { return clamp(this.skills[name] || 0.1, 0, 2); }

    /** Improve the active skill slightly each tick */
    improveSkill(name, amount) {
        if (this.skills[name] !== undefined)
            this.skills[name] = Math.min(2, this.skills[name] + amount);
    }

    get displayName() { return displayName(this); }

    /** Tick: move, age, update hunger */
    tick(dt, buildingManager, economy) {
        if (!this.alive) return;

        this.animTimer += dt * 2.5;
        this._thoughtTimer -= dt;

        // Age
        this.age += dt * 0.0008;
        if (this.age > 90 && Math.random() < 0.0001 * dt) {
            this.alive = false;
            this._setThought('Прожил долгую жизнь...');
            return;
        }

        // Hunger accumulation
        this.hunger += dt * 0.05;
        if (this.hunger > 100) {
            this.happiness -= dt * 0.5;
            if (Math.random() < 0.0002 * dt) {
                this.alive = false;
                this._setThought('Умер от голода...');
            }
        }

        // Try to eat if hungry
        if (this.hunger > 40 && economy.get('food') > 0) {
            const eaten = Math.min(0.5 * dt, economy.get('food'));
            economy.sub('food', eaten);
            this.hunger = Math.max(0, this.hunger - eaten * 20);
        }

        // Happiness decay toward base
        this.happiness = lerp(this.happiness, 70, dt * 0.001);

        // Movement
        const dx = this.targetX - this.x;
        const dy = this.targetY - this.y;
        const d  = Math.sqrt(dx * dx + dy * dy);
        if (d > 2) {
            this.x += (dx / d) * this.speed * dt;
            this.y += (dy / d) * this.speed * dt;
            this.state = 'walking';
        } else {
            if (this.state === 'walking') this.state = 'idle';
        }

        // Periodic re-targeting
        if (this._thoughtTimer < 0) {
            this._updateTarget(buildingManager);
        }

        // Skill gain from working
        if (this.workBuildingId) {
            const career = this.career;
            const skill  = CAREERS[career]?.skill;
            if (skill) this.improveSkill(skill, dt * 0.0002);
        }
    }

    _updateTarget(bm) {
        this._thoughtTimer = rnd(5, 20);
        const r = Math.random();

        if (this.workBuildingId && r < 0.5) {
            const work = bm.getById(this.workBuildingId);
            if (work && work.constructed) {
                this.targetX = work.cx + rnd(-10, 10);
                this.targetY = work.cy + rnd(-10, 10);
                this.state   = 'walking';
                this._setThought(this._workThought());
                return;
            }
        }
        if (this.homeBuildingId && r < 0.8) {
            const home = bm.getById(this.homeBuildingId);
            if (home) {
                this.targetX = home.cx + rnd(-12, 12);
                this.targetY = home.cy + rnd(-12, 12);
                this.state   = 'walking';
                this._setThought('Иду домой...');
                return;
            }
        }
        // Wander
        this.targetX = this.x + rnd(-120, 120);
        this.targetY = this.y + rnd(-120, 120);
        this._setThought(pick([
            'Красивый денёк!',
            'Нужно закупиться на рынке.',
            'Работа не волк...',
            'Говорят, скоро праздник.',
            'Надо бы навестить соседей.',
            'Чем бы заняться?',
            'Хочу ' + this.dream + '.',
        ]));
    }

    _workThought() {
        const career = CAREERS[this.career];
        if (!career) return 'Иду на работу...';
        return pick([
            `Работаю как ${career.name}.`,
            `${career.emoji} Трудимся!`,
            'Тяжёлый день, но я справлюсь.',
            'Ещё чуть-чуть и будет хорошо.',
        ]);
    }

    _setThought(t) { this.thought = t; this._thoughtTimer = rnd(8, 15); }

    setHome(building) {
        this.homeBuildingId = building.id;
        this.x = building.cx + rnd(-20, 20);
        this.y = building.cy + rnd(-20, 20);
        this.targetX = this.x;
        this.targetY = this.y;
    }

    setWork(building) {
        this.workBuildingId = building.id;
        this.career = BUILDING_TO_CAREER[building.type] || 'idle';
    }

    clearWork() {
        this.workBuildingId = null;
        this.career = 'idle';
    }

    serialize() {
        return {
            id: this.id, female: this.female,
            firstName: this.firstName, lastName: this.lastName, nickname: this.nickname,
            age: Math.floor(this.age), career: this.career, happiness: Math.round(this.happiness),
            hunger: Math.round(this.hunger), skills: this.skills,
            parentIds: this.parentIds, spouseId: this.spouseId, childIds: this.childIds,
            dream: this.dream, trait: this.trait, backstory: this.backstory,
            homeBuildingId: this.homeBuildingId, workBuildingId: this.workBuildingId,
            alive: this.alive, wealth: Math.floor(this.wealth),
        };
    }
}

/* ─────────────────────────────────────────────────────────────────────────── */

class ResidentManager extends EventEmitter {
    constructor() {
        super();
        this.residents = [];
        this._byId     = {};
        this.schoolBonus = 0;
    }

    spawn(female, parentIds, parentResidents) {
        const r = new Resident(female, parentIds);

        // Inherit parent skills (weighted average + bonus)
        if (parentResidents && parentResidents.length > 0) {
            for (const skill of Object.keys(r.skills)) {
                let total = 0;
                for (const p of parentResidents) total += (p.skills[skill] || 0);
                const inherited = (total / parentResidents.length) * 0.6 + rnd(0.05, 0.15);
                r.skills[skill] = Math.min(1.5, inherited + this.schoolBonus * 0.3);
            }
            // Child inherits career affinity
            const parentCareers = parentResidents.map(p => p.career).filter(c => c !== 'idle');
            if (parentCareers.length > 0 && Math.random() < 0.5) {
                const inherCareer = pick(parentCareers);
                const skill = CAREERS[inherCareer]?.skill;
                if (skill) r.skills[skill] = Math.min(2, r.skills[skill] + 0.3);
            }
        }

        this.residents.push(r);
        this._byId[r.id] = r;
        this.emit('spawned', r);
        return r;
    }

    remove(id) {
        const r = this._byId[id];
        if (!r) return;
        this.residents = this.residents.filter(x => x.id !== id);
        delete this._byId[id];
        this.emit('removed', r);
    }

    getById(id)    { return this._byId[id] || null; }
    getAll()       { return this.residents; }
    alive()        { return this.residents.filter(r => r.alive); }
    count()        { return this.residents.filter(r => r.alive).length; }

    averageHappiness() {
        const alive = this.alive();
        if (alive.length === 0) return CONFIG.baseHappiness;
        return alive.reduce((s, r) => s + r.happiness, 0) / alive.length;
    }

    /** Match idle workers to workplaces */
    assignJobs(buildingManager) {
        const idle = this.alive().filter(r => !r.workBuildingId);
        for (const r of idle) {
            for (const b of buildingManager.getAll()) {
                if (!b.constructed || b.isFull()) continue;
                if (!b.def.maxWorkers) continue;
                b.addWorker(r.id);
                r.setWork(b);
                break;
            }
        }
    }

    /** Match homeless residents to housing */
    assignHousing(buildingManager) {
        const homeless = this.alive().filter(r => !r.homeBuildingId);
        for (const r of homeless) {
            for (const b of buildingManager.getAll()) {
                if (!b.constructed || b.isHousingFull()) continue;
                if (!b.def.maxResidents) continue;
                if (b.addResident(r.id)) {
                    r.setHome(b);
                    break;
                }
            }
        }
    }

    /** Attempt to form new families (marriage) */
    tryMarriage(day) {
        if (day % 30 !== 0) return;
        const single = this.alive().filter(r => !r.spouseId && r.age >= 18 && r.age <= 50);
        const males  = shuffle(single.filter(r => !r.female));
        const females = shuffle(single.filter(r => r.female));
        const pairs  = Math.min(males.length, females.length, 2);
        for (let i = 0; i < pairs; i++) {
            males[i].spouseId  = females[i].id;
            females[i].spouseId = males[i].id;
            this.emit('marriage', males[i], females[i]);
        }
    }

    /** Try to produce children */
    tryBirth(day, buildingManager) {
        if (day % 90 !== 0) return;
        const married = this.alive().filter(r => !r.female && r.spouseId);
        for (const father of married) {
            if (Math.random() > 0.35) continue;
            const mother = this.getById(father.spouseId);
            if (!mother || !mother.alive || mother.age > 45) continue;
            // Need free housing
            let home = null;
            for (const b of buildingManager.getAll()) {
                if (b.def.maxResidents && !b.isHousingFull() && b.constructed) { home = b; break; }
            }
            if (!home) continue;

            const child = this.spawn(Math.random() < 0.5, [father.id, mother.id], [father, mother]);
            child.age = 0;
            father.childIds.push(child.id);
            mother.childIds.push(child.id);
            home.addResident(child.id);
            child.setHome(home);
            this.emit('birth', child, father, mother);
        }
    }

    tick(dt, buildingManager, economy) {
        for (const r of this.residents) {
            if (!r.alive) continue;
            r.tick(dt, buildingManager, economy);
        }
        // Clean up dead residents from buildings
        for (const r of this.residents.filter(x => !x.alive)) {
            if (r.homeBuildingId) {
                const b = buildingManager.getById(r.homeBuildingId);
                if (b) b.removeResident(r.id);
            }
            if (r.workBuildingId) {
                const b = buildingManager.getById(r.workBuildingId);
                if (b) b.removeResident(r.id);
            }
        }
        this.residents = this.residents.filter(r => r.alive);
    }

    serialize() { return this.residents.map(r => r.serialize()); }
}

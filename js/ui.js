/**
 * UI controller – panels, tabs, dialogs, notifications.
 */

class UI extends EventEmitter {
    constructor(game) {
        super();
        this.game = game;
        this._activeTab      = 'city';
        this._activeCat      = 'housing';
        this._notifQueue     = [];
        this._eventHistory   = [];

        this._bindHUD();
        this._bindLeftPanel();
        this._bindRightPanel();
        this._bindBottomPanel();
    }

    /* ── HUD ──────────────────────────────────────────────────────────── */

    _bindHUD() {
        document.getElementById('btn-pause').addEventListener('click', () => {
            this.game.togglePause();
            this._updatePauseBtn();
        });
        document.getElementById('btn-speed').addEventListener('click', () => {
            this.game.cycleSpeed();
            this._updateSpeedBtn();
        });
        document.getElementById('city-name').addEventListener('click', () => {
            const name = prompt('Введите имя города:', this.game.cityName);
            if (name) { this.game.cityName = name; this.updateHUD(); }
        });
    }

    _updatePauseBtn() {
        document.getElementById('btn-pause').textContent = this.game.paused ? '▶️' : '⏸️';
    }
    _updateSpeedBtn() {
        document.getElementById('btn-speed').textContent = `${this.game.speed}x`;
    }

    updateHUD() {
        const { economy, residentManager } = this.game;

        const setText = (id, val) => {
            const el = document.getElementById(id);
            if (el) el.querySelector('span').textContent = val;
        };

        setText('res-gold',  formatNumber(Math.floor(economy.get('gold'))));
        setText('res-food',  formatNumber(Math.floor(economy.get('food'))));
        setText('res-wood',  formatNumber(Math.floor(economy.get('wood'))));
        setText('res-stone', formatNumber(Math.floor(economy.get('stone'))));
        setText('res-tools', formatNumber(Math.floor(economy.get('tools'))));
        setText('res-goods', formatNumber(Math.floor(economy.get('goods'))));

        setText('city-pop',       residentManager.count());
        const happiness = Math.round(residentManager.averageHappiness());
        const hEl = document.getElementById('city-happiness');
        if (hEl) {
            const span = hEl.querySelector('span');
            span.textContent = `${happiness}%`;
            span.style.color = happiness > 60 ? '#6ec86e'
                             : happiness > 35 ? '#e8c050'
                             : '#e85050';
        }
        setText('game-date', `День ${this.game.day}`);

        const nameEl = document.getElementById('city-name');
        if (nameEl) nameEl.textContent = `🏰 ${this.game.cityName}`;
    }

    /* ── Left panel – Building menu ────────────────────────────────────── */

    _bindLeftPanel() {
        document.querySelectorAll('.cat-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('.cat-btn').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                this._activeCat = btn.dataset.cat;
                this._renderBuildingList();
            });
        });

        document.getElementById('btn-road').addEventListener('click', () => {
            this.game.input.setMode('road');
            this._highlight('btn-road');
        });
        document.getElementById('btn-demolish').addEventListener('click', () => {
            this.game.input.setMode('demolish');
            this._highlight('btn-demolish');
        });
    }

    _highlight(id) {
        document.querySelectorAll('.building-item, #btn-road, #btn-demolish')
            .forEach(b => b.classList.remove('selected'));
        document.getElementById(id)?.classList.add('selected');
    }

    _renderBuildingList() {
        const list = document.getElementById('building-list');
        list.innerHTML = '';
        const economy = this.game.economy;

        for (const [key, def] of Object.entries(BUILDING_DEFS)) {
            if (def.category !== this._activeCat) continue;
            if (def.unlockDay && this.game.day < def.unlockDay) continue;

            const canAfford = economy.has(def.cost);
            const item = document.createElement('div');
            item.className = 'building-item' + (canAfford ? '' : ' cant-afford');
            item.innerHTML = `
                <span class="b-emoji">${def.emoji}</span>
                <span class="b-name">${def.name}</span>
                <span class="b-cost">${this._costStr(def.cost)}</span>
            `;
            item.title = def.description;
            item.addEventListener('click', () => {
                if (!canAfford) { this.notify('Недостаточно ресурсов!', 'warn'); return; }
                this.game.input.setMode('place', key);
                document.querySelectorAll('.building-item').forEach(b => b.classList.remove('selected'));
                item.classList.add('selected');
            });
            list.appendChild(item);
        }
    }

    _costStr(cost) {
        return Object.entries(cost)
            .map(([k, v]) => `${RESOURCE_ICONS[k]}${v}`)
            .join(' ');
    }

    /* ── Right panel – Tabs ─────────────────────────────────────────────── */

    _bindRightPanel() {
        document.querySelectorAll('.tab-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                this._activeTab = btn.dataset.tab;
                this.updateRightPanel();
            });
        });
    }

    updateRightPanel() {
        const content = document.getElementById('tab-content');
        if (!content) return;
        switch (this._activeTab) {
            case 'city':      content.innerHTML = this._cityTab();      break;
            case 'residents': content.innerHTML = this._residentsTab(); break;
            case 'events':    content.innerHTML = this._eventsTab();    break;
            case 'laws':      content.innerHTML = this._lawsTab();      break;
        }
        this._bindTabListeners();
    }

    _cityTab() {
        const { economy, buildingManager, residentManager, day } = this.game;
        const pop = residentManager.count();
        const h   = Math.round(residentManager.averageHappiness());
        const buildings = buildingManager.getAll();
        const constructed = buildings.filter(b => b.constructed).length;
        const underCons  = buildings.length - constructed;

        const season = this.game.world.season;
        const seasonEmojis = { spring:'🌸', summer:'☀️', autumn:'🍂', winter:'❄️' };

        return `
        <div class="tab-section">
            <h4>📊 Сводка города</h4>
            <div class="stat-row"><span>День</span><span>${day}</span></div>
            <div class="stat-row"><span>Сезон</span><span>${seasonEmojis[season] || ''} ${season}</span></div>
            <div class="stat-row"><span>Население</span><span>${pop}</span></div>
            <div class="stat-row"><span>Счастье</span><span>${h}%</span></div>
            <div class="stat-row"><span>Построек</span><span>${constructed}</span></div>
            <div class="stat-row"><span>В стройке</span><span>${underCons}</span></div>
        </div>
        <div class="tab-section">
            <h4>💰 Экономика</h4>
            <div class="stat-row"><span>Золото</span><span>${Math.floor(economy.get('gold'))}</span></div>
            <div class="stat-row"><span>Доход (день)</span><span>+${Math.floor(economy.income)}</span></div>
            <div class="stat-row"><span>Расходы (день)</span><span>-${Math.floor(economy.expenses)}</span></div>
        </div>
        <div class="tab-section">
            <h4>🏗️ Производство</h4>
            ${RESOURCES.filter(r => r !== 'gold').map(r => `
                <div class="stat-row">
                    <span>${RESOURCE_ICONS[r]} ${RESOURCE_NAMES[r]}</span>
                    <span>${Math.floor(economy.get(r))}</span>
                </div>
            `).join('')}
        </div>`;
    }

    _residentsTab() {
        const residents = this.game.residentManager.alive().slice(0, 30);
        if (residents.length === 0) return `<div class="empty-msg">Нет жителей. Постройте дома!</div>`;

        return `
        <div class="tab-section">
            <h4>👥 Жители (${residents.length})</h4>
            <div class="resident-list">
                ${residents.map(r => `
                <div class="resident-row" data-id="${r.id}">
                    <span class="res-icon">${r.female ? '👩' : '👨'}</span>
                    <span class="res-name">${r.firstName} ${r.lastName}</span>
                    <span class="res-career">${CAREERS[r.career]?.emoji || '😴'}</span>
                    <span class="res-happy ${r.happiness > 60 ? 'happy' : r.happiness > 35 ? 'ok' : 'sad'}">
                        ${Math.round(r.happiness)}%
                    </span>
                </div>`).join('')}
            </div>
        </div>`;
    }

    _eventsTab() {
        const history = this.game.eventSystem.getHistory();
        if (history.length === 0) return `<div class="empty-msg">Событий пока не было.</div>`;

        return `
        <div class="tab-section">
            <h4>📜 История событий</h4>
            ${this._eventHistory.slice(-15).reverse().map(e => `
            <div class="event-hist-item">
                <span class="event-day">День ${e.day}</span>
                <strong>${e.title}</strong>
                <p>${e.outcome}</p>
            </div>`).join('')}
        </div>`;
    }

    _lawsTab() {
        const { economy } = this.game;
        const hasHall = this.game.buildingManager.getByType('townhall').filter(b=>b.constructed).length > 0;

        if (!hasHall) return `<div class="empty-msg">Постройте Ратушу, чтобы вводить законы!</div>`;

        return `
        <div class="tab-section">
            <h4>📜 Законы и указы</h4>
            ${Object.entries(LAW_DEFS).map(([id, def]) => {
                const active   = economy.isLawActive(id);
                const canPass  = !active && economy.has(def.cost || {});
                const reqMet   = !def.requires ||
                    this.game.buildingManager.getByType(def.requires).filter(b=>b.constructed).length > 0;
                return `
                <div class="law-item ${active ? 'active' : ''}">
                    <div class="law-header">
                        <strong>${def.name}</strong>
                        <button class="law-btn" data-law="${id}" ${(!canPass && !active) || !reqMet ? 'disabled' : ''}>
                            ${active ? '❌ Отменить' : '✅ Принять'}
                        </button>
                    </div>
                    <p class="law-desc">${def.description}</p>
                    <p class="law-effect">${def.effect}</p>
                    ${def.cost && Object.keys(def.cost).length > 0 ? `<p class="law-cost">Стоимость: ${this._costStr(def.cost)}</p>` : ''}
                    ${def.upkeep ? `<p class="law-cost">Содержание: ${this._costStr(def.upkeep)}/день</p>` : ''}
                </div>`;
            }).join('')}
        </div>`;
    }

    _bindTabListeners() {
        // Resident rows → profile
        document.querySelectorAll('.resident-row').forEach(row => {
            row.addEventListener('click', () => {
                const id = parseInt(row.dataset.id);
                const r  = this.game.residentManager.getById(id);
                if (r) this.showResidentProfile(r);
            });
        });

        // Law buttons
        document.querySelectorAll('.law-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const id     = btn.dataset.law;
                const active = this.game.economy.isLawActive(id);
                if (active) {
                    this.game.economy.disableLaw(id);
                    this.notify(`Закон "${LAW_DEFS[id].name}" отменён.`, 'info');
                } else {
                    if (this.game.economy.enableLaw(id)) {
                        this.notify(`Принят закон "${LAW_DEFS[id].name}"!`, 'success');
                    }
                }
                this.updateRightPanel();
            });
        });
    }

    /* ── Bottom panel – Selected building ───────────────────────────────── */

    _bindBottomPanel() {
        document.getElementById('btn-close-info')?.addEventListener('click', () => {
            this.hideBottomPanel();
            this.game.selectedBuildingId = null;
        });
    }

    showBuildingInfo(building) {
        const panel = document.getElementById('panel-bottom');
        const info  = document.getElementById('selected-info');
        if (!panel || !info) return;

        const def = building.def;
        const workerNames = building.workers
            .map(id => this.game.residentManager.getById(id))
            .filter(Boolean)
            .map(r => `${r.firstName} ${r.lastName}`)
            .join(', ') || 'Нет рабочих';
        const residentNames = building.residents
            .map(id => this.game.residentManager.getById(id))
            .filter(Boolean)
            .map(r => `${r.firstName} ${r.lastName}`)
            .join(', ') || 'Никого';

        info.innerHTML = `
            <div class="binfo">
                <span class="binfo-emoji">${def.emoji}</span>
                <div class="binfo-details">
                    <strong>${def.name}</strong>
                    <p>${def.description}</p>
                    ${building.constructed
                        ? `<p>Состояние: ✅ Построено</p>`
                        : `<p>Состояние: 🏗️ Стройка ${Math.round(building.buildProgress)}%</p>`}
                    ${def.maxWorkers ? `<p>Рабочие: ${building.workerCount}/${def.maxWorkers} — ${workerNames}</p>` : ''}
                    ${def.maxResidents ? `<p>Жители: ${building.residentCount}/${def.maxResidents} — ${residentNames}</p>` : ''}
                </div>
                <button class="demolish-btn-inline" data-id="${building.id}">💣 Снести</button>
            </div>`;

        panel.style.display = 'flex';

        info.querySelector('.demolish-btn-inline')?.addEventListener('click', () => {
            this.game.demolish(building.id);
            this.hideBottomPanel();
        });
    }

    hideBottomPanel() {
        const panel = document.getElementById('panel-bottom');
        if (panel) panel.style.display = 'none';
    }

    /* ── Resident profile ───────────────────────────────────────────────── */

    showResidentProfile(r) {
        const el = document.getElementById('resident-profile');
        const content = document.getElementById('profile-content');
        if (!el || !content) return;

        const career = CAREERS[r.career] || CAREERS.idle;
        const home   = r.homeBuildingId
            ? this.game.buildingManager.getById(r.homeBuildingId)?.def?.name || 'Нет'
            : 'Бездомный';
        const spouse = r.spouseId
            ? this.game.residentManager.getById(r.spouseId)
            : null;

        // Top 3 skills
        const topSkills = Object.entries(r.skills)
            .sort((a, b) => b[1] - a[1])
            .slice(0, 3)
            .map(([k, v]) => `<span class="skill-tag">${k}: ${(v * 100).toFixed(0)}%</span>`)
            .join('');

        content.innerHTML = `
            <div class="profile-header">
                <span class="profile-avatar">${r.female ? '👩' : '👨'}</span>
                <div>
                    <h2>${r.displayName}</h2>
                    <p class="profile-meta">${r.female ? 'Женщина' : 'Мужчина'}, ${Math.floor(r.age)} лет</p>
                </div>
            </div>
            <div class="profile-section">
                <p><strong>Профессия:</strong> ${career.emoji} ${career.name}</p>
                <p><strong>Дом:</strong> ${home}</p>
                <p><strong>Счастье:</strong> ${Math.round(r.happiness)}%</p>
                <p><strong>Голод:</strong> ${Math.round(r.hunger)}%</p>
                <p><strong>Богатство:</strong> ${Math.floor(r.wealth)} 🪙</p>
            </div>
            <div class="profile-section">
                <p><strong>Черта:</strong> ${r.trait}</p>
                <p><strong>Мечта:</strong> ${r.dream}</p>
                <p><strong>История:</strong> ${r.backstory}</p>
            </div>
            <div class="profile-section">
                <strong>Навыки:</strong><div class="skills-grid">${topSkills}</div>
            </div>
            <div class="profile-section">
                <p><strong>Семья:</strong>
                ${spouse ? `Супруг(а): ${spouse.displayName}` : 'Не женат/замужем'}
                ${r.childIds.length > 0 ? ` · Детей: ${r.childIds.length}` : ''}</p>
            </div>
            ${r.thought ? `<div class="profile-thought">💭 «${r.thought}»</div>` : ''}
        `;

        el.style.display = 'flex';
        document.getElementById('close-profile').onclick = () => { el.style.display = 'none'; };
    }

    /* ── Event dialog ───────────────────────────────────────────────────── */

    showEvent(event) {
        const dialog = document.getElementById('event-dialog');
        if (!dialog) return;

        document.getElementById('event-title').textContent = event.title;
        document.getElementById('event-desc').textContent  = event.desc;
        const choicesEl = document.getElementById('event-choices');
        choicesEl.innerHTML = '';

        event.choices.forEach((choice, i) => {
            const btn = document.createElement('button');
            btn.className   = 'choice-btn';
            btn.textContent = choice.text;
            btn.addEventListener('click', () => {
                const outcome = this.game.eventSystem.applyChoice(
                    event, i,
                    this.game.economy,
                    this.game.residentManager
                );
                this._eventHistory.push({ day: this.game.day, title: event.title, outcome });
                this.hideEvent();
                this.notify(outcome, 'info');
                this.updateRightPanel();
            });
            choicesEl.appendChild(btn);
        });

        dialog.style.display = 'flex';
    }

    hideEvent() {
        document.getElementById('event-dialog').style.display = 'none';
    }

    /* ── Notifications ──────────────────────────────────────────────────── */

    notify(msg, type) {
        const container = document.getElementById('notifications');
        if (!container) return;
        const el = document.createElement('div');
        el.className = `notification notif-${type || 'info'}`;
        el.textContent = msg;
        container.appendChild(el);
        requestAnimationFrame(() => el.classList.add('show'));
        setTimeout(() => {
            el.classList.remove('show');
            setTimeout(() => el.remove(), 400);
        }, 3500);
    }

    /* ── Update cycle ───────────────────────────────────────────────────── */

    update() {
        this.updateHUD();
        if (this._activeTab !== 'city') return;   // only keep city stats live
    }

    refreshBuildingList() { this._renderBuildingList(); }
}

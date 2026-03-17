'use strict';

/**
 * Game — master state machine, game loop, income, drag system, quests, save.
 */
const Game = {
  credits: 0,
  totalBuilds: 0,
  totalMerges: 0,
  questIdx: 0,        // current active quest index in QUESTS
  particles: null,
  _lastIncomeTick: 0,
  _lastSave: 0,
  _animId: null,

  /* ── drag state ── */
  drag: {
    active: false,
    srcIdx: -1,
    building: null,
    x: 0, y: 0,
  },

  /* ── initialise ─────────────────────────────────────────────────────── */
  init(canvas) {
    this.particles = new ParticleSystem();
    Grid.init();
    Renderer.init(canvas, this.particles);

    this._loadSave();
    this._attachInput(canvas);
    this._startLoop();

    UI.update(this);
    UI.renderShop(this);
    UI.updateQuest(this);
  },

  /* ── game loop ──────────────────────────────────────────────────────── */
  _startLoop() {
    const loop = (ts) => {
      this._animId = requestAnimationFrame(loop);
      this._update(ts);
      Renderer.render(Grid, this.drag);
      this.particles.update();
      Renderer.particles.draw(Renderer.ctx);
    };
    this._animId = requestAnimationFrame(loop);
  },

  _update(ts) {
    // Income tick (every 1 s)
    if (ts - this._lastIncomeTick >= CONFIG.INCOME_INTERVAL) {
      this._lastIncomeTick = ts;
      this._doIncomeTick();
    }
    // Auto-save
    if (ts - this._lastSave >= CONFIG.SAVE_INTERVAL) {
      this._lastSave = ts;
      this._save();
    }
    // Quest progress check
    this._checkQuest();
  },

  _doIncomeTick() {
    Grid.cells.forEach((cell, idx) => {
      if (!cell) return;
      this.credits += cell.incomePerSec;
      const pos = Grid.centerOfCell(idx);
      this.particles.addIncome(pos.x, pos.y, cell.incomePerSec, cell.color);
    });
    UI.update(this);
  },

  /* ── buy ────────────────────────────────────────────────────────────── */
  /** Cost of the next building purchase */
  nextCost() {
    return Math.ceil(CONFIG.BASE_COST * Math.pow(CONFIG.COST_GROWTH, this.totalBuilds));
  },

  buy() {
    const cost = this.nextCost();
    if (this.credits < cost) {
      UI.shake('buy-btn');
      return;
    }
    if (Grid.isFull()) {
      UI.toast('Нет свободного места!');
      return;
    }
    this.credits -= cost;
    const idx = Grid.firstEmpty();
    Grid.place(idx, 1);
    this.totalBuilds++;

    const pos = Grid.centerOfCell(idx);
    this.particles.addIncome(pos.x, pos.y, 0, BUILDINGS[0].color);

    this._checkQuest();
    UI.update(this);
    UI.renderShop(this);
    this._save();
  },

  /* ── drag & drop ────────────────────────────────────────────────────── */
  _attachInput(canvas) {
    // Mouse
    canvas.addEventListener('mousedown', e => this._onDown(e, canvas));
    canvas.addEventListener('mousemove', e => this._onMove(e, canvas));
    canvas.addEventListener('mouseup',   e => this._onUp(e, canvas));
    canvas.addEventListener('mouseleave', () => this._cancelDrag());

    // Touch
    canvas.addEventListener('touchstart', e => { e.preventDefault(); this._onDown(e.touches[0], canvas); }, { passive: false });
    canvas.addEventListener('touchmove',  e => { e.preventDefault(); this._onMove(e.touches[0], canvas); }, { passive: false });
    canvas.addEventListener('touchend',   e => { e.preventDefault(); this._onUp(e.changedTouches[0], canvas); }, { passive: false });
  },

  _canvasXY(evt, canvas) {
    const rect = canvas.getBoundingClientRect();
    const scaleX = canvas.width / rect.width;
    const scaleY = canvas.height / rect.height;
    return {
      x: (evt.clientX - rect.left) * scaleX,
      y: (evt.clientY - rect.top)  * scaleY,
    };
  },

  _onDown(evt, canvas) {
    const { x, y } = this._canvasXY(evt, canvas);
    const idx = Grid.indexFromPixel(x, y);
    if (idx === -1 || !Grid.cells[idx]) return;

    this.drag.active = true;
    this.drag.srcIdx  = idx;
    this.drag.building = Grid.cells[idx];
    this.drag.x = x;
    this.drag.y = y;
  },

  _onMove(evt, canvas) {
    if (!this.drag.active) return;
    const { x, y } = this._canvasXY(evt, canvas);
    this.drag.x = x;
    this.drag.y = y;
  },

  _onUp(evt, canvas) {
    if (!this.drag.active) return;
    const { x, y } = this._canvasXY(evt, canvas);
    const dstIdx = Grid.indexFromPixel(x, y);

    if (dstIdx !== -1 && dstIdx !== this.drag.srcIdx) {
      const dst = Grid.cells[dstIdx];

      if (dst === null) {
        // Move to empty cell
        Grid.move(this.drag.srcIdx, dstIdx);
      } else if (Grid.canMerge(this.drag.srcIdx, dstIdx)) {
        // Merge!
        const newBld = Grid.merge(this.drag.srcIdx, dstIdx);
        if (newBld) {
          this.totalMerges++;
          const pos = Grid.centerOfCell(dstIdx);
          this.particles.addMerge(pos.x, pos.y, newBld.color);
          UI.toast(`✨ ${newBld.name} создан!`);
          this._checkQuest();
          UI.update(this);
          this._save();
        }
      }
      // else: different tier — snap back (do nothing)
    }

    this._cancelDrag();
  },

  _cancelDrag() {
    this.drag.active = false;
    this.drag.srcIdx  = -1;
    this.drag.building = null;
  },

  /* ── quests ─────────────────────────────────────────────────────────── */
  _checkQuest() {
    while (this.questIdx < QUESTS.length) {
      const q = QUESTS[this.questIdx];
      let progress = 0;

      switch (q.target) {
        case 'builds':  progress = this.totalBuilds;  break;
        case 'merges':  progress = this.totalMerges;  break;
        case 'tier':    progress = Grid.maxTier();     break;
        case 'credits': progress = this.credits;      break;
      }

      if (progress >= q.value) {
        this.credits += q.reward;
        UI.questComplete(q);
        this.questIdx++;
        UI.update(this);
        UI.updateQuest(this);
      } else {
        break;
      }
    }
    UI.updateQuest(this);
  },

  questProgress() {
    if (this.questIdx >= QUESTS.length) return { pct: 1, current: 0, target: 0 };
    const q = QUESTS[this.questIdx];
    let current = 0;
    switch (q.target) {
      case 'builds':  current = this.totalBuilds;  break;
      case 'merges':  current = this.totalMerges;  break;
      case 'tier':    current = Grid.maxTier();     break;
      case 'credits': current = this.credits;      break;
    }
    return {
      pct: Math.min(1, current / q.value),
      current: Math.min(current, q.value),
      target: q.value,
    };
  },

  /* ── save / load ────────────────────────────────────────────────────── */
  _save() {
    try {
      const data = {
        v: 1,
        credits: this.credits,
        totalBuilds: this.totalBuilds,
        totalMerges: this.totalMerges,
        questIdx: this.questIdx,
        grid: Grid.serialise(),
      };
      localStorage.setItem(CONFIG.SAVE_KEY, JSON.stringify(data));
    } catch (e) { /* ignore */ }
  },

  _loadSave() {
    try {
      const raw = localStorage.getItem(CONFIG.SAVE_KEY);
      if (!raw) {
        this.credits = CONFIG.STARTING_CREDITS;
        return;
      }
      const data = JSON.parse(raw);
      if (data.v !== 1) { this.credits = CONFIG.STARTING_CREDITS; return; }
      this.credits     = data.credits     || CONFIG.STARTING_CREDITS;
      this.totalBuilds = data.totalBuilds || 0;
      this.totalMerges = data.totalMerges || 0;
      this.questIdx    = data.questIdx    || 0;
      Grid.deserialise(data.grid);
    } catch (e) {
      this.credits = CONFIG.STARTING_CREDITS;
    }
  },

  resetSave() {
    localStorage.removeItem(CONFIG.SAVE_KEY);
    this.credits     = CONFIG.STARTING_CREDITS;
    this.totalBuilds = 0;
    this.totalMerges = 0;
    this.questIdx    = 0;
    Grid.init();
    UI.update(this);
    UI.renderShop(this);
    UI.updateQuest(this);
  },
};

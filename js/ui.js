'use strict';

/** UI — all DOM interactions outside the canvas */
const UI = {
  _toastTimeout: null,

  /** Refresh numeric stats in the header */
  update(game) {
    const credits = document.getElementById('credits-val');
    const rate    = document.getElementById('credits-rate');
    const cost    = document.getElementById('cost-val');
    const buyBtn  = document.getElementById('buy-btn');

    if (credits) credits.textContent = Utils.formatNumber(Math.floor(game.credits));
    if (rate)    rate.textContent    = '+' + Utils.formatNumber(Grid.totalIncome()) + '/с';

    const nextCost = game.nextCost();
    if (cost)   cost.textContent = Utils.formatNumber(nextCost);
    if (buyBtn) {
      buyBtn.disabled = game.credits < nextCost || Grid.isFull();
      buyBtn.title = Grid.isFull() ? 'Сетка заполнена!' : '';
    }
  },

  /** Re-render the shop panel (static — only cost changes) */
  renderShop(game) {
    const container = document.getElementById('shop-items');
    if (!container) return;
    container.innerHTML = '';

    // Only Nano-Pod is purchasable; higher tiers come from merging
    const bld = BUILDINGS[0];
    const item = document.createElement('div');
    item.className = 'shop-item';
    item.innerHTML = `
      <canvas class="shop-preview" width="60" height="60" data-tier="1"></canvas>
      <div class="shop-item-info">
        <div class="shop-item-name">${bld.name}</div>
        <div class="shop-item-desc">${bld.desc}</div>
        <div class="shop-item-income">💎 ${Utils.formatNumber(bld.incomePerSec)}/с</div>
      </div>`;
    container.appendChild(item);

    // Draw preview on the mini canvas
    requestAnimationFrame(() => {
      const previewCanvas = container.querySelector('.shop-preview');
      if (!previewCanvas) return;
      const pctx = previewCanvas.getContext('2d');
      pctx.clearRect(0, 0, 60, 60);
      pctx.fillStyle = '#0a0a1f';
      pctx.fillRect(0, 0, 60, 60);
      Renderer.drawPreview(pctx, bld, 30, 30, 55);
    });
  },

  /** Show quest bar */
  updateQuest(game) {
    const bar  = document.getElementById('quest-text');
    const prog = document.getElementById('quest-progress');
    const fill = document.getElementById('quest-fill');

    if (game.questIdx >= QUESTS.length) {
      if (bar)  bar.textContent  = '🏆 Все задания выполнены! Вы победили!';
      if (prog) prog.style.display = 'none';
      return;
    }

    const q = QUESTS[game.questIdx];
    const { pct, current, target } = game.questProgress();

    if (bar)  bar.textContent  = q.text + ` (${Utils.formatNumber(current)}/${Utils.formatNumber(target)}) — награда: +${Utils.formatNumber(q.reward)} 💎`;
    if (fill) fill.style.width = Math.round(pct * 100) + '%';
    if (prog) prog.style.display = '';
  },

  /** Show a brief toast notification */
  toast(msg) {
    let el = document.getElementById('toast');
    if (!el) return;
    el.textContent = msg;
    el.classList.remove('hidden');
    el.classList.add('visible');
    clearTimeout(this._toastTimeout);
    this._toastTimeout = setTimeout(() => {
      el.classList.remove('visible');
      el.classList.add('hidden');
    }, 2000);
  },

  /** Animate shake on an element by id */
  shake(id) {
    const el = document.getElementById(id);
    if (!el) return;
    el.classList.remove('shake');
    void el.offsetWidth; // reflow
    el.classList.add('shake');
    el.addEventListener('animationend', () => el.classList.remove('shake'), { once: true });
  },

  /** Show quest completion banner */
  questComplete(q) {
    this.toast(`✅ Задание выполнено! +${Utils.formatNumber(q.reward)} 💎`);
  },

  /** Building info panel when cell is clicked (currently unused but available) */
  showInfo(bld) {
    const panel = document.getElementById('info-panel');
    if (!panel) return;
    if (!bld) { panel.innerHTML = ''; return; }
    panel.innerHTML = `
      <div class="info-name" style="color:${bld.color}">${bld.name}</div>
      <div class="info-income">💎 ${Utils.formatNumber(bld.incomePerSec)}/с</div>
      <div class="info-desc">${bld.desc}</div>`;
  },
};

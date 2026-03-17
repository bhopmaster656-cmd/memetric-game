'use strict';

window.addEventListener('DOMContentLoaded', () => {
  const canvas = document.getElementById('game-canvas');

  /* ── Responsive canvas sizing ─────────────────────────────────────── */
  function resizeCanvas() {
    const maxW = Math.min(window.innerWidth - 20, 520);
    const cellSize = Math.floor(maxW / CONFIG.GRID_COLS);
    // Update CONFIG dynamically based on screen
    CONFIG.CELL_SIZE = cellSize;
    canvas.width  = cellSize * CONFIG.GRID_COLS;
    canvas.height = cellSize * CONFIG.GRID_ROWS;
  }

  resizeCanvas();
  window.addEventListener('resize', () => {
    resizeCanvas();
    UI.renderShop(Game);
  });

  /* ── Start game ────────────────────────────────────────────────────── */
  Game.init(canvas);

  /* ── Buy button ────────────────────────────────────────────────────── */
  document.getElementById('buy-btn').addEventListener('click', () => {
    Game.buy();
  });

  /* ── Reset button ──────────────────────────────────────────────────── */
  document.getElementById('reset-btn').addEventListener('click', () => {
    if (confirm('Сбросить прогресс и начать заново?')) {
      Game.resetSave();
    }
  });

  /* ── Keyboard shortcut: Space = buy ─────────────────────────────────── */
  document.addEventListener('keydown', e => {
    if (e.code === 'Space' && document.activeElement.tagName !== 'BUTTON') {
      e.preventDefault();
      Game.buy();
    }
  });
});

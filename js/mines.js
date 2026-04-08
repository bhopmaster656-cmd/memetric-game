/* ─────────────────────────────────────────────
   MINES.JS — Mines Game
   ───────────────────────────────────────────── */

const Mines = (() => {
  const GRID_SIZE = 25; // 5×5

  let grid = [];
  let minePositions = new Set();
  let openedCells = 0;
  let betAmount = 0;
  let mineCount = 3;
  let active = false;
  let currentMultiplier = 1.0;

  let startBtn, cashoutBtn, cashoutValEl, betInput, minesCountSelect;
  let openedEl, multEl, currentWinEl, minesCountEl;

  /* ── Multiplier table (safe cells opened → multiplier) ── */
  function calcMultiplier(opened, mines) {
    const safe = GRID_SIZE - mines;
    if (opened === 0) return 1.0;
    // product of probabilities (house edge ~4%)
    let prob = 1.0;
    for (let i = 0; i < opened; i++) {
      prob *= (safe - i) / (GRID_SIZE - i);
    }
    return Math.max(1.0, ((1 / prob) * 0.96));
  }

  /* ── Build grid UI ── */
  function buildGrid() {
    const el = document.getElementById('minesGrid');
    el.innerHTML = '';
    grid = [];
    for (let i = 0; i < GRID_SIZE; i++) {
      const cell = document.createElement('button');
      cell.className = 'mine-cell';
      cell.dataset.index = i;
      cell.textContent = '';
      cell.setAttribute('aria-label', 'Клетка ' + (i + 1));
      cell.addEventListener('click', () => onCellClick(i));
      el.appendChild(cell);
      grid.push(cell);
    }
  }

  /* ── Place mines randomly ── */
  function placeMines(count, firstClick) {
    minePositions = new Set();
    while (minePositions.size < count) {
      const idx = Math.floor(Math.random() * GRID_SIZE);
      if (idx !== firstClick) minePositions.add(idx);
    }
  }

  /* ── Cell click handler ── */
  function onCellClick(idx) {
    if (!active) return;
    const cell = grid[idx];
    if (cell.classList.contains('revealed') || cell.classList.contains('disabled')) return;

    // Place mines on first click to guarantee safe first move
    if (openedCells === 0) {
      placeMines(mineCount, idx);
    }

    cell.classList.add('revealed');

    if (minePositions.has(idx)) {
      // Hit a mine!
      cell.textContent = '💣';
      cell.classList.add('mine-reveal', 'disabled');
      triggerGameOver();
    } else {
      // Safe gem
      cell.textContent = '💎';
      cell.classList.add('gem', 'disabled');
      openedCells++;
      currentMultiplier = calcMultiplier(openedCells, mineCount);
      updateUI();

      // All safe cells opened → auto win
      if (openedCells >= GRID_SIZE - mineCount) {
        triggerAutoWin();
      }
    }
  }

  function triggerGameOver() {
    active = false;
    // Reveal all mines
    minePositions.forEach(idx => {
      const cell = grid[idx];
      if (!cell.classList.contains('revealed')) {
        cell.textContent = '💣';
        cell.classList.add('mine-reveal', 'disabled', 'revealed');
      }
    });
    // Disable rest
    grid.forEach(cell => cell.classList.add('disabled'));

    recordLoss(betAmount);
    showToast(`💥 Мина! Потеряно ${formatNum(betAmount)} ₽`, 'loss');
    addLiveFeedEntry('Мины', betAmount, null, false);
    resetBetPanel();
  }

  function triggerAutoWin() {
    const win = Math.floor(betAmount * currentMultiplier);
    cashOut(win);
  }

  function cashOut(overrideWin) {
    if (!active) return;
    active = false;
    grid.forEach(cell => cell.classList.add('disabled'));
    // Reveal mines peacefully
    minePositions.forEach(idx => {
      const cell = grid[idx];
      if (!cell.classList.contains('revealed')) {
        cell.textContent = '💣';
        cell.classList.add('disabled', 'revealed');
      }
    });

    const win = overrideWin !== undefined ? overrideWin : Math.floor(betAmount * currentMultiplier);
    addBalance(win);
    const profit = win - betAmount;
    recordWin(profit);
    showToast(`✅ Забрано ${formatNum(win)} ₽ (×${currentMultiplier.toFixed(2)})`, 'win');
    addLiveFeedEntry('Мины', win, currentMultiplier.toFixed(2), true);
    resetBetPanel();
  }

  function startGame() {
    const bet = parseInt(betInput.value);
    if (!bet || bet < 1) { showToast('Введите ставку', 'loss'); return; }
    if (bet > getBalance()) { showToast('Недостаточно средств', 'loss'); return; }

    mineCount = parseInt(minesCountSelect.value);
    betAmount = bet;
    openedCells = 0;
    currentMultiplier = 1.0;
    active = true;
    minePositions = new Set();

    subBalance(bet);
    buildGrid();
    minesCountEl.textContent = mineCount;
    updateUI();

    startBtn.classList.add('hidden');
    cashoutBtn.classList.remove('hidden');
    betInput.disabled = true;
    minesCountSelect.disabled = true;
    showToast(`Игра начата! Ставка ${formatNum(bet)} ₽`, 'info');
  }

  function resetBetPanel() {
    startBtn.classList.remove('hidden');
    cashoutBtn.classList.add('hidden');
    betInput.disabled = false;
    minesCountSelect.disabled = false;
    updateUI();
  }

  function updateUI() {
    openedEl.textContent = openedCells;
    multEl.textContent = currentMultiplier.toFixed(2) + '×';
    const win = Math.floor(betAmount * currentMultiplier);
    cashoutValEl.textContent = formatNum(win) + ' ₽';
    currentWinEl.textContent = active ? formatNum(win) + ' ₽' : '0 ₽';
  }

  function init() {
    startBtn        = document.getElementById('minesStartBtn');
    cashoutBtn      = document.getElementById('minesCashoutBtn');
    cashoutValEl    = document.getElementById('minesCashoutVal');
    betInput        = document.getElementById('minesBet');
    minesCountSelect= document.getElementById('minesCountSelect');
    openedEl        = document.getElementById('minesOpened');
    multEl          = document.getElementById('minesMultiplier');
    currentWinEl    = document.getElementById('minesCurrentWin');
    minesCountEl    = document.getElementById('minesCount');

    startBtn.addEventListener('click', startGame);
    cashoutBtn.addEventListener('click', () => cashOut());
    minesCountSelect.addEventListener('change', () => {
      minesCountEl.textContent = minesCountSelect.value;
    });

    buildGrid();
  }

  return { init };
})();

document.addEventListener('DOMContentLoaded', () => Mines.init());

/* ─────────────────────────────────────────────
   APP.JS — State, Balance, Navigation, Utilities
   ───────────────────────────────────────────── */

// ── State ──────────────────────────────────
const state = {
  balance: 1000,
  wins: 0,
  losses: 0,
  profit: 0,
};

// ── Balance helpers ─────────────────────────
function getBalance() { return state.balance; }

function setBalance(val) {
  state.balance = Math.max(0, parseFloat((Math.round(val * 100) / 100).toFixed(2)));
  updateBalanceUI();
}

function addBalance(val) { setBalance(state.balance + val); }
function subBalance(val) { setBalance(state.balance - val); }

function recordWin(profit) {
  state.wins++;
  state.profit += profit;
  updateStatsUI();
}
function recordLoss(loss) {
  state.losses++;
  state.profit -= loss;
  updateStatsUI();
}

function updateBalanceUI() {
  const fmt = formatNum(state.balance);
  document.getElementById('headerBalance').textContent = fmt;
  document.getElementById('sidebarBalance').textContent = fmt;
}

function updateStatsUI() {
  document.getElementById('statWins').textContent = state.wins;
  document.getElementById('statLosses').textContent = state.losses;
  const el = document.getElementById('statProfit');
  el.textContent = formatNum(state.profit) + ' ₽';
  el.className = state.profit >= 0 ? 'profit-positive' : 'profit-negative';
}

function formatNum(n) {
  return Math.abs(n) >= 1000
    ? n.toLocaleString('ru-RU', { maximumFractionDigits: 0 })
    : n.toLocaleString('ru-RU', { maximumFractionDigits: 2 });
}

// ── Navigation ───────────────────────────────
function navigateTo(page) {
  // pages
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  const target = document.getElementById('page-' + page);
  if (target) target.classList.add('active');

  // nav buttons (header)
  document.querySelectorAll('.nav-btn').forEach(b => {
    b.classList.toggle('active', b.dataset.page === page);
  });
  // sidebar buttons
  document.querySelectorAll('.sidebar__item').forEach(b => {
    b.classList.toggle('active', b.dataset.page === page);
  });
}

// ── Quick-bet helpers (global, called from HTML) ─
function halveBet(id) {
  const el = document.getElementById(id);
  el.value = Math.max(1, Math.floor(Number(el.value) / 2));
  el.dispatchEvent(new Event('input'));
}
function doubleBet(id) {
  const el = document.getElementById(id);
  el.value = Math.min(getBalance(), Number(el.value) * 2);
  el.dispatchEvent(new Event('input'));
}
function setQuickBet(id, val) {
  const el = document.getElementById(id);
  el.value = Math.min(getBalance(), val);
  el.dispatchEvent(new Event('input'));
}

// ── Deposit helpers ──────────────────────────
function deposit(amount) {
  addBalance(amount);
  closeModal();
  showToast(`+${formatNum(amount)} ₽ зачислено!`, 'win');
}
function depositCustom() {
  const val = parseInt(document.getElementById('customDeposit').value);
  if (!val || val < 1) { showToast('Введите сумму', 'loss'); return; }
  deposit(val);
}
function openModal() {
  document.getElementById('depositModal').classList.remove('hidden');
}
function closeModal() {
  document.getElementById('depositModal').classList.add('hidden');
}

// ── Toast ─────────────────────────────────────
function showToast(msg, type = 'info', duration = 3000) {
  const c = document.getElementById('toastContainer');
  const t = document.createElement('div');
  t.className = `toast ${type}`;
  t.textContent = msg;
  c.prepend(t);
  setTimeout(() => {
    t.style.opacity = '0';
    t.style.transition = 'opacity .3s';
    setTimeout(() => t.remove(), 300);
  }, duration);
}

// ── Live Feed ─────────────────────────────────
const feedNames = ['Игрок1234', 'Lucky_Star', 'Dragon88', 'BigWin_RU', 'Maximus', 'ProGamer', 'NightWolf', 'CashlordX'];
const feedGames = ['Краш', 'Мины', 'Монетка', 'Колесо'];

function addLiveFeedEntry(game, amount, multiplier, won) {
  const list = document.getElementById('liveFeed');
  if (!list) return;
  const name = feedNames[Math.floor(Math.random() * feedNames.length)];
  const el = document.createElement('div');
  el.className = 'live-item';
  el.innerHTML = `
    <span class="live-item__game">${game}</span>
    <span class="live-item__user">👤 ${name}</span>
    <span class="live-item__amount ${won ? 'win' : 'loss'}">${won ? '+' : '-'}${formatNum(amount)} ₽</span>
    ${multiplier ? `<span class="live-item__mult">${multiplier}×</span>` : ''}
  `;
  list.prepend(el);
  // Keep max 12 items
  while (list.children.length > 12) list.removeChild(list.lastChild);
}

function startFeedSimulation() {
  function addFake() {
    const game = feedGames[Math.floor(Math.random() * feedGames.length)];
    const amount = [50, 100, 200, 500, 1000][Math.floor(Math.random() * 5)];
    const won = Math.random() > 0.45;
    const mult = (1.1 + Math.random() * 10).toFixed(2);
    addLiveFeedEntry(game, amount, won ? mult : null, won);
  }
  for (let i = 0; i < 6; i++) addFake();
  setInterval(addFake, 2800);
}

// ── Lobby crash preview ───────────────────────
function drawLobbyPreview() {
  const c = document.getElementById('lobbyCrashPreview');
  if (!c) return;
  const ctx = c.getContext('2d');
  const w = c.width, h = c.height;
  ctx.clearRect(0, 0, w, h);
  ctx.strokeStyle = '#00e676';
  ctx.lineWidth = 2.5;
  ctx.shadowColor = '#00e676';
  ctx.shadowBlur = 8;
  ctx.beginPath();
  ctx.moveTo(0, h);
  for (let x = 0; x <= w; x++) {
    const t = x / w;
    const y = h - Math.pow(t, 1.6) * h * 0.85;
    ctx.lineTo(x, y);
  }
  ctx.stroke();
  // fill under
  ctx.shadowBlur = 0;
  ctx.lineTo(w, h);
  ctx.closePath();
  ctx.fillStyle = 'rgba(0,230,118,.08)';
  ctx.fill();
}

// ── Init ──────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  // Navigation wiring
  document.querySelectorAll('[data-page]').forEach(el => {
    el.addEventListener('click', () => navigateTo(el.dataset.page));
  });

  // Deposit modal
  document.getElementById('depositBtn').addEventListener('click', openModal);
  document.getElementById('depositBtnSide').addEventListener('click', openModal);
  document.getElementById('modalClose').addEventListener('click', closeModal);
  document.getElementById('depositModal').addEventListener('click', e => {
    if (e.target === e.currentTarget) closeModal();
  });

  // Sidebar toggle
  document.getElementById('sidebarToggle').addEventListener('click', () => {
    document.getElementById('sidebar').classList.toggle('open');
  });

  // Initial UI sync
  updateBalanceUI();
  updateStatsUI();
  drawLobbyPreview();
  startFeedSimulation();

  // Game card clicks
  document.querySelectorAll('.game-card').forEach(card => {
    card.querySelector('.btn--play')?.addEventListener('click', e => {
      e.stopPropagation();
      navigateTo(card.dataset.page);
    });
    card.addEventListener('click', () => navigateTo(card.dataset.page));
  });
});

/* ─────────────────────────────────────────────
   CRASH.JS — Crash Game Engine
   ───────────────────────────────────────────── */

const Crash = (() => {
  /* ── DOM refs ── */
  let canvas, ctx, multiplierEl, statusEl, betBtn, cashoutBtn, cashoutValEl;
  let betInput, autoOutInput, potentialEl;

  /* ── State ── */
  let phase = 'waiting';   // waiting | betting | flying | crashed
  let currentMult = 1.0;
  let crashPoint = 1.0;
  let playerBet = 0;
  let hasBet = false;
  let hasCashedOut = false;
  let animId = null;
  let startTime = null;
  const history = [];
  const points = [];           // {x,y} canvas coords for graph

  const WAIT_MS    = 5000;
  const CANVAS_W   = 700;
  const CANVAS_H   = 360;
  const PAD_L      = 48;
  const PAD_B      = 36;
  const GRAPH_W    = CANVAS_W - PAD_L - 12;
  const GRAPH_H    = CANVAS_H - PAD_B - 12;

  /* ── Generate crash point (house edge ~3%) ── */
  function genCrashPoint() {
    const r = Math.random();
    if (r < 0.01) return 1.0;
    return Math.max(1.0, parseFloat((99 / (1 - r * 0.97)).toFixed(2)));
  }

  /* ── Time → multiplier mapping (exponential) ── */
  function timeToMult(ms) {
    return Math.pow(Math.E, ms / 12000);
  }

  /* ── Canvas drawing ── */
  function drawFrame() {
    ctx.clearRect(0, 0, CANVAS_W, CANVAS_H);

    // background grid
    ctx.strokeStyle = 'rgba(255,255,255,.04)';
    ctx.lineWidth = 1;
    for (let x = PAD_L; x <= CANVAS_W; x += 60) {
      ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, CANVAS_H - PAD_B); ctx.stroke();
    }
    for (let y = CANVAS_H - PAD_B; y >= 0; y -= 50) {
      ctx.beginPath(); ctx.moveTo(PAD_L, y); ctx.lineTo(CANVAS_W, y); ctx.stroke();
    }

    // axes
    ctx.strokeStyle = 'rgba(255,255,255,.15)';
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.moveTo(PAD_L, 0); ctx.lineTo(PAD_L, CANVAS_H - PAD_B);
    ctx.lineTo(CANVAS_W, CANVAS_H - PAD_B);
    ctx.stroke();

    if (points.length < 2) return;

    // curve
    const isCrashed = phase === 'crashed';
    const lineColor = isCrashed ? '#ff4560' : '#00e676';
    const glowColor = isCrashed ? 'rgba(255,69,96,.5)' : 'rgba(0,230,118,.5)';

    ctx.save();
    ctx.shadowColor = lineColor;
    ctx.shadowBlur = 14;
    ctx.strokeStyle = lineColor;
    ctx.lineWidth = 3;
    ctx.lineJoin = 'round';
    ctx.beginPath();
    ctx.moveTo(points[0].x, points[0].y);
    for (let i = 1; i < points.length; i++) ctx.lineTo(points[i].x, points[i].y);
    ctx.stroke();
    ctx.restore();

    // gradient fill under curve
    const last = points[points.length - 1];
    ctx.save();
    const grad = ctx.createLinearGradient(0, 0, 0, CANVAS_H);
    grad.addColorStop(0, isCrashed ? 'rgba(255,69,96,.18)' : 'rgba(0,230,118,.18)');
    grad.addColorStop(1, 'rgba(0,0,0,0)');
    ctx.fillStyle = grad;
    ctx.beginPath();
    ctx.moveTo(points[0].x, points[0].y);
    for (let i = 1; i < points.length; i++) ctx.lineTo(points[i].x, points[i].y);
    ctx.lineTo(last.x, CANVAS_H - PAD_B);
    ctx.lineTo(PAD_L, CANVAS_H - PAD_B);
    ctx.closePath();
    ctx.fill();
    ctx.restore();

    // dot at tip
    ctx.save();
    ctx.shadowColor = lineColor;
    ctx.shadowBlur = 20;
    ctx.fillStyle = lineColor;
    ctx.beginPath();
    ctx.arc(last.x, last.y, 5, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  }

  /* ── Map multiplier to canvas Y ── */
  function multToY(m) {
    const logMax = Math.log(Math.max(currentMult, 2) + 0.5);
    const logM   = Math.log(Math.max(m, 1));
    return (CANVAS_H - PAD_B) - (logM / logMax) * GRAPH_H * 0.9;
  }

  /* ── Map elapsed ms to canvas X ── */
  function timeToX(elapsed, maxElapsed) {
    const ratio = Math.min(elapsed / Math.max(maxElapsed, 1), 1);
    return PAD_L + ratio * GRAPH_W * 0.95;
  }

  /* ── Fly animation loop ── */
  function flyLoop(ts) {
    if (!startTime) startTime = ts;
    const elapsed = ts - startTime;
    currentMult = timeToMult(elapsed);

    // Auto cashout
    const autoVal = parseFloat(autoOutInput.value);
    if (hasBet && !hasCashedOut && autoVal >= 1.01 && currentMult >= autoVal) {
      cashOut();
    }

    if (currentMult >= crashPoint) {
      doCrash();
      return;
    }

    // Build point for graph
    const x = timeToX(elapsed, crashPoint > 2 ? (crashPoint * 3500) : 8000);
    const y = multToY(currentMult);
    points.push({ x, y });
    if (points.length > 600) points.shift();

    multiplierEl.textContent = currentMult.toFixed(2) + '×';
    updatePotential();
    drawFrame();

    animId = requestAnimationFrame(flyLoop);
  }

  function doCrash() {
    phase = 'crashed';
    multiplierEl.textContent = crashPoint.toFixed(2) + '×';
    multiplierEl.classList.add('crashed');
    statusEl.textContent = `💥 Краш на ${crashPoint.toFixed(2)}×`;

    drawFrame();

    if (hasBet && !hasCashedOut) {
      recordLoss(playerBet);
      showToast(`💥 Краш! Потеряно ${formatNum(playerBet)} ₽`, 'loss');
      addLiveFeedEntry('Краш', playerBet, null, false);
    }
    betBtn.classList.remove('hidden');
    cashoutBtn.classList.add('hidden');
    betBtn.disabled = false;
    betBtn.textContent = 'Поставить';

    addHistory(crashPoint);

    setTimeout(() => startWait(), 4000);
  }

  function cashOut() {
    if (!hasBet || hasCashedOut) return;
    hasCashedOut = true;
    const win = Math.floor(playerBet * currentMult);
    addBalance(win);
    const profit = win - playerBet;
    recordWin(profit);
    showToast(`✅ Выведено ${formatNum(win)} ₽ (×${currentMult.toFixed(2)})`, 'win');
    addLiveFeedEntry('Краш', win, currentMult.toFixed(2), true);
    cashoutBtn.classList.add('hidden');
    betBtn.classList.remove('hidden');
    betBtn.disabled = true;
    betBtn.textContent = '⌛ Ждём краша…';
  }

  function placeBet() {
    if (phase !== 'betting') return;
    const bet = parseInt(betInput.value);
    if (!bet || bet < 1) { showToast('Введите ставку', 'loss'); return; }
    if (bet > getBalance()) { showToast('Недостаточно средств', 'loss'); return; }
    subBalance(bet);
    playerBet = bet;
    hasBet = true;
    hasCashedOut = false;
    betBtn.classList.add('hidden');
    cashoutBtn.classList.remove('hidden');
    showToast(`Ставка ${formatNum(bet)} ₽ принята`, 'info');
  }

  function updatePotential() {
    const bet = parseInt(betInput.value) || 0;
    const m   = hasBet ? currentMult : (parseFloat(autoOutInput.value) || 2.0);
    potentialEl.textContent = formatNum(Math.floor(bet * m)) + ' ₽';
    if (hasBet) {
      cashoutValEl.textContent = formatNum(Math.floor(playerBet * currentMult)) + ' ₽';
    }
  }

  function addHistory(mult) {
    history.unshift(mult);
    if (history.length > 10) history.pop();
    const el = document.getElementById('crashHistory');
    el.innerHTML = '';
    history.forEach(m => {
      const chip = document.createElement('span');
      chip.className = `crash-chip ${m < 1.5 ? 'low' : m < 5 ? 'mid' : 'high'}`;
      chip.textContent = m.toFixed(2) + '×';
      el.appendChild(chip);
    });
  }

  /* ── Phase: waiting ── */
  function startWait() {
    phase = 'waiting';
    hasBet = false;
    hasCashedOut = false;
    playerBet = 0;
    points.length = 0;
    currentMult = 1.0;
    crashPoint = genCrashPoint();
    multiplierEl.classList.remove('crashed');
    multiplierEl.textContent = '1.00×';
    statusEl.textContent = 'Ожидание ставок…';
    betBtn.classList.remove('hidden');
    betBtn.disabled = false;
    betBtn.textContent = 'Поставить';
    cashoutBtn.classList.add('hidden');
    drawFrame();

    const remaining = document.createElement('span');
    let sec = Math.ceil(WAIT_MS / 1000);
    statusEl.textContent = `Ставки принимаются (${sec}с)`;
    const interval = setInterval(() => {
      sec--;
      statusEl.textContent = sec > 0 ? `Ставки принимаются (${sec}с)` : 'Запуск…';
      if (sec <= 0) clearInterval(interval);
    }, 1000);

    setTimeout(() => {
      phase = 'betting';  // allow bets until we explicitly start flying
      setTimeout(startFly, 100);
    }, WAIT_MS);
  }

  /* ── Phase: flying ── */
  function startFly() {
    phase = 'flying';
    startTime = null;
    statusEl.textContent = 'Летим!';
    animId = requestAnimationFrame(flyLoop);
  }

  /* ── Boot ── */
  function init() {
    canvas       = document.getElementById('crashCanvas');
    ctx          = canvas.getContext('2d');
    multiplierEl = document.getElementById('crashMultiplier');
    statusEl     = document.getElementById('crashStatus');
    betBtn       = document.getElementById('crashBetBtn');
    cashoutBtn   = document.getElementById('crashCashoutBtn');
    cashoutValEl = document.getElementById('crashCashoutVal');
    betInput     = document.getElementById('crashBet');
    autoOutInput = document.getElementById('crashAutoOut');
    potentialEl  = document.getElementById('crashPotential');

    betBtn.addEventListener('click', placeBet);
    cashoutBtn.addEventListener('click', cashOut);
    betInput.addEventListener('input', updatePotential);
    autoOutInput.addEventListener('input', updatePotential);

    startWait();
  }

  return { init };
})();

document.addEventListener('DOMContentLoaded', () => Crash.init());

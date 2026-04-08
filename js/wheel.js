/* ─────────────────────────────────────────────
   WHEEL.JS — Wheel of Fortune
   ───────────────────────────────────────────── */

const Wheel = (() => {
  const SEGMENTS = [
    { label: '0×',    multiplier: 0,    color: '#ff4560', prob: 0.30 },
    { label: '0.5×',  multiplier: 0.5,  color: '#ff6b35', prob: 0.20 },
    { label: '1.5×',  multiplier: 1.5,  color: '#ffd700', prob: 0.20 },
    { label: '2×',    multiplier: 2,    color: '#00e676', prob: 0.15 },
    { label: '3×',    multiplier: 3,    color: '#00d4ff', prob: 0.08 },
    { label: '5×',    multiplier: 5,    color: '#a78bfa', prob: 0.05 },
    { label: '10×',   multiplier: 10,   color: '#f59e0b', prob: 0.015 },
    { label: '50×',   multiplier: 50,   color: '#ec4899', prob: 0.005 },
  ];

  let canvas, ctx, betInput, spinBtn, resultEl, maxWinEl;
  let spinning = false;
  let currentAngle = 0;

  /* ── Pick weighted random segment ── */
  function pickSegment() {
    const r = Math.random();
    let cum = 0;
    for (const seg of SEGMENTS) {
      cum += seg.prob;
      if (r <= cum) return seg;
    }
    return SEGMENTS[0];
  }

  /* ── Draw wheel ── */
  function drawWheel(angle) {
    const W = canvas.width;
    const H = canvas.height;
    const cx = W / 2, cy = H / 2;
    const radius = Math.min(cx, cy) - 10;

    ctx.clearRect(0, 0, W, H);

    const total = SEGMENTS.length;
    const sliceAngle = (2 * Math.PI) / total;

    // Build cumulative angle shares (equal visual, weighted only for outcome)
    SEGMENTS.forEach((seg, i) => {
      const start = angle + i * sliceAngle;
      const end   = start + sliceAngle;

      // Slice
      ctx.save();
      ctx.beginPath();
      ctx.moveTo(cx, cy);
      ctx.arc(cx, cy, radius, start, end);
      ctx.closePath();
      ctx.fillStyle = seg.color;
      ctx.fill();
      ctx.strokeStyle = 'rgba(0,0,0,.4)';
      ctx.lineWidth = 2;
      ctx.stroke();
      ctx.restore();

      // Label
      const midAngle = start + sliceAngle / 2;
      const labelR = radius * 0.68;
      const lx = cx + Math.cos(midAngle) * labelR;
      const ly = cy + Math.sin(midAngle) * labelR;

      ctx.save();
      ctx.translate(lx, ly);
      ctx.rotate(midAngle + Math.PI / 2);
      ctx.fillStyle = '#fff';
      ctx.font = 'bold 15px Inter, sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.shadowColor = 'rgba(0,0,0,.7)';
      ctx.shadowBlur = 4;
      ctx.fillText(seg.label, 0, 0);
      ctx.restore();
    });

    // Center circle
    ctx.save();
    ctx.beginPath();
    ctx.arc(cx, cy, 28, 0, Math.PI * 2);
    ctx.fillStyle = '#0b0c1a';
    ctx.fill();
    ctx.strokeStyle = '#2a2d50';
    ctx.lineWidth = 3;
    ctx.stroke();
    ctx.restore();

    ctx.save();
    ctx.fillStyle = '#e8eaf6';
    ctx.font = 'bold 14px Inter, sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('🐉', cx, cy);
    ctx.restore();
  }

  /* ── Spin animation ── */
  function spin() {
    if (spinning) return;
    const bet = parseInt(betInput.value);
    if (!bet || bet < 1) { showToast('Введите ставку', 'loss'); return; }
    if (bet > getBalance()) { showToast('Недостаточно средств', 'loss'); return; }

    subBalance(bet);
    spinning = true;
    spinBtn.disabled = true;
    resultEl.textContent = '';
    resultEl.className = 'wheel-result';

    const winner = pickSegment();
    const total  = SEGMENTS.length;
    const sliceAngle = (2 * Math.PI) / total;

    // Find winner segment index
    const winIdx = SEGMENTS.indexOf(winner);
    // Target angle: winner segment centred under pointer (top = -π/2)
    const targetSliceStart = winIdx * sliceAngle;
    const targetMid = targetSliceStart + sliceAngle / 2;
    // Pointer is at top (−π/2). We want targetMid to align with −π/2.
    // finalAngle + targetMid = -π/2  ⟹  finalAngle = -π/2 - targetMid
    const extraSpins  = (8 + Math.floor(Math.random() * 4)) * 2 * Math.PI;
    const finalAngle  = -Math.PI / 2 - targetMid + extraSpins;

    const startAngle  = currentAngle;
    const angleDiff   = finalAngle - startAngle;
    const duration    = 4000 + Math.random() * 1000;
    let   startTime   = null;

    function easeOut(t) { return 1 - Math.pow(1 - t, 4); }

    function frame(ts) {
      if (!startTime) startTime = ts;
      const elapsed = ts - startTime;
      const t = Math.min(elapsed / duration, 1);
      const easedT = easeOut(t);
      currentAngle = startAngle + angleDiff * easedT;
      drawWheel(currentAngle);

      if (t < 1) {
        requestAnimationFrame(frame);
      } else {
        currentAngle = finalAngle % (2 * Math.PI);
        drawWheel(currentAngle);
        spinning = false;
        spinBtn.disabled = false;
        showResult(winner, bet);
      }
    }

    requestAnimationFrame(frame);
  }

  function showResult(seg, bet) {
    const win = Math.floor(bet * seg.multiplier);
    if (seg.multiplier > 1) {
      addBalance(win);
      const profit = win - bet;
      recordWin(profit);
      resultEl.textContent = `🎉 ${seg.label} — +${formatNum(win)} ₽`;
      resultEl.className = 'wheel-result win';
      showToast(`🎡 ${seg.label}! Выигрыш ${formatNum(win)} ₽`, 'win');
      addLiveFeedEntry('Колесо', win, seg.label, true);
    } else if (seg.multiplier === 0.5) {
      const refund = Math.floor(bet * 0.5);
      addBalance(refund);
      recordLoss(bet - refund);
      resultEl.textContent = `🙁 ${seg.label} — Возврат ${formatNum(refund)} ₽`;
      resultEl.className = 'wheel-result loss';
      showToast(`🎡 ${seg.label} — Частичный возврат ${formatNum(refund)} ₽`, 'info');
      addLiveFeedEntry('Колесо', bet - refund, null, false);
    } else {
      recordLoss(bet);
      resultEl.textContent = `💀 ${seg.label} — Потеряно ${formatNum(bet)} ₽`;
      resultEl.className = 'wheel-result loss';
      showToast(`🎡 ${seg.label}! Потеряно ${formatNum(bet)} ₽`, 'loss');
      addLiveFeedEntry('Колесо', bet, null, false);
    }
  }

  /* ── Render segment info list ── */
  function renderSegmentList() {
    const el = document.getElementById('segmentList');
    el.innerHTML = '';
    SEGMENTS.forEach(seg => {
      const row = document.createElement('div');
      row.className = 'seg-row';
      row.innerHTML = `
        <span style="display:flex;align-items:center;gap:6px">
          <span class="seg-dot" style="background:${seg.color}"></span>
          ${seg.label}
        </span>
        <span style="color:var(--text-muted);font-size:11px">${Math.round(seg.prob * 100)}%</span>
      `;
      el.appendChild(row);
    });
  }

  function updateMaxWin() {
    const bet = parseInt(betInput?.value) || 0;
    const max = SEGMENTS.reduce((a, s) => Math.max(a, s.multiplier), 0);
    if (maxWinEl) maxWinEl.textContent = formatNum(bet * max) + ' ₽';
  }

  function init() {
    canvas    = document.getElementById('wheelCanvas');
    ctx       = canvas.getContext('2d');
    betInput  = document.getElementById('wheelBet');
    spinBtn   = document.getElementById('wheelSpinBtn');
    resultEl  = document.getElementById('wheelResult');
    maxWinEl  = document.getElementById('wheelMaxWin');

    spinBtn.addEventListener('click', spin);
    betInput.addEventListener('input', updateMaxWin);

    renderSegmentList();
    drawWheel(0);
    updateMaxWin();
  }

  return { init };
})();

document.addEventListener('DOMContentLoaded', () => Wheel.init());

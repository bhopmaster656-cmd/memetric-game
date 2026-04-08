/* ─────────────────────────────────────────────
   COINFLIP.JS — Coin Flip Game
   ───────────────────────────────────────────── */

const CoinFlip = (() => {
  let flipping = false;
  let chosenSide = 'heads';
  let streak = 0;
  let betInput, flipBtn, resultEl, streakEl, potentialEl;

  function setSide(side) {
    chosenSide = side;
    document.getElementById('sideHeads').classList.toggle('active', side === 'heads');
    document.getElementById('sideTails').classList.toggle('active', side === 'tails');
    updatePotential();
  }

  function updatePotential() {
    const bet = parseInt(betInput?.value) || 0;
    if (potentialEl) potentialEl.textContent = formatNum(bet * 2) + ' ₽';
  }

  function flip() {
    if (flipping) return;
    const bet = parseInt(betInput.value);
    if (!bet || bet < 1) { showToast('Введите ставку', 'loss'); return; }
    if (bet > getBalance()) { showToast('Недостаточно средств', 'loss'); return; }

    subBalance(bet);
    flipping = true;
    flipBtn.disabled = true;
    resultEl.textContent = '';
    resultEl.className = 'coinflip-result';

    const coinEl = document.getElementById('coinEl');
    coinEl.classList.remove('spinning');
    void coinEl.offsetWidth; // reflow to restart animation
    coinEl.classList.add('spinning');

    const won = Math.random() < 0.5;
    const result = won ? chosenSide : (chosenSide === 'heads' ? 'tails' : 'heads');

    setTimeout(() => {
      coinEl.classList.remove('spinning');
      // Set final face
      if (result === 'heads') {
        coinEl.style.transform = 'rotateY(0deg)';
      } else {
        coinEl.style.transform = 'rotateY(180deg)';
      }

      if (won) {
        const win = bet * 2;
        addBalance(win);
        streak++;
        recordWin(bet);
        resultEl.textContent = `👑 Победа! +${formatNum(win)} ₽`;
        resultEl.className = 'coinflip-result win';
        showToast(`🎉 Победа! +${formatNum(win)} ₽`, 'win');
        addLiveFeedEntry('Монетка', win, '2.00', true);
      } else {
        streak = 0;
        recordLoss(bet);
        resultEl.textContent = `💀 Поражение! -${formatNum(bet)} ₽`;
        resultEl.className = 'coinflip-result loss';
        showToast(`😢 Поражение! -${formatNum(bet)} ₽`, 'loss');
        addLiveFeedEntry('Монетка', bet, null, false);
      }

      streakEl.textContent = streak;
      flipping = false;
      flipBtn.disabled = false;
    }, 1250);
  }

  function init() {
    betInput    = document.getElementById('coinBet');
    flipBtn     = document.getElementById('coinFlipBtn');
    resultEl    = document.getElementById('coinflipResult');
    streakEl    = document.getElementById('coinStreak');
    potentialEl = document.getElementById('coinPotential');

    flipBtn.addEventListener('click', flip);
    betInput.addEventListener('input', updatePotential);

    document.getElementById('sideHeads').addEventListener('click', () => setSide('heads'));
    document.getElementById('sideTails').addEventListener('click', () => setSide('tails'));

    updatePotential();
  }

  return { init };
})();

document.addEventListener('DOMContentLoaded', () => CoinFlip.init());

/* Slot Machine Game */
(function() {
    const SYMBOLS = ['🍒', '🍋', '🍊', '🍇', '🔔', '💎', '7️⃣', '⭐'];
    const PAYOUTS = {
        '7️⃣': 10,
        '💎': 7,
        '⭐': 5,
        '🔔': 4,
        '🍇': 3,
        '🍊': 2,
        '🍋': 1.5,
        '🍒': 1
    };

    let spinning = false;

    function getRandomSymbol() {
        // Weighted: common fruits more likely
        const weights = [20, 20, 18, 15, 10, 8, 5, 4];
        const total = weights.reduce((a, b) => a + b, 0);
        let r = Math.random() * total;
        for (let i = 0; i < weights.length; i++) {
            r -= weights[i];
            if (r <= 0) return SYMBOLS[i];
        }
        return SYMBOLS[0];
    }

    function spin() {
        if (spinning) return;

        const betInput = document.getElementById('slot-bet');
        const bet = parseInt(betInput.value, 10);
        const resultEl = document.getElementById('slot-result');

        if (isNaN(bet) || bet < 10) {
            resultEl.textContent = 'Минимальная ставка: 10';
            resultEl.className = 'slot-result lose';
            return;
        }
        if (!Balance.canAfford(bet)) {
            resultEl.textContent = 'Недостаточно средств!';
            resultEl.className = 'slot-result lose';
            return;
        }

        Balance.subtract(bet);
        spinning = true;
        resultEl.textContent = '';
        resultEl.className = 'slot-result';

        const reels = [
            document.getElementById('reel-0'),
            document.getElementById('reel-1'),
            document.getElementById('reel-2')
        ];
        const results = [getRandomSymbol(), getRandomSymbol(), getRandomSymbol()];

        // Start spinning animation
        reels.forEach(r => r.classList.add('spinning'));

        // Reveal reels one by one
        const delays = [600, 1000, 1400];
        reels.forEach((reel, i) => {
            // Cycle through random symbols during spin
            const interval = setInterval(() => {
                reel.querySelector('.reel-inner').textContent = SYMBOLS[Math.floor(Math.random() * SYMBOLS.length)];
            }, 80);

            setTimeout(() => {
                clearInterval(interval);
                reel.classList.remove('spinning');
                reel.querySelector('.reel-inner').textContent = results[i];
            }, delays[i]);
        });

        // Check result
        setTimeout(() => {
            spinning = false;
            const [a, b, c] = results;

            if (a === b && b === c) {
                // Three of a kind
                const payout = PAYOUTS[a] || 1;
                const winAmount = Math.round(bet * payout);
                Balance.add(winAmount);
                resultEl.textContent = `🎉 ДЖЕКПОТ! ${a}${a}${a} — Выигрыш: ${Balance.formatNumber(winAmount)} 💎`;
                resultEl.className = 'slot-result win win-pulse';
            } else if (a === b || b === c || a === c) {
                // Two of a kind
                const match = a === b ? a : (b === c ? b : a);
                const payout = (PAYOUTS[match] || 1) * 0.3;
                const winAmount = Math.max(Math.round(bet * payout), bet);
                Balance.add(winAmount);
                resultEl.textContent = `✨ Пара! Выигрыш: ${Balance.formatNumber(winAmount)} 💎`;
                resultEl.className = 'slot-result win';
            } else {
                resultEl.textContent = `Попробуй ещё! -${Balance.formatNumber(bet)} 💎`;
                resultEl.className = 'slot-result lose';
            }
        }, 1500);
    }

    document.addEventListener('DOMContentLoaded', () => {
        document.getElementById('spin-btn').addEventListener('click', spin);
    });
})();

/* Dice Game */
(function() {
    const HOUSE_EDGE = 0.02; // 2%
    let mode = 'under'; // under | over

    function getChance() {
        const target = parseInt(document.getElementById('dice-slider').value, 10);
        return mode === 'under' ? target : 100 - target;
    }

    function getPayout() {
        const chance = getChance();
        if (chance <= 0 || chance >= 100) return 0;
        return Math.round(((1 - HOUSE_EDGE) / (chance / 100)) * 100) / 100;
    }

    function updateDisplay() {
        const target = parseInt(document.getElementById('dice-slider').value, 10);
        const chance = getChance();
        const payout = getPayout();

        document.getElementById('dice-target-label').textContent = target;
        document.getElementById('dice-chance').textContent = chance + '%';
        document.getElementById('dice-payout').textContent = payout.toFixed(2) + '×';

        // Update slider gradient
        const slider = document.getElementById('dice-slider');
        if (mode === 'under') {
            slider.style.background = `linear-gradient(to right, #22c55e ${target}%, #ef4444 ${target}%)`;
        } else {
            slider.style.background = `linear-gradient(to right, #ef4444 ${target}%, #22c55e ${target}%)`;
        }
    }

    function roll() {
        const betInput = document.getElementById('dice-bet');
        const bet = parseInt(betInput.value, 10);
        const resultEl = document.getElementById('dice-result');
        const rollResultEl = document.getElementById('dice-roll-result');

        if (isNaN(bet) || bet < 10) {
            resultEl.textContent = 'Минимальная ставка: 10';
            resultEl.className = 'dice-result lose';
            return;
        }
        if (!Balance.canAfford(bet)) {
            resultEl.textContent = 'Недостаточно средств!';
            resultEl.className = 'dice-result lose';
            return;
        }

        const target = parseInt(document.getElementById('dice-slider').value, 10);
        const payout = getPayout();

        Balance.subtract(bet);

        // Roll animation
        let rollCount = 0;
        const rollInterval = setInterval(() => {
            rollResultEl.textContent = (Math.random() * 99 + 1).toFixed(2);
            rollResultEl.style.color = '#a78bfa';
            rollCount++;
            if (rollCount > 15) {
                clearInterval(rollInterval);

                // Final result
                const result = Math.round((Math.random() * 9899 + 100)) / 100; // 1.00 to 99.99
                rollResultEl.textContent = result.toFixed(2);

                let won = false;
                if (mode === 'under' && result < target) won = true;
                if (mode === 'over' && result > target) won = true;

                if (won) {
                    const winAmount = Math.round(bet * payout);
                    Balance.add(winAmount);
                    rollResultEl.style.color = '#22c55e';
                    resultEl.textContent = `🎉 ${result.toFixed(2)} ${mode === 'under' ? '<' : '>'} ${target} — Выигрыш: ${Balance.formatNumber(winAmount)} 💎`;
                    resultEl.className = 'dice-result win';
                } else {
                    rollResultEl.style.color = '#ef4444';
                    resultEl.textContent = `${result.toFixed(2)} ${mode === 'under' ? '≥' : '≤'} ${target} — Проигрыш`;
                    resultEl.className = 'dice-result lose';
                }
            }
        }, 50);
    }

    document.addEventListener('DOMContentLoaded', () => {
        const slider = document.getElementById('dice-slider');
        if (!slider) return;

        slider.addEventListener('input', updateDisplay);

        document.querySelectorAll('.dice-mode-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('.dice-mode-btn').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                mode = btn.dataset.mode;
                updateDisplay();
            });
        });

        document.getElementById('dice-roll-btn').addEventListener('click', roll);
        updateDisplay();
    });
})();

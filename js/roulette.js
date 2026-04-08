/* Roulette Game */
(function() {
    const RED_NUMBERS = [1,3,5,7,9,12,14,16,18,19,21,23,25,27,30,32,34,36];
    const WHEEL_NUMBERS = [
        0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36,
        11, 30, 8, 23, 10, 5, 24, 16, 33, 1, 20, 14, 31, 9,
        22, 18, 29, 7, 28, 12, 35, 3, 26
    ];

    const BET_LABELS = {
        red: 'Красное', black: 'Чёрное', green: 'Зелёное',
        odd: 'Нечёт', even: 'Чёт',
        '1-12': '1-12', '13-24': '13-24', '25-36': '25-36'
    };

    let selectedBets = {};
    let isSpinning = false;
    let wheelAngle = 0;

    function isRed(n) { return RED_NUMBERS.includes(n); }
    function getColor(n) { return n === 0 ? 'green' : isRed(n) ? 'red' : 'black'; }

    function drawWheel(canvas, highlightIndex) {
        const ctx = canvas.getContext('2d');
        const cx = canvas.width / 2;
        const cy = canvas.height / 2;
        const r = Math.min(cx, cy) - 10;
        const count = WHEEL_NUMBERS.length;
        const arc = (2 * Math.PI) / count;

        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.save();
        ctx.translate(cx, cy);
        ctx.rotate(wheelAngle);

        for (let i = 0; i < count; i++) {
            const num = WHEEL_NUMBERS[i];
            const angle = i * arc - Math.PI / 2;
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.arc(0, 0, r, angle, angle + arc);
            ctx.closePath();

            if (num === 0) ctx.fillStyle = '#15803d';
            else if (isRed(num)) ctx.fillStyle = '#b91c1c';
            else ctx.fillStyle = '#1f2937';

            if (highlightIndex === i) {
                ctx.fillStyle = '#eab308';
            }
            ctx.fill();
            ctx.strokeStyle = '#0f0f1a';
            ctx.lineWidth = 1;
            ctx.stroke();

            // Number text
            ctx.save();
            ctx.rotate(angle + arc / 2);
            ctx.textAlign = 'center';
            ctx.fillStyle = '#fff';
            ctx.font = 'bold 11px Montserrat, sans-serif';
            ctx.fillText(num, r * 0.78, 4);
            ctx.restore();
        }

        ctx.restore();

        // Center circle
        ctx.beginPath();
        ctx.arc(cx, cy, r * 0.2, 0, Math.PI * 2);
        ctx.fillStyle = '#1a1a2e';
        ctx.fill();
        ctx.strokeStyle = '#7c3aed';
        ctx.lineWidth = 2;
        ctx.stroke();

        // Pointer (top)
        ctx.beginPath();
        ctx.moveTo(cx - 10, 5);
        ctx.lineTo(cx + 10, 5);
        ctx.lineTo(cx, 22);
        ctx.closePath();
        ctx.fillStyle = '#eab308';
        ctx.fill();
    }

    function buildNumberGrid() {
        const grid = document.getElementById('roulette-number-grid');
        if (!grid) return;
        grid.innerHTML = '';

        // Zero first
        const zeroBtn = document.createElement('button');
        zeroBtn.className = 'roulette-num-btn rnum-green';
        zeroBtn.textContent = '0';
        zeroBtn.dataset.bet = 'number-0';
        grid.appendChild(zeroBtn);

        for (let i = 1; i <= 36; i++) {
            const btn = document.createElement('button');
            btn.className = 'roulette-num-btn ' + (isRed(i) ? 'rnum-red' : 'rnum-black');
            btn.textContent = i;
            btn.dataset.bet = 'number-' + i;
            grid.appendChild(btn);
        }
    }

    function toggleBet(betType) {
        if (selectedBets[betType]) {
            delete selectedBets[betType];
        } else {
            selectedBets[betType] = true;
        }
        updateBetDisplay();
    }

    function updateBetDisplay() {
        const activeBetsEl = document.getElementById('roulette-active-bets');
        const keys = Object.keys(selectedBets);
        if (keys.length === 0) {
            activeBetsEl.textContent = 'Выберите ставку';
        } else {
            activeBetsEl.textContent = 'Ставки: ' + keys.map(k => {
                if (k.startsWith('number-')) return '#' + k.split('-')[1];
                return BET_LABELS[k] || k;
            }).join(', ');
        }

        // Update button states
        document.querySelectorAll('.roulette-bet-btn, .roulette-num-btn').forEach(btn => {
            const bt = btn.dataset.bet;
            btn.classList.toggle('selected', !!selectedBets[bt]);
        });
    }

    function spinRoulette() {
        if (isSpinning) return;

        const betInput = document.getElementById('roulette-bet');
        const bet = parseInt(betInput.value, 10);
        const resultEl = document.getElementById('roulette-result');
        const numberEl = document.getElementById('roulette-number');
        const canvas = document.getElementById('roulette-canvas');

        const betKeys = Object.keys(selectedBets);
        if (betKeys.length === 0) {
            resultEl.textContent = 'Сначала выберите ставку!';
            resultEl.className = 'roulette-result lose';
            return;
        }
        if (isNaN(bet) || bet < 10) {
            resultEl.textContent = 'Минимальная ставка: 10';
            resultEl.className = 'roulette-result lose';
            return;
        }

        const totalBet = bet * betKeys.length;
        if (!Balance.canAfford(totalBet)) {
            resultEl.textContent = 'Недостаточно средств!';
            resultEl.className = 'roulette-result lose';
            return;
        }

        Balance.subtract(totalBet);
        isSpinning = true;
        resultEl.textContent = '';
        resultEl.className = 'roulette-result';
        numberEl.textContent = '...';

        // Pick winning number
        const winIndex = Math.floor(Math.random() * WHEEL_NUMBERS.length);
        const winNum = WHEEL_NUMBERS[winIndex];
        const winColor = getColor(winNum);

        // Animate wheel
        const totalRotation = Math.PI * 2 * (5 + Math.random() * 3);
        const targetAngle = -((winIndex / WHEEL_NUMBERS.length) * Math.PI * 2);
        const finalAngle = totalRotation + targetAngle;
        const duration = 3000;
        const start = performance.now();

        function animate(time) {
            const elapsed = time - start;
            const progress = Math.min(elapsed / duration, 1);
            // Ease out cubic
            const ease = 1 - Math.pow(1 - progress, 3);
            wheelAngle = ease * finalAngle;
            drawWheel(canvas, progress > 0.95 ? winIndex : -1);

            if (progress < 1) {
                requestAnimationFrame(animate);
            } else {
                // Done
                isSpinning = false;
                numberEl.textContent = winNum;
                numberEl.style.color = winColor === 'red' ? '#ef4444' : winColor === 'green' ? '#22c55e' : '#e2e8f0';

                // Calculate winnings
                let totalWin = 0;
                betKeys.forEach(key => {
                    if (key === 'red' && winColor === 'red') totalWin += bet * 2;
                    else if (key === 'black' && winColor === 'black') totalWin += bet * 2;
                    else if (key === 'green' && winColor === 'green') totalWin += bet * 14;
                    else if (key === 'odd' && winNum > 0 && winNum % 2 === 1) totalWin += bet * 2;
                    else if (key === 'even' && winNum > 0 && winNum % 2 === 0) totalWin += bet * 2;
                    else if (key === '1-12' && winNum >= 1 && winNum <= 12) totalWin += bet * 3;
                    else if (key === '13-24' && winNum >= 13 && winNum <= 24) totalWin += bet * 3;
                    else if (key === '25-36' && winNum >= 25 && winNum <= 36) totalWin += bet * 3;
                    else if (key.startsWith('number-') && parseInt(key.split('-')[1], 10) === winNum) totalWin += bet * 36;
                });

                if (totalWin > 0) {
                    Balance.add(totalWin);
                    resultEl.textContent = `🎉 Выпало ${winNum} (${winColor === 'red' ? 'красное' : winColor === 'green' ? 'зелёное' : 'чёрное'}) — Выигрыш: ${Balance.formatNumber(totalWin)} 💎`;
                    resultEl.className = 'roulette-result win';
                } else {
                    resultEl.textContent = `Выпало ${winNum} (${winColor === 'red' ? 'красное' : winColor === 'green' ? 'зелёное' : 'чёрное'}) — Проигрыш`;
                    resultEl.className = 'roulette-result lose';
                }
            }
        }
        requestAnimationFrame(animate);
    }

    document.addEventListener('DOMContentLoaded', () => {
        const canvas = document.getElementById('roulette-canvas');
        if (!canvas) return;

        buildNumberGrid();
        drawWheel(canvas, -1);

        // Bet buttons
        document.querySelectorAll('.roulette-bet-btn').forEach(btn => {
            btn.addEventListener('click', () => toggleBet(btn.dataset.bet));
        });
        document.getElementById('roulette-number-grid').addEventListener('click', e => {
            if (e.target.classList.contains('roulette-num-btn')) {
                toggleBet(e.target.dataset.bet);
            }
        });

        document.getElementById('roulette-spin-btn').addEventListener('click', spinRoulette);
        updateBetDisplay();
    });
})();

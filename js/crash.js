/* Crash Game */
(function() {
    let gameState = 'idle'; // idle | running | crashed | cashed
    let multiplier = 1.00;
    let crashPoint = 1.00;
    let currentBet = 0;
    let animFrame = null;
    let startTime = 0;
    let graphPoints = [];
    const history = [];

    function generateCrashPoint() {
        // House edge ~3%
        const r = Math.random();
        if (r < 0.03) return 1.00; // instant crash 3%
        return Math.max(1.00, Math.floor(100 / (1 - r)) / 100);
    }

    function drawGraph(canvas) {
        const ctx = canvas.getContext('2d');
        const w = canvas.width;
        const h = canvas.height;
        ctx.clearRect(0, 0, w, h);

        // Background
        ctx.fillStyle = '#0f0f1a';
        ctx.fillRect(0, 0, w, h);

        // Grid
        ctx.strokeStyle = 'rgba(45, 45, 74, 0.5)';
        ctx.lineWidth = 1;
        for (let i = 1; i < 5; i++) {
            const y = h - (h / 5) * i;
            ctx.beginPath();
            ctx.moveTo(0, y);
            ctx.lineTo(w, y);
            ctx.stroke();

            ctx.fillStyle = '#94a3b8';
            ctx.font = '11px Montserrat, sans-serif';
            ctx.fillText((1 + i).toFixed(1) + '×', 4, y + 14);
        }

        if (graphPoints.length < 2) return;

        // Line
        const maxT = graphPoints[graphPoints.length - 1].t;
        const maxM = Math.max(multiplier, 2);

        ctx.beginPath();
        ctx.strokeStyle = gameState === 'crashed' ? '#ef4444' : '#22c55e';
        ctx.lineWidth = 3;
        ctx.shadowColor = gameState === 'crashed' ? 'rgba(239,68,68,0.4)' : 'rgba(34,197,94,0.4)';
        ctx.shadowBlur = 10;

        graphPoints.forEach((p, i) => {
            const x = (p.t / Math.max(maxT, 2000)) * (w - 20) + 10;
            const y = h - ((p.m - 1) / (maxM - 1)) * (h - 40) - 20;
            if (i === 0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
        });
        ctx.stroke();
        ctx.shadowBlur = 0;

        // Fill under curve
        const lastPt = graphPoints[graphPoints.length - 1];
        const lastX = (lastPt.t / Math.max(maxT, 2000)) * (w - 20) + 10;
        const lastY = h - ((lastPt.m - 1) / (maxM - 1)) * (h - 40) - 20;
        ctx.lineTo(lastX, h);
        ctx.lineTo(10, h);
        ctx.closePath();
        ctx.fillStyle = gameState === 'crashed' ? 'rgba(239,68,68,0.08)' : 'rgba(34,197,94,0.08)';
        ctx.fill();
    }

    function updateGame(timestamp) {
        if (gameState !== 'running') return;

        const elapsed = timestamp - startTime;
        // Exponential growth: e^(0.0006*t)
        multiplier = Math.pow(Math.E, 0.0006 * elapsed);
        multiplier = Math.round(multiplier * 100) / 100;

        graphPoints.push({ t: elapsed, m: multiplier });

        const multEl = document.getElementById('crash-multiplier');
        multEl.textContent = multiplier.toFixed(2) + '×';
        multEl.className = 'crash-multiplier';

        const canvas = document.getElementById('crash-canvas');
        drawGraph(canvas);

        if (multiplier >= crashPoint) {
            // Crash!
            gameState = 'crashed';
            multiplier = crashPoint;
            multEl.textContent = multiplier.toFixed(2) + '×';
            multEl.className = 'crash-multiplier crashed';

            graphPoints.push({ t: elapsed, m: multiplier });
            drawGraph(canvas);

            addHistory(crashPoint);
            const resultEl = document.getElementById('crash-result');
            resultEl.textContent = `💥 КРАШ на ${crashPoint.toFixed(2)}× — Проигрыш ${Balance.formatNumber(currentBet)} 💎`;
            resultEl.className = 'crash-result lose';

            document.getElementById('crash-play-btn').style.display = '';
            document.getElementById('crash-cashout-btn').style.display = 'none';
            return;
        }

        animFrame = requestAnimationFrame(updateGame);
    }

    function addHistory(val) {
        history.unshift(val);
        if (history.length > 20) history.pop();
        const el = document.getElementById('crash-history');
        el.innerHTML = history.map(v => {
            const cls = v >= 2 ? 'high' : 'low';
            return `<span class="crash-history-item ${cls}">${v.toFixed(2)}×</span>`;
        }).join('');
    }

    function play() {
        if (gameState === 'running') return;

        const betInput = document.getElementById('crash-bet');
        const bet = parseInt(betInput.value, 10);
        const resultEl = document.getElementById('crash-result');

        if (isNaN(bet) || bet < 10) {
            resultEl.textContent = 'Минимальная ставка: 10';
            resultEl.className = 'crash-result lose';
            return;
        }
        if (!Balance.canAfford(bet)) {
            resultEl.textContent = 'Недостаточно средств!';
            resultEl.className = 'crash-result lose';
            return;
        }

        Balance.subtract(bet);
        currentBet = bet;
        crashPoint = generateCrashPoint();
        multiplier = 1.00;
        graphPoints = [{ t: 0, m: 1.00 }];
        gameState = 'running';

        resultEl.textContent = '';
        resultEl.className = 'crash-result';

        document.getElementById('crash-play-btn').style.display = 'none';
        document.getElementById('crash-cashout-btn').style.display = '';

        startTime = performance.now();
        animFrame = requestAnimationFrame(updateGame);
    }

    function cashout() {
        if (gameState !== 'running') return;

        gameState = 'cashed';
        if (animFrame) cancelAnimationFrame(animFrame);

        const winAmount = Math.round(currentBet * multiplier);
        Balance.add(winAmount);

        addHistory(crashPoint);

        const resultEl = document.getElementById('crash-result');
        resultEl.textContent = `💰 Забрано на ${multiplier.toFixed(2)}× — Выигрыш: ${Balance.formatNumber(winAmount)} 💎`;
        resultEl.className = 'crash-result win';

        const multEl = document.getElementById('crash-multiplier');
        multEl.textContent = multiplier.toFixed(2) + '× ✓';

        document.getElementById('crash-play-btn').style.display = '';
        document.getElementById('crash-cashout-btn').style.display = 'none';
    }

    document.addEventListener('DOMContentLoaded', () => {
        document.getElementById('crash-play-btn').addEventListener('click', play);
        document.getElementById('crash-cashout-btn').addEventListener('click', cashout);

        // Initial draw
        const canvas = document.getElementById('crash-canvas');
        if (canvas) drawGraph(canvas);
    });
})();

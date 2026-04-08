/* Mines Game */
(function() {
    const GRID_SIZE = 25; // 5x5
    let minePositions = [];
    let revealed = [];
    let mineCount = 3;
    let currentBet = 0;
    let gemsFound = 0;
    let gameActive = false;

    function getMultiplier(gems, mines) {
        // Fair multiplier based on probability
        const total = GRID_SIZE;
        let mult = 1;
        for (let i = 0; i < gems; i++) {
            mult *= total - mines - i;
            mult /= total - i;
        }
        return Math.max(1, Math.round((0.97 / mult) * 100) / 100);
    }

    function buildGrid() {
        const grid = document.getElementById('mines-grid');
        grid.innerHTML = '';
        for (let i = 0; i < GRID_SIZE; i++) {
            const cell = document.createElement('div');
            cell.className = 'mine-cell';
            cell.dataset.index = i;
            cell.textContent = '';
            grid.appendChild(cell);
        }
    }

    function placeMines(count) {
        const positions = [];
        while (positions.length < count) {
            const pos = Math.floor(Math.random() * GRID_SIZE);
            if (!positions.includes(pos)) positions.push(pos);
        }
        return positions;
    }

    function updateInfo() {
        document.getElementById('mines-multiplier').textContent =
            getMultiplier(gemsFound, mineCount).toFixed(2) + '×';
        document.getElementById('mines-found').textContent = gemsFound;
    }

    function revealAll() {
        const cells = document.querySelectorAll('.mine-cell');
        cells.forEach((cell, i) => {
            if (!revealed.includes(i)) {
                if (minePositions.includes(i)) {
                    cell.textContent = '💣';
                    cell.classList.add('revealed', 'bomb');
                } else {
                    cell.textContent = '💎';
                    cell.classList.add('revealed', 'gem');
                    cell.style.opacity = '0.4';
                }
            }
        });
    }

    function clickCell(index) {
        if (!gameActive || revealed.includes(index)) return;

        revealed.push(index);
        const cell = document.querySelectorAll('.mine-cell')[index];

        if (minePositions.includes(index)) {
            // Hit a mine!
            cell.textContent = '💥';
            cell.classList.add('revealed', 'bomb');
            gameActive = false;

            revealAll();

            const resultEl = document.getElementById('mines-result');
            resultEl.textContent = `💥 БУМ! Проигрыш ${Balance.formatNumber(currentBet)} 💎`;
            resultEl.className = 'mines-result lose';

            document.getElementById('mines-play-btn').style.display = '';
            document.getElementById('mines-cashout-btn').style.display = 'none';
        } else {
            // Safe!
            cell.textContent = '💎';
            cell.classList.add('revealed', 'gem');
            gemsFound++;
            updateInfo();

            // Check if all safe cells found
            if (gemsFound >= GRID_SIZE - mineCount) {
                cashout();
            }
        }
    }

    function play() {
        if (gameActive) return;

        const betInput = document.getElementById('mines-bet');
        const bet = parseInt(betInput.value, 10);
        const resultEl = document.getElementById('mines-result');
        mineCount = parseInt(document.getElementById('mines-count').value, 10);

        if (isNaN(bet) || bet < 10) {
            resultEl.textContent = 'Минимальная ставка: 10';
            resultEl.className = 'mines-result lose';
            return;
        }
        if (!Balance.canAfford(bet)) {
            resultEl.textContent = 'Недостаточно средств!';
            resultEl.className = 'mines-result lose';
            return;
        }

        Balance.subtract(bet);
        currentBet = bet;
        gemsFound = 0;
        revealed = [];
        minePositions = placeMines(mineCount);
        gameActive = true;

        buildGrid();
        updateInfo();
        resultEl.textContent = '';
        resultEl.className = 'mines-result';

        document.getElementById('mines-play-btn').style.display = 'none';
        document.getElementById('mines-cashout-btn').style.display = '';
    }

    function cashout() {
        if (!gameActive || gemsFound === 0) return;

        gameActive = false;
        const mult = getMultiplier(gemsFound, mineCount);
        const winAmount = Math.round(currentBet * mult);
        Balance.add(winAmount);

        revealAll();

        const resultEl = document.getElementById('mines-result');
        resultEl.textContent = `💰 Забрано! ${mult.toFixed(2)}× — Выигрыш: ${Balance.formatNumber(winAmount)} 💎`;
        resultEl.className = 'mines-result win';

        document.getElementById('mines-play-btn').style.display = '';
        document.getElementById('mines-cashout-btn').style.display = 'none';
    }

    document.addEventListener('DOMContentLoaded', () => {
        buildGrid();
        updateInfo();

        document.getElementById('mines-grid').addEventListener('click', e => {
            const cell = e.target.closest('.mine-cell');
            if (cell) clickCell(parseInt(cell.dataset.index, 10));
        });

        document.getElementById('mines-play-btn').addEventListener('click', play);
        document.getElementById('mines-cashout-btn').addEventListener('click', cashout);
    });
})();

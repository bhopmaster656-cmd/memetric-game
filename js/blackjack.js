/* Blackjack Game */
(function() {
    const SUITS = ['♠', '♥', '♦', '♣'];
    const RANKS = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];

    let deck = [];
    let playerHand = [];
    let dealerHand = [];
    let currentBet = 0;
    let gameActive = false;

    function createDeck() {
        const d = [];
        for (const suit of SUITS) {
            for (const rank of RANKS) {
                d.push({ rank, suit });
            }
        }
        // Shuffle
        for (let i = d.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [d[i], d[j]] = [d[j], d[i]];
        }
        return d;
    }

    function cardValue(card) {
        if (['J', 'Q', 'K'].includes(card.rank)) return 10;
        if (card.rank === 'A') return 11;
        return parseInt(card.rank, 10);
    }

    function handScore(hand) {
        let score = 0;
        let aces = 0;
        for (const card of hand) {
            score += cardValue(card);
            if (card.rank === 'A') aces++;
        }
        while (score > 21 && aces > 0) {
            score -= 10;
            aces--;
        }
        return score;
    }

    function isRedSuit(suit) { return suit === '♥' || suit === '♦'; }

    function renderCard(card, faceDown) {
        const div = document.createElement('div');
        div.className = 'playing-card';
        if (faceDown) {
            div.classList.add('face-down');
            return div;
        }
        if (isRedSuit(card.suit)) div.classList.add('red');
        div.innerHTML = `<span>${card.rank}</span><span class="card-suit">${card.suit}</span>`;
        return div;
    }

    function renderHands(revealDealer) {
        const dealerEl = document.getElementById('dealer-cards');
        const playerEl = document.getElementById('player-cards');
        const dealerScoreEl = document.getElementById('dealer-score');
        const playerScoreEl = document.getElementById('player-score');

        dealerEl.innerHTML = '';
        playerEl.innerHTML = '';

        dealerHand.forEach((card, i) => {
            dealerEl.appendChild(renderCard(card, !revealDealer && i === 1));
        });

        playerHand.forEach(card => {
            playerEl.appendChild(renderCard(card, false));
        });

        if (revealDealer) {
            dealerScoreEl.textContent = `(${handScore(dealerHand)})`;
        } else if (dealerHand.length > 0) {
            dealerScoreEl.textContent = `(${cardValue(dealerHand[0])})`;
        } else {
            dealerScoreEl.textContent = '';
        }
        playerScoreEl.textContent = playerHand.length > 0 ? `(${handScore(playerHand)})` : '';
    }

    function setButtons(dealing) {
        document.getElementById('bj-deal-btn').disabled = dealing;
        document.getElementById('bj-hit-btn').disabled = !dealing;
        document.getElementById('bj-stand-btn').disabled = !dealing;
        document.getElementById('bj-double-btn').disabled = !dealing || playerHand.length !== 2 || !Balance.canAfford(currentBet);
        document.getElementById('bj-bet').disabled = dealing;
    }

    function endGame(result, message) {
        gameActive = false;
        const resultEl = document.getElementById('bj-result');

        renderHands(true);

        if (result === 'win') {
            Balance.add(currentBet * 2);
            resultEl.className = 'bj-result win win-pulse';
        } else if (result === 'blackjack') {
            Balance.add(Math.round(currentBet * 2.5));
            resultEl.className = 'bj-result win win-pulse';
        } else if (result === 'push') {
            Balance.add(currentBet);
            resultEl.className = 'bj-result push';
        } else {
            resultEl.className = 'bj-result lose';
        }

        resultEl.textContent = message;
        setButtons(false);
    }

    function dealerPlay() {
        renderHands(true);

        function dealerDraw() {
            if (handScore(dealerHand) < 17) {
                setTimeout(() => {
                    dealerHand.push(deck.pop());
                    renderHands(true);
                    dealerDraw();
                }, 500);
            } else {
                const ds = handScore(dealerHand);
                const ps = handScore(playerHand);

                if (ds > 21) {
                    endGame('win', `Дилер перебрал! (${ds}) Вы выиграли ${Balance.formatNumber(currentBet * 2)} 💎`);
                } else if (ds > ps) {
                    endGame('lose', `Дилер ${ds} vs Вы ${ps} — Проигрыш`);
                } else if (ds < ps) {
                    endGame('win', `Вы ${ps} vs Дилер ${ds} — Выигрыш ${Balance.formatNumber(currentBet * 2)} 💎`);
                } else {
                    endGame('push', `Ничья! ${ps} = ${ds}`);
                }
            }
        }
        dealerDraw();
    }

    function deal() {
        if (gameActive) return;

        const betInput = document.getElementById('bj-bet');
        const bet = parseInt(betInput.value, 10);
        const resultEl = document.getElementById('bj-result');

        if (isNaN(bet) || bet < 10) {
            resultEl.textContent = 'Минимальная ставка: 10';
            resultEl.className = 'bj-result lose';
            return;
        }
        if (!Balance.canAfford(bet)) {
            resultEl.textContent = 'Недостаточно средств!';
            resultEl.className = 'bj-result lose';
            return;
        }

        Balance.subtract(bet);
        currentBet = bet;
        gameActive = true;
        resultEl.textContent = '';
        resultEl.className = 'bj-result';

        deck = createDeck();
        playerHand = [deck.pop(), deck.pop()];
        dealerHand = [deck.pop(), deck.pop()];

        renderHands(false);
        setButtons(true);

        // Check for blackjack
        if (handScore(playerHand) === 21) {
            if (handScore(dealerHand) === 21) {
                endGame('push', 'Оба блэкджека! Ничья');
            } else {
                endGame('blackjack', `🃏 БЛЭКДЖЕК! Выигрыш: ${Balance.formatNumber(Math.round(currentBet * 2.5))} 💎`);
            }
        }
    }

    function hit() {
        if (!gameActive) return;
        playerHand.push(deck.pop());
        renderHands(false);
        setButtons(true);
        document.getElementById('bj-double-btn').disabled = true;

        if (handScore(playerHand) > 21) {
            endGame('lose', `Перебор! (${handScore(playerHand)}) — Проигрыш`);
        } else if (handScore(playerHand) === 21) {
            stand();
        }
    }

    function stand() {
        if (!gameActive) return;
        setButtons(false);
        dealerPlay();
    }

    function doubleBet() {
        if (!gameActive || playerHand.length !== 2) return;
        if (!Balance.canAfford(currentBet)) return;

        Balance.subtract(currentBet);
        currentBet *= 2;
        playerHand.push(deck.pop());
        renderHands(false);

        if (handScore(playerHand) > 21) {
            endGame('lose', `Перебор! (${handScore(playerHand)}) — Проигрыш`);
        } else {
            setButtons(false);
            dealerPlay();
        }
    }

    document.addEventListener('DOMContentLoaded', () => {
        document.getElementById('bj-deal-btn').addEventListener('click', deal);
        document.getElementById('bj-hit-btn').addEventListener('click', hit);
        document.getElementById('bj-stand-btn').addEventListener('click', stand);
        document.getElementById('bj-double-btn').addEventListener('click', doubleBet);
    });
})();

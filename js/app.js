/* Main App - Navigation & Shared Logic */
(function() {
    function navigateTo(page) {
        // Update pages
        document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
        const target = document.getElementById('page-' + page);
        if (target) target.classList.add('active');

        // Update nav
        document.querySelectorAll('.nav-btn').forEach(btn => {
            btn.classList.toggle('active', btn.dataset.page === page);
        });

        // Close sidebar on mobile
        document.getElementById('sidebar').classList.remove('open');
    }

    // Setup bet half/double buttons
    function setupBetControls() {
        document.querySelectorAll('.bet-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const action = btn.dataset.action;
                const input = btn.closest('.bet-control').querySelector('input[type="number"]');
                if (!input) return;
                let val = parseInt(input.value, 10) || 100;
                if (action === 'half') val = Math.max(10, Math.floor(val / 2));
                if (action === 'double') val = Math.min(100000, val * 2);
                input.value = val;
            });
        });
    }

    document.addEventListener('DOMContentLoaded', () => {
        // Navigation - sidebar
        document.querySelectorAll('.nav-btn').forEach(btn => {
            btn.addEventListener('click', () => navigateTo(btn.dataset.page));
        });

        // Navigation - game cards in lobby
        document.querySelectorAll('.game-card').forEach(card => {
            card.addEventListener('click', () => navigateTo(card.dataset.page));
        });

        // Mobile sidebar toggle
        document.getElementById('sidebar-toggle').addEventListener('click', () => {
            document.getElementById('sidebar').classList.toggle('open');
        });

        // Balance modal
        document.getElementById('add-balance-btn').addEventListener('click', () => {
            document.getElementById('balance-modal').style.display = 'flex';
        });
        document.getElementById('modal-close').addEventListener('click', () => {
            document.getElementById('balance-modal').style.display = 'none';
        });
        document.querySelectorAll('.modal-amount-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const amount = parseInt(btn.dataset.amount, 10);
                Balance.add(amount);
                document.getElementById('balance-modal').style.display = 'none';
            });
        });

        // Close modal on background click
        document.getElementById('balance-modal').addEventListener('click', e => {
            if (e.target === e.currentTarget) {
                e.currentTarget.style.display = 'none';
            }
        });

        // Setup bet controls
        setupBetControls();

        // Initialize balance display
        Balance.updateDisplay();
    });
})();

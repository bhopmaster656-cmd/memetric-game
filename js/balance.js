/* Balance Manager - Virtual currency system */
const Balance = {
    STORAGE_KEY: 'memetric_balance',
    DEFAULT: 10000,

    get() {
        const stored = localStorage.getItem(this.STORAGE_KEY);
        return stored !== null ? parseInt(stored, 10) : this.DEFAULT;
    },

    set(val) {
        val = Math.max(0, Math.round(val));
        localStorage.setItem(this.STORAGE_KEY, val);
        this.updateDisplay();
        return val;
    },

    add(amount) {
        return this.set(this.get() + amount);
    },

    subtract(amount) {
        const current = this.get();
        if (current < amount) return false;
        this.set(current - amount);
        return true;
    },

    canAfford(amount) {
        return this.get() >= amount;
    },

    updateDisplay() {
        const el = document.getElementById('balance');
        if (el) {
            el.textContent = this.get().toLocaleString('ru-RU');
        }
    },

    formatNumber(n) {
        return n.toLocaleString('ru-RU');
    }
};

// Initialize display on load
document.addEventListener('DOMContentLoaded', () => {
    Balance.updateDisplay();
});

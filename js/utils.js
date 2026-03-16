/**
 * Utility helpers.
 */

/* ─── Random ─────────────────────────────────────────────────────────────── */
function rnd(min, max) { return Math.random() * (max - min) + min; }
function rndInt(min, max) { return Math.floor(rnd(min, max + 1)); }
function pick(arr) { return arr[Math.floor(Math.random() * arr.length)]; }
function shuffle(arr) {
    const a = arr.slice();
    for (let i = a.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
}

/* ─── Math ───────────────────────────────────────────────────────────────── */
function lerp(a, b, t) { return a + (b - a) * t; }
function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }
function dist(ax, ay, bx, by) {
    const dx = ax - bx, dy = ay - by;
    return Math.sqrt(dx * dx + dy * dy);
}
function distSq(ax, ay, bx, by) {
    const dx = ax - bx, dy = ay - by;
    return dx * dx + dy * dy;
}

/* ─── Geometry ───────────────────────────────────────────────────────────── */
function rectOverlap(ax, ay, aw, ah, bx, by, bw, bh, margin) {
    margin = margin || 0;
    return !(ax + aw + margin < bx || bx + bw + margin < ax ||
             ay + ah + margin < by || by + bh + margin < ay);
}

function ptInRect(px, py, rx, ry, rw, rh) {
    return px >= rx && px <= rx + rw && py >= ry && py <= ry + rh;
}

/* ─── Simple 2-D Perlin-like noise (value noise) ────────────────────────── */
const _noiseTable = (() => {
    const t = new Float32Array(512);
    for (let i = 0; i < 256; i++) t[i] = t[i + 256] = Math.random();
    return t;
})();

function fade(t) { return t * t * t * (t * (t * 6 - 15) + 10); }
function noiseInterp(a, b, t) { return a + fade(t) * (b - a); }

function noise2(x, y) {
    const xi = Math.floor(x) & 255, yi = Math.floor(y) & 255;
    const xf = x - Math.floor(x), yf = y - Math.floor(y);
    const a  = _noiseTable[xi + _noiseTable[yi]];
    const b  = _noiseTable[xi + 1 + _noiseTable[yi]];
    const c  = _noiseTable[xi + _noiseTable[yi + 1]];
    const d  = _noiseTable[xi + 1 + _noiseTable[yi + 1]];
    return noiseInterp(noiseInterp(a, b, xf), noiseInterp(c, d, xf), yf);
}

function fbm(x, y, octaves, gain, lacunarity) {
    gain = gain || 0.5; lacunarity = lacunarity || 2.0;
    let val = 0, amp = 0.5, freq = 1, max = 0;
    for (let i = 0; i < octaves; i++) {
        val += noise2(x * freq, y * freq) * amp;
        max += amp; amp *= gain; freq *= lacunarity;
    }
    return val / max;
}

/* ─── String helpers ─────────────────────────────────────────────────────── */
function padZ(n, width) { return String(n).padStart(width, '0'); }
function formatNumber(n) {
    if (n >= 1e6) return (n / 1e6).toFixed(1) + 'М';
    if (n >= 1e3) return (n / 1e3).toFixed(1) + 'К';
    return String(Math.floor(n));
}

/* ─── Deep-clone plain object ────────────────────────────────────────────── */
function deepClone(obj) { return JSON.parse(JSON.stringify(obj)); }

/* ─── Debounce ───────────────────────────────────────────────────────────── */
function debounce(fn, delay) {
    let t;
    return (...args) => { clearTimeout(t); t = setTimeout(() => fn(...args), delay); };
}

/* ─── Color helpers ──────────────────────────────────────────────────────── */
function hexToRgb(hex) {
    const r = parseInt(hex.slice(1, 3), 16);
    const g = parseInt(hex.slice(3, 5), 16);
    const b = parseInt(hex.slice(5, 7), 16);
    return { r, g, b };
}
function rgbToHex(r, g, b) {
    return '#' + [r, g, b].map(v => clamp(Math.round(v), 0, 255).toString(16).padStart(2, '0')).join('');
}
function lighten(hex, amount) {
    const { r, g, b } = hexToRgb(hex);
    return rgbToHex(r + amount, g + amount, b + amount);
}
function darken(hex, amount) { return lighten(hex, -amount); }

/* ─── ID generator ───────────────────────────────────────────────────────── */
let _idCounter = 0;
function nextId() { return ++_idCounter; }

/* ─── Event emitter (tiny) ───────────────────────────────────────────────── */
class EventEmitter {
    constructor() { this._listeners = {}; }
    on(evt, fn) { (this._listeners[evt] = this._listeners[evt] || []).push(fn); return this; }
    off(evt, fn) {
        if (this._listeners[evt])
            this._listeners[evt] = this._listeners[evt].filter(f => f !== fn);
    }
    emit(evt, ...args) { (this._listeners[evt] || []).forEach(f => f(...args)); }
}

'use strict';

/**
 * Grid — manages cell state and merge logic.
 * Cells are indexed row-major: idx = row * COLS + col.
 */
const Grid = {
  cells: [],  // null | building-object

  init() {
    this.cells = new Array(CONFIG.GRID_COLS * CONFIG.GRID_ROWS).fill(null);
  },

  /** Place a building (by tier id) in the given cell. Returns true on success. */
  place(idx, tierId) {
    if (idx < 0 || idx >= this.cells.length) return false;
    if (this.cells[idx] !== null) return false;
    this.cells[idx] = Object.assign({}, BUILDINGS[tierId - 1]);
    return true;
  },

  /** Remove building from cell and return it (or null if empty). */
  remove(idx) {
    const bld = this.cells[idx];
    this.cells[idx] = null;
    return bld;
  },

  /** Move building from srcIdx to an empty dstIdx. Returns true on success. */
  move(srcIdx, dstIdx) {
    if (this.cells[dstIdx] !== null) return false;
    this.cells[dstIdx] = this.cells[srcIdx];
    this.cells[srcIdx] = null;
    return true;
  },

  /**
   * Merge building at srcIdx into dstIdx.
   * Both must exist and have the same tier id.
   * Returns the resulting building or null on failure.
   */
  merge(srcIdx, dstIdx) {
    const a = this.cells[srcIdx];
    const b = this.cells[dstIdx];
    if (!a || !b) return null;
    if (a.id !== b.id) return null;
    if (a.id >= CONFIG.MAX_TIER) return null; // already max

    // BUILDINGS is 0-indexed; a.id is the current tier number (1-10),
    // so BUILDINGS[a.id] gives the *next* tier (e.g. tier 1 → BUILDINGS[1] = tier 2).
    const newTier = BUILDINGS[a.id];
    this.cells[srcIdx] = null;
    this.cells[dstIdx] = Object.assign({}, newTier);
    return this.cells[dstIdx];
  },

  /** True when src and dst have same tier and dst is not src */
  canMerge(srcIdx, dstIdx) {
    if (srcIdx === dstIdx) return false;
    const a = this.cells[srcIdx];
    const b = this.cells[dstIdx];
    return a !== null && b !== null && a.id === b.id && a.id < CONFIG.MAX_TIER;
  },

  /** First empty cell index, or -1 */
  firstEmpty() {
    return this.cells.findIndex(c => c === null);
  },

  isFull() {
    return this.cells.every(c => c !== null);
  },

  /** Sum of income/s across all occupied cells */
  totalIncome() {
    return this.cells.reduce((s, c) => s + (c ? c.incomePerSec : 0), 0);
  },

  /** Highest tier currently on grid */
  maxTier() {
    return this.cells.reduce((m, c) => (c && c.id > m ? c.id : m), 0);
  },

  /** Cell index from canvas pixel (x, y) */
  indexFromPixel(px, py) {
    const cs = CONFIG.CELL_SIZE;
    const col = Math.floor(px / cs);
    const row = Math.floor(py / cs);
    if (col < 0 || col >= CONFIG.GRID_COLS) return -1;
    if (row < 0 || row >= CONFIG.GRID_ROWS) return -1;
    return row * CONFIG.GRID_COLS + col;
  },

  /** Canvas pixel center of cell at idx */
  centerOfCell(idx) {
    const cs = CONFIG.CELL_SIZE;
    const col = idx % CONFIG.GRID_COLS;
    const row = Math.floor(idx / CONFIG.GRID_COLS);
    return { x: col * cs + cs / 2, y: row * cs + cs / 2 };
  },

  /** Serialise grid cells (array of tier-ids or null) */
  serialise() {
    return this.cells.map(c => (c ? c.id : null));
  },

  /** Restore from serialised array */
  deserialise(data) {
    this.init();
    if (!Array.isArray(data)) return;
    data.forEach((tierId, idx) => {
      if (tierId !== null && tierId >= 1 && tierId <= CONFIG.MAX_TIER) {
        this.cells[idx] = Object.assign({}, BUILDINGS[tierId - 1]);
      }
    });
  },
};

'use strict';

const Utils = {
  formatNumber(n) {
    if (n >= 1e15) return (n / 1e15).toFixed(2) + 'Q';
    if (n >= 1e12) return (n / 1e12).toFixed(2) + 'T';
    if (n >= 1e9)  return (n / 1e9).toFixed(2) + 'B';
    if (n >= 1e6)  return (n / 1e6).toFixed(2) + 'M';
    if (n >= 1e3)  return (n / 1e3).toFixed(1) + 'K';
    return Math.floor(n).toString();
  },

  /** Parse a hex color string to {r,g,b} */
  hexToRgb(hex) {
    const res = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return res
      ? { r: parseInt(res[1], 16), g: parseInt(res[2], 16), b: parseInt(res[3], 16) }
      : { r: 255, g: 255, b: 255 };
  },

  lerp(a, b, t) { return a + (b - a) * t; },
  clamp(v, lo, hi) { return Math.min(Math.max(v, lo), hi); },
  easeOut(t) { return 1 - Math.pow(1 - t, 3); },
  easeInOut(t) { return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t; },

  /** Deep clone a plain-object or array */
  deepClone(o) { return JSON.parse(JSON.stringify(o)); },
};

'use strict';

/**
 * Renderer — draws grid, buildings, drag ghost and particles onto the canvas.
 *
 * Visual style: colorful 3D-box buildings (front face + right side face + roof)
 * sitting on a city ground, matching the bright city-builder aesthetic of
 * Empire City / similar Yandex Games titles.
 */
const Renderer = {
  canvas: null,
  ctx: null,
  particles: null,

  /** Advances each frame for animated elements */
  _phase: 0,

  /* ── 3D depth offsets (applied uniformly for consistent "light source") ── */
  DEPTH_X: 10,   // pixels the side-face shifts right
  DEPTH_Y:  6,   // pixels the roof shifts upward

  init(canvas, particles) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.particles = particles;
  },

  render(grid, drag) {
    const ctx = this.ctx;
    const W = this.canvas.width;
    const H = this.canvas.height;

    // Advance animation phase [0, 2π)
    this._phase = (this._phase + 0.014) % (Math.PI * 2);

    this._drawBackground(W, H);
    this._drawGrid(grid, drag);
    this.particles.draw(ctx);

    if (drag && drag.building && drag.active) {
      ctx.save();
      ctx.globalAlpha = 0.72;
      this._drawBuilding(drag.building, drag.x, drag.y, CONFIG.CELL_SIZE);
      ctx.restore();
    }
  },

  /* ── Background ───────────────────────────────────────────────────────── */
  _drawBackground(W, H) {
    const ctx = this.ctx;

    // Night-city sky gradient
    const sky = ctx.createLinearGradient(0, 0, 0, H);
    sky.addColorStop(0,   '#08111e');
    sky.addColorStop(0.5, '#0c1a2e');
    sky.addColorStop(1,   '#101f35');
    ctx.fillStyle = sky;
    ctx.fillRect(0, 0, W, H);

    // Subtle ambient city-light bloom
    ctx.save();
    ctx.globalAlpha = 0.07;
    const glow = ctx.createRadialGradient(W * 0.5, H * 0.2, 0, W * 0.5, H * 0.2, W * 0.7);
    glow.addColorStop(0, '#4fc3f7');
    glow.addColorStop(1, 'transparent');
    ctx.fillStyle = glow;
    ctx.fillRect(0, 0, W, H);
    ctx.restore();
  },

  /* ── Grid ─────────────────────────────────────────────────────────────── */
  _drawGrid(grid, drag) {
    const cs = CONFIG.CELL_SIZE;
    const cols = CONFIG.GRID_COLS;
    const rows = CONFIG.GRID_ROWS;

    for (let row = 0; row < rows; row++) {
      for (let col = 0; col < cols; col++) {
        const idx  = row * cols + col;
        const cx   = col * cs + cs / 2;
        const cy   = row * cs + cs / 2;
        const cell = grid.cells[idx];
        const isDragSrc = drag && drag.srcIdx === idx;
        const isTarget  = drag && drag.active &&
          grid.canMerge(drag.srcIdx, idx) && idx !== drag.srcIdx;

        this._drawCell(cx, cy, cs, cell, isDragSrc, isTarget);
        if (cell && !isDragSrc) {
          this._drawBuilding(cell, cx, cy, cs);
        }
      }
    }
  },

  _drawCell(cx, cy, cs, cell, isDragSrc, isTarget) {
    const ctx = this.ctx;
    const pad = 3;
    const x = cx - cs / 2 + pad;
    const y = cy - cs / 2 + pad;
    const w = cs - pad * 2;
    const h = cs - pad * 2;

    ctx.save();
    ctx.beginPath();
    ctx.roundRect(x, y, w, h, 6);

    if (isTarget) {
      const p = 0.5 + 0.5 * Math.sin(this._phase * 4);
      ctx.fillStyle   = `rgba(80,255,130,${0.14 + 0.1 * p})`;
      ctx.shadowBlur  = 14 + 7 * p;
      ctx.shadowColor = '#00ff80';
      ctx.strokeStyle = `rgba(80,255,130,${0.75 + 0.25 * p})`;
      ctx.lineWidth   = 2;
    } else if (isDragSrc) {
      ctx.fillStyle   = 'rgba(100,190,255,0.06)';
      ctx.strokeStyle = 'rgba(100,190,255,0.55)';
      ctx.lineWidth   = 1.5;
      ctx.setLineDash([5, 5]);
    } else if (cell) {
      ctx.fillStyle   = 'rgba(18,32,55,0.88)';
      ctx.strokeStyle = 'rgba(55,95,155,0.45)';
      ctx.lineWidth   = 1;
    } else {
      ctx.fillStyle   = 'rgba(12,24,44,0.82)';
      ctx.strokeStyle = 'rgba(35,65,105,0.38)';
      ctx.lineWidth   = 1;
    }

    ctx.fill();
    ctx.stroke();
    ctx.restore();
  },

  /* ── Building dispatcher ─────────────────────────────────────────────── */
  _drawBuilding(bld, cx, cy, cs) {
    const pulse = 0.5 + 0.5 * Math.sin(this._phase + bld.id * 1.1);

    // Tier determines proportions
    const widthFrac  = 0.60 + (bld.id - 1) * 0.032;   // T1=0.60 … T10=0.89
    const heightFrac = 0.26 + (bld.id - 1) * 0.068;   // T1=0.26 … T10=0.87

    const bw  = cs * Math.min(widthFrac,  0.90);
    const bh  = cs * Math.min(heightFrac, 0.90);

    // Anchor building at bottom of cell
    const baseY = cy + cs * 0.43;
    const topY  = baseY - bh;
    const bx    = cx - bw / 2;

    const dx = this.DEPTH_X;
    const dy = this.DEPTH_Y;

    const rgb = Utils.hexToRgb(bld.color);

    // ── Drop shadow ──────────────────────────────────────────────────────
    const ctx = this.ctx;
    ctx.save();
    ctx.globalAlpha = 0.4;
    ctx.fillStyle = '#020810';
    ctx.beginPath();
    ctx.ellipse(cx + dx / 2, baseY + 5, bw * 0.52 + dx / 2, 7, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();

    // ── Right side face (darker shade) ───────────────────────────────────
    const darkR = Math.max(0, rgb.r - 65);
    const darkG = Math.max(0, rgb.g - 65);
    const darkB = Math.max(0, rgb.b - 55);
    ctx.save();
    ctx.fillStyle = `rgb(${darkR},${darkG},${darkB})`;
    ctx.beginPath();
    ctx.moveTo(bx + bw,      topY);           // front-top-right
    ctx.lineTo(bx + bw + dx, topY - dy);      // back-top-right
    ctx.lineTo(bx + bw + dx, baseY - dy);     // back-bottom-right
    ctx.lineTo(bx + bw,      baseY);          // front-bottom-right
    ctx.closePath();
    ctx.fill();
    ctx.restore();

    // ── Front face ───────────────────────────────────────────────────────
    ctx.save();
    const faceLt = `rgb(${Math.min(255,rgb.r+45)},${Math.min(255,rgb.g+45)},${Math.min(255,rgb.b+45)})`;
    const faceDk = `rgb(${Math.max(0,rgb.r-25)},${Math.max(0,rgb.g-25)},${Math.max(0,rgb.b-25)})`;
    const faceGrad = ctx.createLinearGradient(bx, topY, bx + bw, topY + bh);
    faceGrad.addColorStop(0,   faceLt);
    faceGrad.addColorStop(0.55, bld.color);
    faceGrad.addColorStop(1,   faceDk);
    ctx.fillStyle   = faceGrad;
    ctx.shadowColor = bld.color;
    ctx.shadowBlur  = 6 + 5 * pulse;
    ctx.fillRect(bx, topY, bw, bh);

    // Thin outline for crisp edge
    ctx.strokeStyle = `rgba(${rgb.r},${rgb.g},${rgb.b},0.55)`;
    ctx.lineWidth   = 1;
    ctx.strokeRect(bx, topY, bw, bh);
    ctx.restore();

    // ── Roof face ────────────────────────────────────────────────────────
    const roofR = Math.min(255, rgb.r + 30);
    const roofG = Math.min(255, rgb.g + 30);
    const roofB = Math.min(255, rgb.b + 30);
    ctx.save();
    ctx.fillStyle = `rgb(${roofR},${roofG},${roofB})`;
    ctx.beginPath();
    ctx.moveTo(bx,           topY);           // front-left
    ctx.lineTo(bx + bw,      topY);           // front-right
    ctx.lineTo(bx + bw + dx, topY - dy);      // back-right
    ctx.lineTo(bx      + dx, topY - dy);      // back-left
    ctx.closePath();
    ctx.fill();
    // Roof outline
    ctx.strokeStyle = `rgba(${roofR},${roofG},${roofB},0.5)`;
    ctx.lineWidth   = 0.5;
    ctx.stroke();
    ctx.restore();

    // ── Floor dividers (horizontal bands) ────────────────────────────────
    const floors = Math.min(bld.id + 1, 8);
    if (bh > 18 && floors > 1) {
      ctx.save();
      ctx.strokeStyle = `rgba(0,0,0,0.18)`;
      ctx.lineWidth   = 0.8;
      const fh = bh / floors;
      for (let f = 1; f < floors; f++) {
        ctx.beginPath();
        ctx.moveTo(bx,      topY + f * fh);
        ctx.lineTo(bx + bw, topY + f * fh);
        ctx.stroke();
      }
      ctx.restore();
    }

    // ── Windows ──────────────────────────────────────────────────────────
    this._drawWindows(bx, topY, bw, bh, bld.id, rgb, pulse);

    // ── Rooftop element ──────────────────────────────────────────────────
    this._drawRooftop(bld, cx, topY, dy, bw, cs, pulse);

    // ── Tier badge ───────────────────────────────────────────────────────
    this._drawBadge(bld, bx + 3, baseY - 15, cs);
  },

  /* ── Windows ──────────────────────────────────────────────────────────── */
  _drawWindows(bx, topY, bw, bh, tier, rgb, pulse) {
    const ctx    = this.ctx;
    const wins   = Math.min(tier + 1, 5);
    const floors = Math.min(Math.ceil(tier * 0.8) + 1, 7);
    if (bh < 14 || wins < 1 || floors < 1) return;

    const pad  = Math.max(3, bw * 0.09);
    const winW = Math.max(2, (bw - pad * (wins + 1)) / wins);
    const fh   = bh / (floors + 1);
    const winH = Math.max(2, fh * 0.48);

    // Window flicker constants
    const WIN_FLICKER_SPEED = 1.8;     // animation phase multiplier
    const WIN_FLICKER_ROW   = 1.4;     // per-floor phase offset
    const WIN_FLICKER_COL   = 0.95;    // per-window phase offset
    const WIN_FLICKER_ON    = 0.3;     // threshold above which window is fully lit
    const WIN_FLICKER_DIM   = 0.65;    // brightness when window is dimmed

    for (let f = 0; f < floors; f++) {
      for (let w = 0; w < wins; w++) {
        const wx = bx + pad + w * (winW + pad);
        const wy = topY + pad * 0.5 + f * fh + fh * 0.28;
        // Animated window brightness — varies per floor/column position
        const lit     = Math.sin(this._phase * WIN_FLICKER_SPEED + f * WIN_FLICKER_ROW + w * WIN_FLICKER_COL) > WIN_FLICKER_ON;
        const flicker = lit ? 1 : WIN_FLICKER_DIM;
        const alpha   = (0.55 + 0.35 * pulse) * flicker;
        const wr = Math.min(255, rgb.r + 90);
        const wg = Math.min(255, rgb.g + 90);
        const wb = Math.min(255, rgb.b + 90);
        ctx.fillStyle = `rgba(${wr},${wg},${wb},${Utils.clamp(alpha, 0.25, 1)})`;
        ctx.fillRect(wx, wy, winW, winH);
      }
    }
  },

  /* ── Per-tier rooftop elements ───────────────────────────────────────── */
  _drawRooftop(bld, cx, topY, dy, bw, cs, pulse) {
    const ctx = this.ctx;
    const ry  = topY - dy;           // roof center y (on the roof face)
    const rgb = Utils.hexToRgb(bld.color);
    const bright = `rgb(${Math.min(255,rgb.r+90)},${Math.min(255,rgb.g+90)},${Math.min(255,rgb.b+90)})`;

    ctx.save();
    ctx.shadowColor = bld.color;
    ctx.shadowBlur  = 10 + 7 * pulse;

    switch (bld.id) {

      case 1: // Нано-Под — single blinking antenna
        ctx.strokeStyle = bright;
        ctx.lineWidth   = 2;
        ctx.beginPath();
        ctx.moveTo(cx, topY);
        ctx.lineTo(cx, topY - cs * 0.12);
        ctx.stroke();
        ctx.fillStyle = pulse > 0.5 ? bright : 'rgba(255,255,255,0.3)';
        ctx.beginPath();
        ctx.arc(cx, topY - cs * 0.12, 3, 0, Math.PI * 2);
        ctx.fill();
        break;

      case 2: // Дата-Узел — two small antennas
        [-bw * 0.18, bw * 0.18].forEach(dx => {
          ctx.strokeStyle = bright;
          ctx.lineWidth   = 1.5;
          ctx.beginPath();
          ctx.moveTo(cx + dx, topY);
          ctx.lineTo(cx + dx, topY - cs * 0.13);
          ctx.stroke();
          ctx.fillStyle = bright;
          ctx.beginPath();
          ctx.arc(cx + dx, topY - cs * 0.13, 2.5, 0, Math.PI * 2);
          ctx.fill();
        });
        break;

      case 3: // Нейро-Ячейка — small dome
        ctx.fillStyle   = `rgba(${rgb.r},${rgb.g},${rgb.b},0.45)`;
        ctx.strokeStyle = bright;
        ctx.lineWidth   = 1.5;
        ctx.beginPath();
        ctx.arc(cx, topY - 1, bw * 0.2, Math.PI, 0);
        ctx.closePath();
        ctx.fill();
        ctx.stroke();
        break;

      case 4: // Квантум-Хаб — glowing orb
        ctx.fillStyle = `rgba(${rgb.r},${rgb.g},${rgb.b},0.25)`;
        ctx.beginPath();
        ctx.arc(cx, topY - cs * 0.06, bw * 0.2, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = bright;
        ctx.beginPath();
        ctx.arc(cx, topY - cs * 0.06, bw * 0.08, 0, Math.PI * 2);
        ctx.fill();
        break;

      case 5: // Голо-Башня — holographic ring + antenna
        ctx.strokeStyle = `rgba(${rgb.r},${rgb.g},${rgb.b},${0.5 + 0.3 * pulse})`;
        ctx.lineWidth   = 1.8;
        ctx.beginPath();
        ctx.ellipse(cx, topY - cs * 0.07, bw * 0.25, cs * 0.04, 0, 0, Math.PI * 2);
        ctx.stroke();
        ctx.strokeStyle = bright;
        ctx.lineWidth   = 2;
        ctx.beginPath();
        ctx.moveTo(cx, topY);
        ctx.lineTo(cx, topY - cs * 0.14);
        ctx.stroke();
        ctx.fillStyle = bright;
        ctx.beginPath();
        ctx.arc(cx, topY - cs * 0.14, 3.5, 0, Math.PI * 2);
        ctx.fill();
        break;

      case 6: // ИИ-Ядро — dome + central glow
        ctx.fillStyle   = `rgba(${rgb.r},${rgb.g},${rgb.b},0.4)`;
        ctx.strokeStyle = bright;
        ctx.lineWidth   = 2;
        ctx.beginPath();
        ctx.arc(cx, topY - 1, bw * 0.27, Math.PI, 0);
        ctx.closePath();
        ctx.fill();
        ctx.stroke();
        ctx.fillStyle = bright;
        ctx.beginPath();
        ctx.arc(cx, topY - bw * 0.12, 4.5, 0, Math.PI * 2);
        ctx.fill();
        break;

      case 7: // Кибер-Нексус — triangular spire
        ctx.fillStyle = bright;
        ctx.beginPath();
        ctx.moveTo(cx - bw * 0.08, topY);
        ctx.lineTo(cx + bw * 0.08, topY);
        ctx.lineTo(cx,             topY - cs * 0.2);
        ctx.closePath();
        ctx.fill();
        break;

      case 8: // Тех-Шпиль — tall spire with glowing tip
        ctx.strokeStyle = bright;
        ctx.lineWidth   = 2.5;
        ctx.beginPath();
        ctx.moveTo(cx, topY);
        ctx.lineTo(cx, topY - cs * 0.25);
        ctx.stroke();
        ctx.fillStyle = bright;
        ctx.beginPath();
        ctx.arc(cx, topY - cs * 0.25, 5, 0, Math.PI * 2);
        ctx.fill();
        ctx.strokeStyle = `rgba(${rgb.r},${rgb.g},${rgb.b},${0.35 + 0.3 * pulse})`;
        ctx.lineWidth   = 1.5;
        ctx.beginPath();
        ctx.arc(cx, topY - cs * 0.25, 10 + 5 * pulse, 0, Math.PI * 2);
        ctx.stroke();
        break;

      case 9: // Сингулярность — rotating orbital ring
        ctx.save();
        ctx.translate(cx, topY - cs * 0.1);
        ctx.rotate(this._phase);
        ctx.strokeStyle = bright;
        ctx.lineWidth   = 2;
        ctx.beginPath();
        ctx.arc(0, 0, bw * 0.24, 0, Math.PI * 2);
        ctx.stroke();
        // inner glow ball
        ctx.fillStyle = `rgba(${rgb.r},${rgb.g},${rgb.b},${0.5 + 0.4 * pulse})`;
        ctx.beginPath();
        ctx.arc(0, 0, bw * 0.09, 0, Math.PI * 2);
        ctx.fill();
        ctx.restore();
        break;

      case 10: // Нео-Центр — crown of 4 spires + central pulsing orb
        [-bw * 0.26, -bw * 0.09, bw * 0.09, bw * 0.26].forEach((ox, i) => {
          const h = (i === 0 || i === 3) ? cs * 0.15 : cs * 0.22;
          ctx.strokeStyle = bright;
          ctx.lineWidth   = 2;
          ctx.beginPath();
          ctx.moveTo(cx + ox, topY);
          ctx.lineTo(cx + ox, topY - h);
          ctx.stroke();
          ctx.fillStyle = bright;
          ctx.beginPath();
          ctx.arc(cx + ox, topY - h, 3.5, 0, Math.PI * 2);
          ctx.fill();
        });
        // Central orb
        ctx.fillStyle = `rgba(${rgb.r},${rgb.g},${rgb.b},${0.3 + 0.25 * pulse})`;
        ctx.beginPath();
        ctx.arc(cx, topY - cs * 0.1, bw * 0.17, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = bright;
        ctx.beginPath();
        ctx.arc(cx, topY - cs * 0.1, bw * 0.08, 0, Math.PI * 2);
        ctx.fill();
        break;
    }

    ctx.restore();
  },

  /* ── Tier badge ──────────────────────────────────────────────────────── */
  _drawBadge(bld, bx, by, cs) {
    const ctx = this.ctx;
    const { r, g, b } = Utils.hexToRgb(bld.color);
    ctx.save();
    ctx.fillStyle   = 'rgba(0,0,0,0.62)';
    ctx.strokeStyle = `rgba(${r},${g},${b},0.6)`;
    ctx.lineWidth   = 1;
    ctx.beginPath();
    ctx.roundRect(bx, by, 18, 13, 3);
    ctx.fill();
    ctx.stroke();
    ctx.fillStyle  = bld.color;
    ctx.font       = `bold 9px 'Orbitron', monospace`;
    ctx.textAlign  = 'center';
    ctx.fillText(bld.id, bx + 9, by + 10);
    ctx.restore();
  },

  /** Draw a single building for the shop preview canvas */
  drawPreview(ctx, bld, cx, cy, size) {
    const savedCtx = this.ctx;
    this.ctx = ctx;
    ctx.save();
    this._drawBuilding(bld, cx, cy + size * 0.08, size);
    ctx.restore();
    this.ctx = savedCtx;
  },
};

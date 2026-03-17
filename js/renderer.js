'use strict';

/**
 * Renderer — draws grid, buildings, drag ghost and particles onto the canvas.
 * All coordinates are in canvas-pixel space.
 */
const Renderer = {
  canvas: null,
  ctx: null,
  particles: null,

  /** Animated phase for glow pulses (0-1 loop) */
  _phase: 0,

  init(canvas, particles) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.particles = particles;
  },

  /** Main render call — invoked every animation frame */
  render(grid, drag) {
    const ctx = this.ctx;
    const W = this.canvas.width;
    const H = this.canvas.height;

    // Advance animation phase [0, 2π) — sin/cos are periodic so any float works,
    // but keeping the value bounded avoids slow float precision loss over long sessions.
    this._phase = (this._phase + 0.012) % (Math.PI * 2);

    // ── Background ────────────────────────────────────────────────────────────
    ctx.fillStyle = '#07071a';
    ctx.fillRect(0, 0, W, H);

    // Scanlines
    ctx.save();
    ctx.globalAlpha = 0.04;
    ctx.fillStyle = '#ffffff';
    for (let y = 0; y < H; y += 4) {
      ctx.fillRect(0, y, W, 2);
    }
    ctx.restore();

    // ── Grid ──────────────────────────────────────────────────────────────────
    this._drawGrid(grid, drag);

    // ── Particles (behind drag ghost) ─────────────────────────────────────────
    this.particles.draw(ctx);

    // ── Drag ghost ───────────────────────────────────────────────────────────
    if (drag && drag.building && drag.active) {
      ctx.save();
      ctx.globalAlpha = 0.65;
      this._drawBuilding(drag.building, drag.x, drag.y, CONFIG.CELL_SIZE * 0.9);
      ctx.restore();
    }
  },

  _drawGrid(grid, drag) {
    const ctx = this.ctx;
    const cs = CONFIG.CELL_SIZE;
    const cols = CONFIG.GRID_COLS;
    const rows = CONFIG.GRID_ROWS;

    for (let row = 0; row < rows; row++) {
      for (let col = 0; col < cols; col++) {
        const idx = row * cols + col;
        const cx = col * cs + cs / 2;
        const cy = row * cs + cs / 2;
        const cell = grid.cells[idx];

        // Is drag source?
        const isDragSrc = drag && drag.srcIdx === idx;
        // Is valid drop target?
        const isTarget = drag && drag.active &&
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
    const half = cs / 2 - 3;

    ctx.save();
    ctx.beginPath();
    ctx.roundRect(cx - half, cy - half, half * 2, half * 2, 8);

    if (isDragSrc) {
      ctx.fillStyle = 'rgba(0,230,255,0.07)';
      ctx.strokeStyle = 'rgba(0,230,255,0.5)';
      ctx.setLineDash([5, 5]);
    } else if (isTarget) {
      const pulse = 0.5 + 0.5 * Math.sin(this._phase * 4);
      ctx.fillStyle = `rgba(0,230,255,${0.1 + 0.1 * pulse})`;
      ctx.shadowBlur = 15 + 5 * pulse;
      ctx.shadowColor = '#00e5ff';
      ctx.strokeStyle = `rgba(0,230,255,${0.6 + 0.4 * pulse})`;
    } else if (cell) {
      const rgb = Utils.hexToRgb(cell.color);
      const pulse = 0.5 + 0.5 * Math.sin(this._phase + cell.id * 0.9);
      ctx.fillStyle = `rgba(${rgb.r},${rgb.g},${rgb.b},0.05)`;
      ctx.shadowBlur = 6 + 4 * pulse;
      ctx.shadowColor = cell.color;
      ctx.strokeStyle = `rgba(${rgb.r},${rgb.g},${rgb.b},0.35)`;
    } else {
      ctx.fillStyle = 'rgba(10,10,40,0.6)';
      ctx.strokeStyle = 'rgba(30,50,100,0.5)';
    }

    ctx.lineWidth = 1.5;
    ctx.fill();
    ctx.stroke();
    ctx.restore();
  },

  /** Draw a building centered at (cx, cy) within a cell of width `cs` */
  _drawBuilding(bld, cx, cy, cs) {
    const s = cs * 0.82; // usable drawing size
    const ctx = this.ctx;
    const pulse = 0.5 + 0.5 * Math.sin(this._phase + bld.id * 1.1);

    ctx.save();
    ctx.shadowColor = bld.color;
    ctx.shadowBlur = 14 + 8 * pulse;

    switch (bld.id) {
      case 1:  this._bldNanoPod(cx, cy, s, bld.color, pulse);   break;
      case 2:  this._bldDataNode(cx, cy, s, bld.color, pulse);  break;
      case 3:  this._bldNeuralCell(cx, cy, s, bld.color, pulse);break;
      case 4:  this._bldQuantumHub(cx, cy, s, bld.color, pulse);break;
      case 5:  this._bldHoloTower(cx, cy, s, bld.color, pulse); break;
      case 6:  this._bldAICore(cx, cy, s, bld.color, pulse);    break;
      case 7:  this._bldCyberNexus(cx, cy, s, bld.color, pulse);break;
      case 8:  this._bldTechSpire(cx, cy, s, bld.color, pulse); break;
      case 9:  this._bldSingularity(cx, cy, s, bld.color, pulse);break;
      case 10: this._bldNeoCore(cx, cy, s, bld.color, pulse);   break;
    }

    // Tier badge
    ctx.shadowBlur = 0;
    ctx.fillStyle = 'rgba(0,0,0,0.55)';
    ctx.fillRect(cx - cs / 2 + 5, cy + cs / 2 - 18, 18, 14);
    ctx.fillStyle = bld.color;
    ctx.font = `bold 10px 'Orbitron', monospace`;
    ctx.textAlign = 'center';
    ctx.fillText(bld.id, cx - cs / 2 + 14, cy + cs / 2 - 7);

    ctx.restore();
  },

  /* ── Building drawing helpers ──────────────────────────────────────────── */

  _fill(color, alpha) {
    const rgb = Utils.hexToRgb(color);
    return `rgba(${rgb.r},${rgb.g},${rgb.b},${alpha})`;
  },

  /** 1 — Nano Pod: small cube with antennas */
  _bldNanoPod(cx, cy, s, col, pulse) {
    const ctx = this.ctx;
    const w = s * 0.38, h = s * 0.48;
    const bx = cx - w / 2, by = cy - h / 2 + s * 0.08;

    ctx.fillStyle = this._fill(col, 0.18);
    ctx.strokeStyle = col;
    ctx.lineWidth = 1.8;
    ctx.beginPath();
    ctx.roundRect(bx, by, w, h, 3);
    ctx.fill();
    ctx.stroke();

    // Window
    ctx.shadowBlur = 10 + 6 * pulse;
    ctx.fillStyle = this._fill(col, 0.55 + 0.2 * pulse);
    ctx.beginPath();
    ctx.arc(cx, cy + s * 0.06, s * 0.09, 0, Math.PI * 2);
    ctx.fill();

    // Antennas
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.moveTo(cx - w * 0.3, by);
    ctx.lineTo(cx - w * 0.4, by - s * 0.15);
    ctx.moveTo(cx + w * 0.2, by);
    ctx.lineTo(cx + w * 0.3, by - s * 0.12);
    ctx.stroke();
    ctx.fillStyle = col;
    ctx.beginPath();
    ctx.arc(cx - w * 0.4, by - s * 0.15, 2.5, 0, Math.PI * 2);
    ctx.arc(cx + w * 0.3, by - s * 0.12, 2, 0, Math.PI * 2);
    ctx.fill();
  },

  /** 2 — Data Node: cube with circuit lines */
  _bldDataNode(cx, cy, s, col, pulse) {
    const ctx = this.ctx;
    const w = s * 0.46, h = s * 0.52;
    const bx = cx - w / 2, by = cy - h / 2 + s * 0.06;

    ctx.fillStyle = this._fill(col, 0.16);
    ctx.strokeStyle = col;
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.roundRect(bx, by, w, h, 4);
    ctx.fill();
    ctx.stroke();

    // Circuit lines
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(bx + w * 0.2, by + h * 0.3);
    ctx.lineTo(bx + w * 0.8, by + h * 0.3);
    ctx.moveTo(bx + w * 0.2, by + h * 0.55);
    ctx.lineTo(bx + w * 0.8, by + h * 0.55);
    ctx.moveTo(cx, by + h * 0.3);
    ctx.lineTo(cx, by + h * 0.55);
    ctx.stroke();

    // Glowing node
    ctx.shadowBlur = 12 + 8 * pulse;
    ctx.fillStyle = this._fill(col, 0.7 + 0.2 * pulse);
    ctx.beginPath();
    ctx.arc(cx, by + h * 0.42, s * 0.07, 0, Math.PI * 2);
    ctx.fill();
  },

  /** 3 — Neural Cell: hexagon with node connections */
  _bldNeuralCell(cx, cy, s, col, pulse) {
    const ctx = this.ctx;
    const r = s * 0.32;
    const offset = s * 0.04;

    // Hexagon
    ctx.fillStyle = this._fill(col, 0.14);
    ctx.strokeStyle = col;
    ctx.lineWidth = 2;
    ctx.beginPath();
    for (let i = 0; i < 6; i++) {
      const a = (Math.PI / 3) * i - Math.PI / 6;
      const x = cx + Math.cos(a) * r;
      const y = cy + offset + Math.sin(a) * r;
      i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
    }
    ctx.closePath();
    ctx.fill();
    ctx.stroke();

    // Neural connections
    ctx.lineWidth = 1;
    const nodes = [];
    for (let i = 0; i < 6; i++) {
      const a = (Math.PI / 3) * i - Math.PI / 6;
      nodes.push({ x: cx + Math.cos(a) * r * 0.65, y: cy + offset + Math.sin(a) * r * 0.65 });
    }
    ctx.strokeStyle = this._fill(col, 0.4);
    ctx.beginPath();
    for (let i = 0; i < nodes.length; i++) {
      for (let j = i + 2; j < nodes.length; j++) {
        ctx.moveTo(nodes[i].x, nodes[i].y);
        ctx.lineTo(nodes[j].x, nodes[j].y);
      }
    }
    ctx.stroke();

    // Center glow
    ctx.shadowBlur = 14 + 8 * pulse;
    ctx.fillStyle = this._fill(col, 0.8);
    ctx.beginPath();
    ctx.arc(cx, cy + offset, s * 0.07, 0, Math.PI * 2);
    ctx.fill();
  },

  /** 4 — Quantum Hub: two blocks with quantum ring */
  _bldQuantumHub(cx, cy, s, col, pulse) {
    const ctx = this.ctx;
    const blockW = s * 0.28, blockH = s * 0.36;
    const gap = s * 0.1;
    const baseY = cy - blockH / 2 + s * 0.1;

    [-1, 1].forEach(side => {
      const bx = cx + side * (blockW / 2 + gap / 2) - blockW / 2;
      ctx.fillStyle = this._fill(col, 0.15);
      ctx.strokeStyle = col;
      ctx.lineWidth = 1.8;
      ctx.beginPath();
      ctx.roundRect(bx, baseY, blockW, blockH, 4);
      ctx.fill();
      ctx.stroke();
    });

    // Bridge
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(cx - gap / 2, cy + s * 0.05);
    ctx.lineTo(cx + gap / 2, cy + s * 0.05);
    ctx.stroke();

    // Quantum ring (ellipse)
    ctx.shadowBlur = 14 + 8 * pulse;
    ctx.strokeStyle = this._fill(col, 0.7 + 0.25 * pulse);
    ctx.lineWidth = 2;
    const rx = s * 0.26 + s * 0.04 * Math.sin(this._phase * 2);
    const ry = s * 0.09;
    ctx.beginPath();
    ctx.ellipse(cx, cy + s * 0.05, rx, ry, 0, 0, Math.PI * 2);
    ctx.stroke();

    // Center node
    ctx.fillStyle = this._fill(col, 0.9);
    ctx.beginPath();
    ctx.arc(cx, cy + s * 0.05, s * 0.055, 0, Math.PI * 2);
    ctx.fill();
  },

  /** 5 — Holo Tower: tall slim tower with floors */
  _bldHoloTower(cx, cy, s, col, pulse) {
    const ctx = this.ctx;
    const w = s * 0.22, h = s * 0.7;
    const bx = cx - w / 2, by = cy - h / 2 + s * 0.04;

    // Tower body
    ctx.fillStyle = this._fill(col, 0.14);
    ctx.strokeStyle = col;
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.roundRect(bx, by, w, h, 4);
    ctx.fill();
    ctx.stroke();

    // Floor bands
    ctx.lineWidth = 1;
    ctx.strokeStyle = this._fill(col, 0.5);
    [0.3, 0.55, 0.75].forEach(frac => {
      ctx.beginPath();
      ctx.moveTo(bx + 2, by + h * frac);
      ctx.lineTo(bx + w - 2, by + h * frac);
      ctx.stroke();
    });

    // Holographic rings (animated)
    ctx.strokeStyle = this._fill(col, 0.35 + 0.2 * pulse);
    ctx.lineWidth = 1.2;
    [0.15, 0.4, 0.65].forEach((frac, i) => {
      const rw = (w * 0.9 + s * 0.06 * Math.sin(this._phase * 3 + i)) / 2;
      ctx.beginPath();
      ctx.ellipse(cx, by + h * frac, rw, rw * 0.28, 0, 0, Math.PI * 2);
      ctx.stroke();
    });

    // Antenna light
    ctx.shadowBlur = 16 + 8 * pulse;
    ctx.fillStyle = this._fill(col, 0.9 + 0.1 * pulse);
    ctx.beginPath();
    ctx.arc(cx, by - 3, 4, 0, Math.PI * 2);
    ctx.fill();
  },

  /** 6 — AI Core: dome with orbital ring */
  _bldAICore(cx, cy, s, col, pulse) {
    const ctx = this.ctx;
    const r = s * 0.3;
    const baseY = cy + s * 0.14;

    // Dome
    ctx.fillStyle = this._fill(col, 0.13);
    ctx.strokeStyle = col;
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.arc(cx, baseY, r, Math.PI, 0);
    ctx.lineTo(cx + r, baseY);
    ctx.lineTo(cx - r, baseY);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();

    // Base platform
    ctx.fillStyle = this._fill(col, 0.25);
    ctx.beginPath();
    ctx.roundRect(cx - r * 1.1, baseY, r * 2.2, r * 0.22, 4);
    ctx.fill();
    ctx.stroke();

    // Orbital ring (animated tilt)
    const angle = this._phase * 1.5;
    ctx.save();
    ctx.translate(cx, baseY - r * 0.4);
    ctx.rotate(Math.sin(angle) * 0.3);
    ctx.scale(1, 0.3);
    ctx.shadowBlur = 14 + 8 * pulse;
    ctx.strokeStyle = this._fill(col, 0.7 + 0.25 * pulse);
    ctx.lineWidth = 2.5;
    ctx.beginPath();
    ctx.arc(0, 0, r * 0.9, 0, Math.PI * 2);
    ctx.stroke();
    ctx.restore();

    // Core glow
    ctx.shadowBlur = 18 + 10 * pulse;
    ctx.fillStyle = this._fill(col, 0.85);
    ctx.beginPath();
    ctx.arc(cx, baseY - r * 0.4, s * 0.07, 0, Math.PI * 2);
    ctx.fill();
  },

  /** 7 — Cyber Nexus: two towers with bridge */
  _bldCyberNexus(cx, cy, s, col, pulse) {
    const ctx = this.ctx;
    const tw = s * 0.22, th = s * 0.58;
    const sep = s * 0.26;
    const baseY = cy - th / 2 + s * 0.06;

    [-1, 1].forEach(side => {
      const tx = cx + side * sep - tw / 2;
      ctx.fillStyle = this._fill(col, 0.15);
      ctx.strokeStyle = col;
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.roundRect(tx, baseY, tw, th, 4);
      ctx.fill();
      ctx.stroke();
      // Windows
      ctx.fillStyle = this._fill(col, 0.5 + 0.2 * pulse);
      [0.2, 0.45, 0.65].forEach(f => {
        ctx.beginPath();
        ctx.roundRect(tx + tw * 0.2, baseY + th * f, tw * 0.6, th * 0.1, 2);
        ctx.fill();
      });
    });

    // Bridge
    const bridgeY = cy - th * 0.1;
    ctx.fillStyle = this._fill(col, 0.22);
    ctx.strokeStyle = col;
    ctx.lineWidth = 1.8;
    ctx.beginPath();
    ctx.roundRect(cx - sep + tw / 2, bridgeY - 6, sep * 2 - tw, 12, 3);
    ctx.fill();
    ctx.stroke();

    // Energy beam on bridge
    ctx.shadowBlur = 12 + 8 * pulse;
    ctx.strokeStyle = this._fill(col, 0.7 + 0.25 * pulse);
    ctx.lineWidth = 2.5;
    ctx.beginPath();
    ctx.moveTo(cx - sep + tw / 2, bridgeY);
    ctx.lineTo(cx + sep - tw / 2, bridgeY);
    ctx.stroke();
  },

  /** 8 — Tech Spire: ultra-tall tapering spire */
  _bldTechSpire(cx, cy, s, col, pulse) {
    const ctx = this.ctx;
    const baseW = s * 0.36, topW = s * 0.08;
    const h = s * 0.76;
    const bx = cx - baseW / 2, by = cy - h / 2 + s * 0.03;

    // Trapezoid body
    ctx.fillStyle = this._fill(col, 0.14);
    ctx.strokeStyle = col;
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(bx, by + h);
    ctx.lineTo(bx + baseW, by + h);
    ctx.lineTo(cx + topW / 2, by);
    ctx.lineTo(cx - topW / 2, by);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();

    // Tech panels
    ctx.strokeStyle = this._fill(col, 0.4);
    ctx.lineWidth = 1;
    [0.25, 0.5, 0.72].forEach(f => {
      const y = by + h * f;
      const pw = baseW * (1 - f) + topW * f;
      ctx.beginPath();
      ctx.moveTo(cx - pw / 2, y);
      ctx.lineTo(cx + pw / 2, y);
      ctx.stroke();
    });

    // Spire tip glow
    ctx.shadowBlur = 20 + 10 * pulse;
    ctx.fillStyle = this._fill(col, 0.9 + 0.1 * pulse);
    ctx.beginPath();
    ctx.arc(cx, by - 2, 5, 0, Math.PI * 2);
    ctx.fill();
    // Secondary glow ring
    ctx.strokeStyle = this._fill(col, 0.35 + 0.25 * pulse);
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.arc(cx, by - 2, 10 + 4 * pulse, 0, Math.PI * 2);
    ctx.stroke();
  },

  /** 9 — Singularity: vortex / portal */
  _bldSingularity(cx, cy, s, col, pulse) {
    const ctx = this.ctx;
    const r = s * 0.34;
    const offset = s * 0.03;
    const phase = this._phase;

    // Outer glow ring
    ctx.shadowBlur = 22 + 12 * pulse;
    ctx.strokeStyle = this._fill(col, 0.5 + 0.3 * pulse);
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.arc(cx, cy + offset, r, 0, Math.PI * 2);
    ctx.stroke();

    // Spiral arms (3 arms)
    ctx.lineWidth = 2;
    for (let arm = 0; arm < 3; arm++) {
      const armPhase = phase + (arm * Math.PI * 2) / 3;
      ctx.strokeStyle = this._fill(col, 0.6 + 0.2 * pulse);
      ctx.beginPath();
      for (let t = 0; t <= 1; t += 0.05) {
        const a = armPhase + t * Math.PI * 1.8;
        const rr = r * 0.9 * t;
        const x = cx + Math.cos(a) * rr;
        const y = cy + offset + Math.sin(a) * rr;
        t === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
      }
      ctx.stroke();
    }

    // Inner rings
    [0.5, 0.25].forEach((scale, i) => {
      ctx.strokeStyle = this._fill(col, 0.3 + 0.2 * i + 0.1 * pulse);
      ctx.lineWidth = 1.5;
      ctx.beginPath();
      ctx.arc(cx, cy + offset, r * scale, 0, Math.PI * 2);
      ctx.stroke();
    });

    // Core
    ctx.shadowBlur = 24 + 14 * pulse;
    ctx.fillStyle = this._fill(col, 1);
    ctx.beginPath();
    ctx.arc(cx, cy + offset, s * 0.07, 0, Math.PI * 2);
    ctx.fill();
  },

  /** 10 — Neo Core: ultimate mega complex */
  _bldNeoCore(cx, cy, s, col, pulse) {
    const ctx = this.ctx;
    const mainR = s * 0.28;
    const offset = s * 0.05;
    const phase = this._phase;

    // Surrounding mini towers (4)
    const towerR = mainR * 0.72;
    for (let i = 0; i < 4; i++) {
      const a = (Math.PI / 2) * i + Math.PI / 4;
      const tx = cx + Math.cos(a) * towerR;
      const ty = cy + offset + Math.sin(a) * towerR;
      const tw = s * 0.13, th = s * 0.28;
      ctx.fillStyle = this._fill(col, 0.18);
      ctx.strokeStyle = col;
      ctx.lineWidth = 1.5;
      ctx.beginPath();
      ctx.roundRect(tx - tw / 2, ty - th / 2, tw, th, 3);
      ctx.fill();
      ctx.stroke();
    }

    // Main dome
    ctx.shadowBlur = 20 + 10 * pulse;
    ctx.fillStyle = this._fill(col, 0.16);
    ctx.strokeStyle = col;
    ctx.lineWidth = 2.5;
    ctx.beginPath();
    ctx.arc(cx, cy + offset, mainR, Math.PI, 0);
    ctx.lineTo(cx + mainR, cy + offset);
    ctx.lineTo(cx - mainR, cy + offset);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();

    // Base platform
    ctx.fillStyle = this._fill(col, 0.28);
    ctx.beginPath();
    ctx.roundRect(cx - mainR * 1.1, cy + offset, mainR * 2.2, mainR * 0.25, 4);
    ctx.fill();
    ctx.stroke();

    // Dual orbital rings (animated)
    [1, -1].forEach((dir, i) => {
      ctx.save();
      ctx.translate(cx, cy + offset - mainR * 0.35);
      ctx.rotate(phase * dir * 0.8 + i * Math.PI / 3);
      ctx.scale(1, 0.35);
      ctx.shadowBlur = 16 + 8 * pulse;
      ctx.strokeStyle = this._fill(col, 0.6 + 0.25 * pulse);
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.arc(0, 0, mainR * 0.82, 0, Math.PI * 2);
      ctx.stroke();
      ctx.restore();
    });

    // Energy pulses radiating outward
    const pulseRad = mainR * (0.4 + 0.6 * ((phase * 0.6) % 1));
    ctx.strokeStyle = this._fill(col, 0.3 * (1 - (phase * 0.6) % 1));
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.arc(cx, cy + offset - mainR * 0.35, pulseRad, 0, Math.PI * 2);
    ctx.stroke();

    // Core glow
    ctx.shadowBlur = 28 + 16 * pulse;
    ctx.fillStyle = this._fill(col, 1);
    ctx.beginPath();
    ctx.arc(cx, cy + offset - mainR * 0.35, s * 0.085, 0, Math.PI * 2);
    ctx.fill();
  },

  /** Draw a single building scaled to `size` for shop preview */
  drawPreview(ctx, bld, cx, cy, size) {
    const saved = this.ctx;
    this.ctx = ctx;
    ctx.save();
    ctx.shadowColor = bld.color;
    ctx.shadowBlur = 10;
    this._drawBuilding(bld, cx, cy, size);
    ctx.restore();
    this.ctx = saved;
  },
};

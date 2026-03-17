'use strict';

class ParticleSystem {
  constructor() {
    this.particles = [];
  }

  /** Burst of sparks at canvas position (cx, cy) */
  addMerge(cx, cy, color) {
    const rgb = Utils.hexToRgb(color);
    // Radial burst
    for (let i = 0; i < 24; i++) {
      const angle = (Math.PI * 2 / 24) * i + (Math.random() - 0.5) * 0.4;
      const speed = 2.5 + Math.random() * 4.5;
      this.particles.push({
        x: cx, y: cy,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        r: rgb.r, g: rgb.g, b: rgb.b,
        alpha: 1,
        size: 2.5 + Math.random() * 3,
        life: 0,
        maxLife: 35 + Math.random() * 25,
        type: 'spark',
      });
    }
    // Glow flash
    this.particles.push({
      x: cx, y: cy, vx: 0, vy: 0,
      r: rgb.r, g: rgb.g, b: rgb.b,
      alpha: 0.9, size: 55,
      life: 0, maxLife: 18,
      type: 'flash',
    });
  }

  /** Floating income text */
  addIncome(cx, cy, amount, color) {
    this.particles.push({
      x: cx, y: cy,
      vx: (Math.random() - 0.5) * 0.8,
      vy: -1.8 - Math.random() * 0.8,
      color,
      alpha: 1,
      fontSize: 13,
      text: '+' + Utils.formatNumber(amount),
      life: 0,
      maxLife: 65,
      type: 'text',
    });
  }

  /** Floating credits earned popup (larger text) */
  addReward(cx, cy, amount) {
    this.particles.push({
      x: cx, y: cy,
      vx: 0, vy: -1.5,
      color: '#ffd740',
      alpha: 1,
      fontSize: 18,
      text: '+' + Utils.formatNumber(amount) + ' 💎',
      life: 0,
      maxLife: 90,
      type: 'text',
    });
  }

  update() {
    for (let i = this.particles.length - 1; i >= 0; i--) {
      const p = this.particles[i];
      p.life++;
      p.x += p.vx;
      p.y += p.vy;
      const t = p.life / p.maxLife;

      if (p.type === 'spark') {
        p.vx *= 0.93;
        p.vy *= 0.93;
        p.alpha = Utils.easeOut(1 - t);
      } else if (p.type === 'flash') {
        p.alpha = (1 - t) * 0.85;
        p.size *= 1.08;
      } else if (p.type === 'text') {
        p.alpha = t < 0.5 ? 1 : 1 - (t - 0.5) * 2;
      }

      if (p.life >= p.maxLife) {
        this.particles.splice(i, 1);
      }
    }
  }

  draw(ctx) {
    for (const p of this.particles) {
      ctx.save();
      ctx.globalAlpha = Utils.clamp(p.alpha, 0, 1);

      if (p.type === 'spark') {
        ctx.shadowBlur = 8;
        ctx.shadowColor = `rgb(${p.r},${p.g},${p.b})`;
        ctx.fillStyle = `rgb(${p.r},${p.g},${p.b})`;
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
        ctx.fill();
      } else if (p.type === 'flash') {
        const grad = ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, p.size);
        grad.addColorStop(0, `rgba(${p.r},${p.g},${p.b},0.6)`);
        grad.addColorStop(1, `rgba(${p.r},${p.g},${p.b},0)`);
        ctx.fillStyle = grad;
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
        ctx.fill();
      } else if (p.type === 'text') {
        ctx.shadowBlur = 10;
        ctx.shadowColor = p.color;
        ctx.fillStyle = p.color;
        ctx.font = `bold ${p.fontSize}px 'Orbitron', monospace`;
        ctx.textAlign = 'center';
        ctx.fillText(p.text, p.x, p.y);
      }

      ctx.restore();
    }
  }
}

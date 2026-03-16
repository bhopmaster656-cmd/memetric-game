/* ===========================
   MEMETRIC – Geometry Dash Style
   Yandex Games Edition
   =========================== */

'use strict';

// ───── Yandex SDK ────────────────────────────────────────────────────────────
let ysdk = null;
let yPlayer = null;
let yPayments = null;
let yLeaderboard = null;
let sdkReady = false;

async function initSDK() {
  try {
    ysdk = await YaGames.init();
    sdkReady = true;
    try { yPlayer = await ysdk.getPlayer({ scopes: false }); } catch (_) { yPlayer = null; }
    try { yPayments = await ysdk.getPayments({ signed: true }); } catch (_) { yPayments = null; }
    try { yLeaderboard = await ysdk.getLeaderboards(); } catch (_) { yLeaderboard = null; }
    if (yPayments) {
      try { const ps = await yPayments.getPurchases(); ps.forEach(p => applyPurchase(p.productID, false)); } catch (_) {}
    }
    loadPlayerData();
  } catch (e) {
    sdkReady = false;
    loadPlayerData();
  }
}

// ───── Persistence ────────────────────────────────────────────────────────────
const SAVE_KEY = 'memetric_save';

const DEFAULT_SAVE = {
  coins: 0,
  highscore: 0,
  ownedSkins: ['default'],
  equippedSkin: 'default',
  attempts: 0,
};

let saveData = { ...DEFAULT_SAVE };

async function loadPlayerData() {
  if (yPlayer) {
    try {
      const d = await yPlayer.getData(['coins', 'highscore', 'ownedSkins', 'equippedSkin', 'attempts']);
      if (d && Object.keys(d).length) {
        saveData = { ...DEFAULT_SAVE, ...d };
        if (!Array.isArray(saveData.ownedSkins)) saveData.ownedSkins = ['default'];
      } else {
        const local = localStorage.getItem(SAVE_KEY);
        if (local) saveData = { ...DEFAULT_SAVE, ...JSON.parse(local) };
      }
    } catch (_) {
      const local = localStorage.getItem(SAVE_KEY);
      if (local) saveData = { ...DEFAULT_SAVE, ...JSON.parse(local) };
    }
  } else {
    const local = localStorage.getItem(SAVE_KEY);
    if (local) saveData = { ...DEFAULT_SAVE, ...JSON.parse(local) };
  }
  updateMenuUI();
}

async function savePlayerData() {
  try { localStorage.setItem(SAVE_KEY, JSON.stringify(saveData)); } catch (_) {}
  if (yPlayer) {
    try { await yPlayer.setData(saveData, true); } catch (_) {}
  }
}

// ───── Shop Catalog ───────────────────────────────────────────────────────────
const SKINS = [
  { id: 'default',   name: 'Дефолт',    emoji: '😎', price: 0,    color: '#ff00ff' },
  { id: 'nyan',      name: 'Нян Кэт',   emoji: '🌈', price: 200,  color: '#ff88ff' },
  { id: 'doge',      name: 'Доге',      emoji: '🐕', price: 350,  color: '#ffcc00' },
  { id: 'trollface', name: 'Троллфейс', emoji: '😈', price: 500,  color: '#ff4400' },
  { id: 'pepe',      name: 'Пепе',      emoji: '🐸', price: 500,  color: '#00ff88' },
  { id: 'bonk',      name: 'Бонк',      emoji: '🔨', price: 750,  color: '#ff0055' },
  { id: 'chad',      name: 'Чад',       emoji: '😤', price: 1000, color: '#00ccff' },
  { id: 'sparkle',   name: 'Спаркл',    emoji: '✨', price: 1200, color: '#ffffff' },
];

const COIN_PACKS = [
  { id: 'coins_small',  label: '🪙 × 100',  sub: 'Стартовый набор', coins: 100,  price: '15 ₽' },
  { id: 'coins_medium', label: '🪙 × 500',  sub: 'Выгодный набор',  coins: 500,  price: '49 ₽' },
  { id: 'coins_large',  label: '🪙 × 1500', sub: 'Большой набор',   coins: 1500, price: '99 ₽' },
  { id: 'coins_mega',   label: '🪙 × 5000', sub: 'Мега набор',      coins: 5000, price: '249 ₽' },
];

function applyPurchase(productID, notify) {
  const pack = COIN_PACKS.find(p => p.id === productID);
  if (!pack) return;
  saveData.coins += pack.coins;
  saveData.coins = Math.min(saveData.coins, 99999);
  savePlayerData();
  updateShopUI();
  if (notify) showNotification(`+${pack.coins} монет получено!`);
}

// ───── Canvas / Game State ────────────────────────────────────────────────────
const canvas = document.getElementById('game-canvas');
const ctx = canvas.getContext('2d');

let W = 0, H = 0;
let dpr = 1;
let gameState = 'loading';

function resizeCanvas() {
  dpr = Math.min(window.devicePixelRatio || 1, 2);
  W = window.innerWidth;
  H = window.innerHeight;
  canvas.width  = W * dpr;
  canvas.height = H * dpr;
  canvas.style.width  = W + 'px';
  canvas.style.height = H + 'px';
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
}
window.addEventListener('resize', resizeCanvas);
resizeCanvas();

// ══════════════════════════════════════════════════════════════════════════════
//  GEOMETRY DASH STYLE ENGINE
// ══════════════════════════════════════════════════════════════════════════════

const PLAYER_SIZE   = 46;
const GROUND_Y_FRAC = 0.80;
const CEIL_Y_FRAC   = 0.06;
const GRAVITY       = 0.58;
const JUMP_V        = -14.5;
const DJUMP_V       = -12.0;
const ORB_V         = -17.5;
const PAD_V         = -20.5;
const SPEED_INIT    = 5.5;
const SPEED_MAX     = 15.0;
const SPEED_INC     = 0.0012;

// ─── Zone colour themes ───────────────────────────────────────────────────────
const ZONES = [
  { name: 'ПУРПУРНАЯ ЗОНА',
    bg1: '#0d0020', bg2: '#1a003a', acc: '#ff00ff', acc2: '#8800ff',
    bld: 'rgba(80,0,120,0.35)',  gnd: '#ff00ff', coin: '#ffe000' },
  { name: 'КИБЕР ЗОНА',
    bg1: '#001a1a', bg2: '#002525', acc: '#00ffff', acc2: '#0088ff',
    bld: 'rgba(0,80,120,0.35)', gnd: '#00ffff', coin: '#00ffaa' },
  { name: 'ОГНЕННАЯ ЗОНА',
    bg1: '#1a0500', bg2: '#2a0a00', acc: '#ff6600', acc2: '#ff0000',
    bld: 'rgba(120,30,0,0.35)', gnd: '#ff6600', coin: '#ffcc00' },
  { name: 'ЗОЛОТАЯ ЗОНА',
    bg1: '#1a1200', bg2: '#2a2000', acc: '#ffcc00', acc2: '#ff8800',
    bld: 'rgba(80,60,0,0.35)',  gnd: '#ffcc00', coin: '#ffffff' },
  { name: 'РАДУГА ЗОНА',
    bg1: '#05000f', bg2: '#0a0030', acc: '#ff00aa', acc2: '#aa00ff',
    bld: 'rgba(60,0,100,0.35)', gnd: '#ff00aa', coin: '#ffe000' },
];

// ─── Obstacle chunk patterns ──────────────────────────────────────────────────
const CHUNKS = [
  // easy
  { diff: 0, items: [{ t: 'spike', dx: 0 }] },
  { diff: 0, items: [{ t: 'spike', dx: 0 }, { t: 'spike', dx: 40 }] },
  { diff: 0, items: [{ t: 'block', dx: 0, w: 50, h: 52 }] },
  { diff: 0, items: [{ t: 'pad',   dx: 0 }] },
  { diff: 0, items: [{ t: 'pad',   dx: 0 }, { t: 'spike', dx: 210 }] },
  // medium
  { diff: 1, items: [{ t: 'spike', dx: 0 }, { t: 'spike', dx: 40 }, { t: 'spike', dx: 80 }] },
  { diff: 1, items: [{ t: 'block', dx: 0, w: 50, h: 88 }] },
  { diff: 1, items: [{ t: 'orb',   dx: 0, dyup: 120 }] },
  { diff: 1, items: [{ t: 'saw',   dx: 0, dyup: 30,  r: 28 }] },
  { diff: 1, items: [{ t: 'block', dx: 0, w: 50, h: 52 }, { t: 'spike', dx: 50 }] },
  { diff: 1, items: [{ t: 'spike_ceil', dx: 0 }, { t: 'spike_ceil', dx: 52 }, { t: 'spike_ceil', dx: 104 }] },
  { diff: 1, items: [{ t: 'pad',   dx: 0 }, { t: 'spike', dx: 170 }, { t: 'spike', dx: 210 }] },
  { diff: 1, items: [{ t: 'orb',   dx: 0, dyup: 110 }, { t: 'spike', dx: 140 }] },
  // hard
  { diff: 2, items: [{ t: 'spike', dx: 0 }, { t: 'spike', dx: 40 }, { t: 'spike', dx: 80 }, { t: 'spike', dx: 120 }] },
  { diff: 2, items: [{ t: 'saw_move', dx: 0, dyup: 42, r: 32 }] },
  { diff: 2, items: [{ t: 'block', dx: 0, w: 50, h: 60 }, { t: 'spike', dx: 50 }, { t: 'block', dx: 132, w: 50, h: 60 }] },
  { diff: 2, items: [{ t: 'spike_ceil', dx: 0 }, { t: 'spike_ceil', dx: 52 }, { t: 'spike_ceil', dx: 104 }, { t: 'orb', dx: 30, dyup: 130 }] },
  { diff: 2, items: [{ t: 'saw', dx: 0, dyup: 30, r: 28 }, { t: 'spike', dx: 100 }, { t: 'spike', dx: 140 }] },
  { diff: 2, items: [{ t: 'block', dx: 0, w: 50, h: 88 }, { t: 'spike_ceil', dx: 20 }, { t: 'spike_ceil', dx: 72 }] },
  // expert
  { diff: 3, items: [{ t: 'spike', dx: 0 }, { t: 'spike', dx: 40 }, { t: 'spike', dx: 120 }, { t: 'spike', dx: 160 }, { t: 'spike', dx: 200 }] },
  { diff: 3, items: [{ t: 'saw_move', dx: 0, dyup: 30, r: 32 }, { t: 'saw_move', dx: 150, dyup: 68, r: 28 }] },
  { diff: 3, items: [{ t: 'block', dx: 0, w: 50, h: 60 }, { t: 'spike_ceil', dx: 0 }, { t: 'orb', dx: 90, dyup: 120 }, { t: 'spike', dx: 185 }] },
  { diff: 3, items: [{ t: 'saw', dx: 0, dyup: 30, r: 32 }, { t: 'spike_ceil', dx: 60 }, { t: 'spike_ceil', dx: 112 }, { t: 'spike', dx: 175 }] },
];

// ─── Game variables ───────────────────────────────────────────────────────────
let player, obstacles, coins, particles, bgStars;
let score, coinCount, combo, lives, speed;
let beatInterval, lastBeat;
let reviveUsed, animFrame;
let screenShake = { timer: 0, amp: 0, x: 0, y: 0 };
let zoneFlash = 0, zoneFlashName = '', lastZoneIdx = -1;
let spawnCooldown = 0;
let frameCount = 0;
let lastTime = 0;
let beatPulse = 0;

// ─── Game init ────────────────────────────────────────────────────────────────
function initGame() {
  speed        = SPEED_INIT;
  score        = 0;
  coinCount    = 0;
  combo        = 0;
  lives        = 3;
  reviveUsed   = false;
  beatInterval = 600;
  lastBeat     = 0;
  spawnCooldown = 0;
  frameCount   = 0;
  screenShake  = { timer: 0, amp: 0, x: 0, y: 0 };
  zoneFlash    = 0;
  lastZoneIdx  = -1;
  beatPulse    = 0;

  const groundY = H * GROUND_Y_FRAC;
  player = {
    x: W * 0.18,
    y: groundY - PLAYER_SIZE,
    vy: 0,
    onGround: true,
    jumpsLeft: 2,
    angle: 0,
    squash: 1,
    stretch: 1,
    trailX: [], trailY: [], trailA: [],
    skin: SKINS.find(s => s.id === saveData.equippedSkin) || SKINS[0],
    invincible: 0,
  };

  obstacles = [];
  coins     = [];
  particles = [];
  bgStars   = initStars();
  updateHUD();
}

function initStars() {
  const arr = [];
  for (let i = 0; i < 80; i++) {
    arr.push({
      x: Math.random() * W,
      y: Math.random() * H * 0.75,
      r: Math.random() * 2 + 0.5,
      speed: Math.random() * 0.4 + 0.1,
      alpha: Math.random() * 0.5 + 0.3,
    });
  }
  return arr;
}

// ─── Input ────────────────────────────────────────────────────────────────────
function handleJump() {
  if (gameState !== 'playing') return;

  // Check orb activation first
  for (let i = 0; i < obstacles.length; i++) {
    const o = obstacles[i];
    if (o.type !== 'orb' || o.used) continue;
    const px = player.x + PLAYER_SIZE / 2;
    const py = player.y + PLAYER_SIZE / 2;
    if (Math.hypot(px - o.cx, py - o.cy) < (o.r || 22) + PLAYER_SIZE * 0.65) {
      o.used = true;
      player.vy = ORB_V;
      player.onGround = false;
      player.jumpsLeft = 1;
      spawnOrbBurst(o.cx, o.cy, o.color);
      return;
    }
  }

  // Normal / double jump
  if (player.jumpsLeft > 0) {
    player.vy = player.onGround ? JUMP_V : DJUMP_V;
    player.onGround = false;
    player.jumpsLeft--;
    player.squash  = 1.35;
    player.stretch = 0.72;
    spawnJumpParticles();
  }
}

function handlePause() {
  if (gameState === 'playing') {
    gameState = 'paused';
    showScreen('pause-screen');
  } else if (gameState === 'paused') {
    resumeGame();
  }
}

document.addEventListener('keydown', e => {
  if (e.code === 'Space' || e.code === 'ArrowUp' || e.code === 'KeyW') {
    e.preventDefault();
    handleJump();
  }
  if (e.code === 'Escape') handlePause();
});

canvas.addEventListener('pointerdown', e => { e.preventDefault(); handleJump(); });

// ─── Particles ────────────────────────────────────────────────────────────────
function spawnJumpParticles() {
  const col = player.skin.color;
  for (let i = 0; i < 8; i++) {
    particles.push({
      x: player.x + PLAYER_SIZE / 2,
      y: player.y + PLAYER_SIZE,
      vx: (Math.random() - 0.5) * 5,
      vy: Math.random() * -3 - 1,
      life: 28, maxLife: 28, color: col,
      r: Math.random() * 5 + 2,
    });
  }
}

function spawnHitParticles() {
  for (let i = 0; i < 24; i++) {
    particles.push({
      x: player.x + PLAYER_SIZE / 2,
      y: player.y + PLAYER_SIZE / 2,
      vx: (Math.random() - 0.5) * 12,
      vy: (Math.random() - 0.5) * 12 - 2,
      life: 45, maxLife: 45,
      color: `hsl(${Math.random() * 40 + 10},100%,65%)`,
      r: Math.random() * 8 + 3,
    });
  }
}

function spawnOrbBurst(cx, cy, color) {
  for (let i = 0; i < 16; i++) {
    const ang = (i / 16) * Math.PI * 2;
    particles.push({
      x: cx, y: cy,
      vx: Math.cos(ang) * (Math.random() * 5 + 2),
      vy: Math.sin(ang) * (Math.random() * 5 + 2),
      life: 30, maxLife: 30, color,
      r: Math.random() * 5 + 3,
    });
  }
}

function spawnCoinBurst(x, y) {
  for (let i = 0; i < 10; i++) {
    const ang = (i / 10) * Math.PI * 2;
    particles.push({
      x, y,
      vx: Math.cos(ang) * (Math.random() * 4 + 1),
      vy: Math.sin(ang) * (Math.random() * 4 + 1) - 2,
      life: 22, maxLife: 22, color: '#ffe000',
      r: Math.random() * 4 + 2,
    });
  }
}

function spawnBeatPulse(zone) {
  particles.push({
    x: W / 2, y: H * GROUND_Y_FRAC,
    vx: 0, vy: 0,
    life: 18, maxLife: 18, color: zone.acc,
    r: W * 0.55, pulse: true,
  });
}

// ─── Chunk spawning ───────────────────────────────────────────────────────────
const SPAWN_INTERVAL_INIT = 100;
const SPAWN_INTERVAL_MIN  = 46;

function currentMaxDiff() {
  if (score > 1500) return 3;
  if (score > 700)  return 2;
  if (score > 250)  return 1;
  return 0;
}

function spawnChunk() {
  const maxDiff = currentMaxDiff();
  const eligible = CHUNKS.filter(c => c.diff <= maxDiff);
  const chunk = eligible[Math.floor(Math.random() * eligible.length)];
  const groundY = H * GROUND_Y_FRAC;
  const ceilY   = H * CEIL_Y_FRAC;
  const ox = W + 60;

  chunk.items.forEach(item => {
    const ix = ox + item.dx;
    if (item.t === 'spike') {
      obstacles.push({ type: 'spike', x: ix, y: groundY - 44, w: 38, h: 44 });
    } else if (item.t === 'spike_ceil') {
      obstacles.push({ type: 'spike_ceil', x: ix, y: ceilY, w: 38, h: 44 });
    } else if (item.t === 'block') {
      const bw = item.w || 50, bh = item.h || 52;
      obstacles.push({ type: 'block', x: ix, y: groundY - bh, w: bw, h: bh });
    } else if (item.t === 'saw') {
      const r = item.r || 28, dyup = item.dyup || 28;
      obstacles.push({ type: 'saw', cx: ix + r, cy: groundY - dyup, r, angle: 0, baseY: groundY - dyup, amp: 0, phase: 0 });
    } else if (item.t === 'saw_move') {
      const r = item.r || 30, dyup = item.dyup || 42;
      obstacles.push({ type: 'saw_move', cx: ix + r, cy: groundY - dyup, r, angle: 0, baseY: groundY - dyup, amp: H * 0.11, phase: Math.random() * Math.PI * 2 });
    } else if (item.t === 'orb') {
      const r = 22, dyup = item.dyup || 120;
      const color = Math.random() < 0.5 ? '#ffe000' : '#ff88ff';
      obstacles.push({ type: 'orb', cx: ix + r, cy: groundY - dyup, r, color, used: false });
    } else if (item.t === 'pad') {
      obstacles.push({ type: 'pad', x: ix, y: groundY - 16, w: 60, h: 16, pulse: 0 });
    }
  });

  // Occasionally toss a coin near the chunk
  if (Math.random() < 0.4) {
    const g = H * GROUND_Y_FRAC;
    coins.push({ x: ox + Math.random() * 60 + 80, y: g - H * 0.10 - Math.random() * H * 0.12, r: 14, wobble: Math.random() * Math.PI * 2 });
  }
}

// ─── Physics ──────────────────────────────────────────────────────────────────
function updatePlayer() {
  const groundY = H * GROUND_Y_FRAC;

  player.vy += GRAVITY;
  player.y  += player.vy;

  // GD cube rotation
  if (!player.onGround) {
    player.angle += 0.115;
  } else {
    const snap = Math.round(player.angle / (Math.PI / 2)) * (Math.PI / 2);
    player.angle += (snap - player.angle) * 0.35;
  }

  // Trail
  player.trailX.push(player.x + PLAYER_SIZE / 2);
  player.trailY.push(player.y + PLAYER_SIZE / 2);
  player.trailA.push(player.angle);
  if (player.trailX.length > 10) { player.trailX.shift(); player.trailY.shift(); player.trailA.shift(); }

  // Squash/stretch
  player.squash  += (1 - player.squash)  * 0.2;
  player.stretch += (1 - player.stretch) * 0.2;

  // Floor
  if (player.y + PLAYER_SIZE >= groundY) {
    player.y = groundY - PLAYER_SIZE;
    player.vy = 0;
    player.onGround = true;
    player.jumpsLeft = 2;
    if (player.squash < 0.9) { player.squash = 0.65; player.stretch = 1.4; }
  } else {
    player.onGround = false;
  }

  if (player.invincible > 0) player.invincible--;
}

// ─── Collision helpers ────────────────────────────────────────────────────────
function rectOverlap(ax, ay, aw, ah, bx, by, bw, bh) {
  return ax < bx + bw && ax + aw > bx && ay < by + bh && ay + ah > by;
}

function circleRectOverlap(cx, cy, r, rx, ry, rw, rh) {
  const nx = Math.max(rx, Math.min(cx, rx + rw));
  const ny = Math.max(ry, Math.min(cy, ry + rh));
  return Math.hypot(cx - nx, cy - ny) < r;
}

function playerHit() {
  if (player.invincible > 0) return;
  lives--;
  combo = 0;
  updateHUD();
  spawnHitParticles();
  triggerScreenShake(14, 22);
  player.invincible = 90;
  if (lives <= 0) triggerGameOver();
}

function triggerScreenShake(amp, dur) {
  screenShake.timer = dur;
  screenShake.amp   = amp;
}

function checkCollisions() {
  if (player.invincible > 0) return;

  const pm = 6;
  const px = player.x + pm, py = player.y + pm;
  const pw = PLAYER_SIZE - pm * 2, ph = PLAYER_SIZE - pm * 2;

  for (let i = obstacles.length - 1; i >= 0; i--) {
    const o = obstacles[i];
    if (o.type === 'spike' || o.type === 'spike_ceil') {
      if (rectOverlap(px, py, pw, ph, o.x + 4, o.y, o.w - 8, o.h)) { playerHit(); return; }
    } else if (o.type === 'block') {
      if (rectOverlap(px, py, pw, ph, o.x, o.y, o.w, o.h)) { playerHit(); return; }
    } else if (o.type === 'saw' || o.type === 'saw_move') {
      if (circleRectOverlap(o.cx, o.cy, o.r - 4, px, py, pw, ph)) { playerHit(); return; }
    } else if (o.type === 'pad') {
      if (player.vy >= 0 && rectOverlap(px, py, pw, ph, o.x, o.y, o.w, o.h)) {
        player.vy = PAD_V;
        player.onGround = false;
        player.jumpsLeft = 1;
        o.pulse = 15;
        spawnOrbBurst(o.x + o.w / 2, o.y, '#ffaa00');
      }
    }
  }

  for (let i = coins.length - 1; i >= 0; i--) {
    const c = coins[i];
    if (rectOverlap(px, py, pw, ph, c.x - c.r, c.y - c.r, c.r * 2, c.r * 2)) {
      coinCount++;
      saveData.coins++;
      combo++;
      score += 10 * Math.max(1, Math.floor(combo / 5));
      spawnCoinBurst(c.x, c.y);
      coins.splice(i, 1);
      updateHUD();
    }
  }
}

// ─── Beat ─────────────────────────────────────────────────────────────────────
function updateBeat(now, zone) {
  if (now - lastBeat >= beatInterval) {
    lastBeat     = now;
    beatInterval = Math.max(350, 600 - score * 0.12);
    beatPulse    = 1.0;
    spawnBeatPulse(zone);
    const el = document.getElementById('hud-score');
    el.style.transform = 'scale(1.3)';
    setTimeout(() => { el.style.transform = ''; }, 90);
  }
  beatPulse *= 0.88;
}

// ─── Main Game Loop ───────────────────────────────────────────────────────────
function gameLoop(ts) {
  if (gameState !== 'playing') {
    if (gameState === 'menu' || gameState === 'paused') {
      ctx.clearRect(0, 0, W, H);
      drawBG(ZONES[0]);
      drawGround(ZONES[0]);
    }
    lastTime = ts;
    animFrame = requestAnimationFrame(gameLoop);
    return;
  }

  const dt = Math.min(ts - lastTime, 50);
  lastTime = ts;
  frameCount++;

  speed = Math.min(SPEED_MAX, SPEED_INIT + score * SPEED_INC);
  score += dt * 0.012;

  const zIdx = Math.min(Math.floor(score / 1000), ZONES.length - 1);
  const zone = ZONES[zIdx];
  if (zIdx !== lastZoneIdx) {
    lastZoneIdx = zIdx;
    if (zIdx > 0) { zoneFlash = 150; zoneFlashName = zone.name; }
  }
  if (zoneFlash > 0) zoneFlash--;

  updateBeat(ts, zone);
  updatePlayer();

  if (screenShake.timer > 0) {
    const t = screenShake.timer--;
    const mag = (t / (screenShake.amp || 14)) * (screenShake.amp || 14);
    screenShake.x = (Math.random() - 0.5) * mag;
    screenShake.y = (Math.random() - 0.5) * mag;
  } else {
    screenShake.x = 0;
    screenShake.y = 0;
  }

  spawnCooldown--;
  if (spawnCooldown <= 0) {
    spawnChunk();
    spawnCooldown = Math.max(SPAWN_INTERVAL_MIN, SPAWN_INTERVAL_INIT - score * 0.03);
  }

  if (Math.random() < 0.006) {
    const g = H * GROUND_Y_FRAC;
    coins.push({ x: W + 40 + Math.random() * 80, y: g - H * 0.10 - Math.random() * H * 0.14, r: 14, wobble: Math.random() * Math.PI * 2 });
  }

  for (let i = obstacles.length - 1; i >= 0; i--) {
    const o = obstacles[i];
    if (o.type === 'saw' || o.type === 'saw_move' || o.type === 'orb') {
      o.cx -= speed;
      if (o.type === 'saw_move') {
        o.phase += 0.04;
        o.cy = o.baseY - Math.abs(Math.sin(o.phase)) * o.amp;
      }
      if (o.type !== 'orb') o.angle += 0.10;
      if (o.cx + (o.r || 30) < -20) obstacles.splice(i, 1);
    } else {
      o.x -= speed;
      if (o.type === 'pad' && o.pulse > 0) o.pulse--;
      if (o.x + (o.w || 50) < -20) obstacles.splice(i, 1);
    }
  }

  coins.forEach(c => { c.x -= speed; c.wobble += 0.07; });
  coins = coins.filter(c => c.x + c.r > -20);

  for (let i = particles.length - 1; i >= 0; i--) {
    const p = particles[i];
    p.x += p.vx; p.y += p.vy; p.life--;
    if (p.life <= 0) particles.splice(i, 1);
  }

  bgStars.forEach(s => { s.x -= s.speed; if (s.x < 0) { s.x = W; s.y = Math.random() * H * 0.75; } });

  checkCollisions();
  draw(zone);
  animFrame = requestAnimationFrame(gameLoop);
}

// ─── Drawing ──────────────────────────────────────────────────────────────────
function draw(zone) {
  ctx.save();
  ctx.translate(screenShake.x, screenShake.y);
  ctx.clearRect(-20, -20, W + 40, H + 40);
  drawBG(zone);
  drawParticles();
  drawGround(zone);
  drawCoins(zone);
  drawObstacles(zone);
  drawPlayer();
  drawHUDCanvas(zone);
  ctx.restore();
}

function drawBG(zone) {
  const grad = ctx.createLinearGradient(0, 0, 0, H);
  grad.addColorStop(0, zone.bg1);
  grad.addColorStop(0.7, zone.bg2);
  grad.addColorStop(1, zone.bg1);
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, W, H);

  bgStars.forEach(s => {
    ctx.globalAlpha = s.alpha;
    ctx.fillStyle = '#fff';
    ctx.beginPath();
    ctx.arc(s.x, s.y, s.r, 0, Math.PI * 2);
    ctx.fill();
  });
  ctx.globalAlpha = 1;

  const bdata = [
    [0.05,0.65,0.04,0.13],[0.10,0.60,0.05,0.18],[0.17,0.62,0.04,0.16],
    [0.24,0.55,0.06,0.23],[0.32,0.63,0.04,0.15],[0.38,0.58,0.05,0.20],
    [0.50,0.50,0.07,0.28],[0.58,0.60,0.04,0.18],[0.65,0.55,0.06,0.23],
    [0.73,0.63,0.04,0.15],[0.80,0.57,0.05,0.21],[0.87,0.65,0.04,0.13],
    [0.93,0.60,0.05,0.18],
  ];
  ctx.fillStyle = zone.bld;
  bdata.forEach(([bx, by, bw, bh]) => ctx.fillRect(bx * W, by * H, bw * W, bh * H));

  if (beatPulse > 0.3) {
    const rgb = hexToRgb(zone.acc);
    bdata.forEach(([bx, by, bw, bh]) => {
      for (let row = 0; row < 3; row++) {
        for (let col = 0; col < 2; col++) {
          if (Math.random() < beatPulse * 0.45) continue;
          ctx.fillStyle = `rgba(${rgb},${beatPulse * 0.22})`;
          ctx.fillRect((bx + bw * 0.1 + col * bw * 0.45) * W, (by + 0.02 + row * 0.045) * H, bw * 0.32 * W, 0.028 * H);
        }
      }
    });
  }

  const groundY = H * GROUND_Y_FRAC;
  const gg = ctx.createLinearGradient(0, groundY - 44, 0, groundY + 8);
  gg.addColorStop(0, 'rgba(0,0,0,0)');
  gg.addColorStop(1, hexToRgba(zone.acc, 0.18));
  ctx.fillStyle = gg;
  ctx.fillRect(0, groundY - 44, W, 52);
}

function drawGround(zone) {
  const groundY = H * GROUND_Y_FRAC;
  const sp = speed || SPEED_INIT;

  ctx.strokeStyle = hexToRgba(zone.acc, 0.12);
  ctx.lineWidth = 1;
  const scroll = (frameCount * sp * 0.5) % (W / 6);
  for (let i = 0; i < 7; i++) {
    const lx = i * (W / 6) - scroll;
    ctx.beginPath();
    ctx.moveTo(lx, groundY);
    ctx.lineTo(W / 2, H * 1.6);
    ctx.stroke();
  }
  for (let row = 0; row < 5; row++) {
    const t = row / 4;
    const gy = groundY + t * (H - groundY);
    ctx.globalAlpha = 0.07 + t * 0.04;
    ctx.beginPath(); ctx.moveTo(0, gy); ctx.lineTo(W, gy);
    ctx.stroke();
  }
  ctx.globalAlpha = 1;

  const pw = 2 + beatPulse * 4;
  ctx.strokeStyle = zone.gnd;
  ctx.lineWidth = pw;
  ctx.shadowColor = zone.gnd;
  ctx.shadowBlur = 8 + beatPulse * 10;
  ctx.beginPath(); ctx.moveTo(0, groundY); ctx.lineTo(W, groundY);
  ctx.stroke();
  ctx.shadowBlur = 0;
  ctx.lineWidth = 1;

  const ceilY = H * CEIL_Y_FRAC;
  ctx.strokeStyle = hexToRgba(zone.acc, 0.22);
  ctx.lineWidth = 1;
  ctx.setLineDash([8, 14]);
  ctx.beginPath(); ctx.moveTo(0, ceilY); ctx.lineTo(W, ceilY);
  ctx.stroke();
  ctx.setLineDash([]);
}

function drawPlayer() {
  const cx = player.x + PLAYER_SIZE / 2;
  const cy = player.y + PLAYER_SIZE / 2;
  const skinColor = player.skin.color;

  for (let i = 0; i < player.trailX.length; i++) {
    const a = (i / player.trailX.length) * 0.28;
    const ts = (i / player.trailX.length) * PLAYER_SIZE * 0.82;
    ctx.save();
    ctx.globalAlpha = a;
    ctx.translate(player.trailX[i], player.trailY[i]);
    ctx.rotate(player.trailA[i]);
    ctx.fillStyle = skinColor;
    ctx.fillRect(-ts / 2, -ts / 2, ts, ts);
    ctx.restore();
  }
  ctx.globalAlpha = 1;

  if (player.invincible > 0 && Math.floor(player.invincible / 5) % 2 === 0) return;

  ctx.save();
  ctx.translate(cx, cy);
  ctx.rotate(player.angle);
  ctx.scale(player.squash, player.stretch);

  const hs = PLAYER_SIZE / 2;

  ctx.shadowColor = skinColor;
  ctx.shadowBlur  = 16 + beatPulse * 8;

  ctx.fillStyle = 'rgba(0,0,0,0.65)';
  ctx.fillRect(-hs, -hs, PLAYER_SIZE, PLAYER_SIZE);
  ctx.fillStyle = hexToRgba(skinColor, 0.15);
  ctx.fillRect(-hs, -hs, PLAYER_SIZE, PLAYER_SIZE);

  ctx.strokeStyle = skinColor;
  ctx.lineWidth = 3;
  ctx.strokeRect(-hs, -hs, PLAYER_SIZE, PLAYER_SIZE);

  const inner = hs * 0.55;
  ctx.strokeStyle = hexToRgba(skinColor, 0.8);
  ctx.lineWidth = 1.5;
  ctx.strokeRect(-inner, -inner, inner * 2, inner * 2);

  ctx.strokeStyle = hexToRgba(skinColor, 0.45);
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.moveTo(-hs + 8, -hs); ctx.lineTo(hs, -hs + 8);
  ctx.moveTo(-hs + 8,  hs); ctx.lineTo(hs,  hs - 8);
  ctx.stroke();

  ctx.shadowBlur = 0;
  ctx.font = `${Math.round(hs * 1.1)}px serif`;
  ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
  ctx.fillText(player.skin.emoji, 0, 0);
  ctx.restore();
}

function drawObstacles(zone) {
  obstacles.forEach(o => {
    if      (o.type === 'spike')      drawSpike(o, zone, false);
    else if (o.type === 'spike_ceil') drawSpike(o, zone, true);
    else if (o.type === 'block')      drawBlock(o, zone);
    else if (o.type === 'saw' || o.type === 'saw_move') drawSaw(o);
    else if (o.type === 'orb')        drawOrb(o);
    else if (o.type === 'pad')        drawPad(o);
  });
}

function drawSpike(o, zone, inverted) {
  ctx.save();
  const cx   = o.x + o.w / 2;
  const base = inverted ? o.y       : o.y + o.h;
  const tip  = inverted ? o.y + o.h : o.y;
  const hw   = o.w / 2;

  ctx.shadowColor = zone.acc;
  ctx.shadowBlur  = 10;
  ctx.fillStyle   = hexToRgba(zone.acc, 0.85);
  ctx.beginPath();
  ctx.moveTo(cx - hw, base); ctx.lineTo(cx + hw, base); ctx.lineTo(cx, tip);
  ctx.closePath(); ctx.fill();

  ctx.strokeStyle = zone.acc; ctx.lineWidth = 2; ctx.stroke();

  ctx.strokeStyle = 'rgba(255,255,255,0.45)'; ctx.lineWidth = 1;
  ctx.beginPath(); ctx.moveTo(cx, tip);
  ctx.lineTo(cx - hw * 0.28, inverted ? tip - o.h * 0.4 : tip + o.h * 0.4);
  ctx.stroke();

  ctx.shadowBlur = 0; ctx.restore();
}

function drawBlock(o, zone) {
  ctx.save();
  ctx.shadowColor = zone.acc; ctx.shadowBlur = 8;
  ctx.fillStyle = 'rgba(0,0,0,0.72)'; ctx.fillRect(o.x, o.y, o.w, o.h);
  ctx.fillStyle = hexToRgba(zone.acc, 0.18); ctx.fillRect(o.x, o.y, o.w, o.h);
  ctx.strokeStyle = zone.acc; ctx.lineWidth = 2.5; ctx.strokeRect(o.x, o.y, o.w, o.h);

  ctx.strokeStyle = hexToRgba(zone.acc, 0.3); ctx.lineWidth = 1;
  ctx.beginPath();
  for (let d = -o.h; d < o.w + o.h; d += 16) {
    ctx.moveTo(o.x + d, o.y); ctx.lineTo(o.x + d + o.h, o.y + o.h);
  }
  ctx.stroke();

  ctx.strokeStyle = hexToRgba(zone.acc, 0.55); ctx.lineWidth = 1;
  ctx.strokeRect(o.x + 5, o.y + 5, o.w - 10, o.h - 10);
  ctx.shadowBlur = 0; ctx.restore();
}

function drawSaw(o) {
  ctx.save();
  ctx.translate(o.cx, o.cy); ctx.rotate(o.angle);
  ctx.shadowColor = '#ff2200'; ctx.shadowBlur = 14;

  const teeth = 10;
  ctx.fillStyle = '#cc1100';
  ctx.beginPath();
  for (let i = 0; i < teeth * 2; i++) {
    const ang = (i / (teeth * 2)) * Math.PI * 2;
    const r   = (i % 2 === 0) ? o.r : o.r * 0.65;
    if (i === 0) ctx.moveTo(Math.cos(ang) * r, Math.sin(ang) * r);
    else         ctx.lineTo(Math.cos(ang) * r, Math.sin(ang) * r);
  }
  ctx.closePath(); ctx.fill();

  ctx.fillStyle = '#440000'; ctx.beginPath(); ctx.arc(0, 0, o.r * 0.45, 0, Math.PI * 2); ctx.fill();
  ctx.fillStyle = '#ff4400'; ctx.beginPath(); ctx.arc(0, 0, o.r * 0.15, 0, Math.PI * 2); ctx.fill();
  ctx.strokeStyle = '#ff4400'; ctx.lineWidth = 2; ctx.beginPath(); ctx.arc(0, 0, o.r, 0, Math.PI * 2); ctx.stroke();
  ctx.shadowBlur = 0; ctx.restore();
}

function drawOrb(o) {
  if (o.used) return;
  ctx.save();
  const glow = 12 + Math.sin(frameCount * 0.12) * 6;
  ctx.shadowColor = o.color; ctx.shadowBlur = glow;
  ctx.strokeStyle = o.color; ctx.lineWidth = 3;
  ctx.beginPath(); ctx.arc(o.cx, o.cy, o.r, 0, Math.PI * 2); ctx.stroke();
  ctx.fillStyle = hexToRgba(o.color, 0.22); ctx.fill();
  drawStar(o.cx, o.cy, 5, o.r * 0.55, o.r * 0.25, frameCount * 0.05, o.color);
  ctx.shadowBlur = 0; ctx.restore();
}

function drawStar(cx, cy, points, outerR, innerR, rotation, color) {
  ctx.save(); ctx.translate(cx, cy); ctx.rotate(rotation);
  ctx.fillStyle = color; ctx.beginPath();
  for (let i = 0; i < points * 2; i++) {
    const ang = (i / (points * 2)) * Math.PI * 2 - Math.PI / 2;
    const r   = (i % 2 === 0) ? outerR : innerR;
    if (i === 0) ctx.moveTo(Math.cos(ang) * r, Math.sin(ang) * r);
    else         ctx.lineTo(Math.cos(ang) * r, Math.sin(ang) * r);
  }
  ctx.closePath(); ctx.fill(); ctx.restore();
}

function drawPad(o) {
  ctx.save();
  const col = o.pulse > 0 ? '#ffcc00' : '#ffaa00';
  ctx.shadowColor = col; ctx.shadowBlur = o.pulse > 0 ? 20 : 8;
  ctx.fillStyle = hexToRgba(col, 0.9);
  ctx.beginPath();
  ctx.moveTo(o.x + 6, o.y); ctx.lineTo(o.x + o.w - 6, o.y);
  ctx.lineTo(o.x + o.w, o.y + o.h); ctx.lineTo(o.x, o.y + o.h);
  ctx.closePath(); ctx.fill();
  ctx.strokeStyle = '#fff'; ctx.lineWidth = 2;
  ctx.beginPath(); ctx.moveTo(o.x + 8, o.y + 3); ctx.lineTo(o.x + o.w - 8, o.y + 3); ctx.stroke();
  ctx.fillStyle = '#000'; ctx.font = `bold ${Math.round(o.h * 0.75)}px serif`;
  ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
  ctx.fillText('▲', o.x + o.w / 2, o.y + o.h / 2);
  ctx.shadowBlur = 0; ctx.restore();
}

function drawCoins(zone) {
  coins.forEach(c => {
    const bob = Math.sin(c.wobble) * 4;
    ctx.save();
    ctx.shadowColor = zone.coin; ctx.shadowBlur = 10;
    ctx.fillStyle = zone.coin;
    ctx.beginPath(); ctx.arc(c.x, c.y + bob, c.r, 0, Math.PI * 2); ctx.fill();
    ctx.strokeStyle = '#fff'; ctx.lineWidth = 1.5; ctx.stroke();
    ctx.fillStyle = 'rgba(255,255,255,0.5)';
    ctx.beginPath();
    ctx.ellipse(c.x - c.r * 0.25, c.y + bob - c.r * 0.28, c.r * 0.26, c.r * 0.16, -0.5, 0, Math.PI * 2);
    ctx.fill();
    ctx.shadowBlur = 0; ctx.restore();
  });
}

function drawParticles() {
  particles.forEach(p => {
    const alpha = p.life / p.maxLife;
    if (p.pulse) {
      ctx.globalAlpha = alpha * 0.22;
      ctx.strokeStyle = p.color; ctx.lineWidth = 3;
      ctx.beginPath(); ctx.arc(p.x, p.y, p.r * (1 - alpha) * 1.5, 0, Math.PI * 2); ctx.stroke();
      ctx.globalAlpha = 1;
    } else {
      ctx.globalAlpha = alpha;
      ctx.fillStyle = p.color;
      ctx.beginPath(); ctx.arc(p.x, p.y, Math.max(0.5, p.r * alpha), 0, Math.PI * 2); ctx.fill();
      ctx.globalAlpha = 1;
    }
  });
}

function drawHUDCanvas(zone) {
  const best = Math.max(saveData.highscore, 1);
  const progress = Math.min(score / best, 1);
  ctx.fillStyle = 'rgba(255,255,255,0.07)';
  ctx.fillRect(0, 0, W, 4);
  ctx.fillStyle = progress >= 1 ? '#ffe000' : zone.acc;
  ctx.fillRect(0, 0, W * progress, 4);

  if (zoneFlash > 0) {
    const a = Math.min(1, zoneFlash / 30) * Math.min(1, zoneFlash / 80);
    ctx.globalAlpha = a * 0.14;
    ctx.fillStyle = zone.acc;
    ctx.fillRect(0, 0, W, H);
    ctx.globalAlpha = 1;

    if (zoneFlash > 20) {
      const ta = Math.min(1, (zoneFlash - 20) / 30);
      ctx.globalAlpha = ta;
      ctx.fillStyle = zone.acc;
      ctx.shadowColor = zone.acc; ctx.shadowBlur = 24;
      ctx.font = `bold ${Math.round(W * 0.046)}px 'Arial Black', Impact, sans-serif`;
      ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
      ctx.fillText(zoneFlashName, W / 2, H / 2);
      ctx.shadowBlur = 0; ctx.globalAlpha = 1;
    }
  }

  const attempts = saveData.attempts || 0;
  ctx.fillStyle = 'rgba(255,255,255,0.32)';
  ctx.font = `${Math.round(W * 0.024)}px 'Arial Black', Impact, sans-serif`;
  ctx.textAlign = 'right'; ctx.textBaseline = 'bottom';
  ctx.fillText(`Попытка #${attempts}`, W - 12, H - 8);
  ctx.textAlign = 'left';
}

// ─── Colour helpers ───────────────────────────────────────────────────────────
const _rgbCache = {};
function hexToRgb(hex) {
  if (_rgbCache[hex]) return _rgbCache[hex];
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  _rgbCache[hex] = `${r},${g},${b}`;
  return _rgbCache[hex];
}
function hexToRgba(hex, alpha) {
  return `rgba(${hexToRgb(hex)},${alpha})`;
}

// ───── HUD & UI ───────────────────────────────────────────────────────────────
function updateHUD() {
  document.getElementById('hud-score').textContent = Math.floor(score);
  document.getElementById('hud-coins').textContent = `🪙 ${coinCount}`;
  const hearts = '❤️'.repeat(lives) + '🖤'.repeat(Math.max(0, 3 - lives));
  document.getElementById('hud-lives').textContent = hearts;
  if (combo >= 5) {
    const comboEl = document.getElementById('hud-combo');
    comboEl.classList.remove('hidden');
    comboEl.textContent = `×${combo}`;
    comboEl.style.animation = 'none';
    void comboEl.offsetWidth;
    comboEl.style.animation = '';
  } else {
    document.getElementById('hud-combo').classList.add('hidden');
  }
}

function updateMenuUI() {
  document.getElementById('menu-highscore').textContent = `Рекорд: ${saveData.highscore}`;
}

// ───── Screen Management ──────────────────────────────────────────────────────
function showScreen(id) {
  ['main-menu', 'shop-screen', 'leaderboard-screen', 'gameover-screen', 'pause-screen'].forEach(s => {
    document.getElementById(s).classList.add('hidden');
  });
  document.getElementById('hud').classList.add('hidden');
  if (id) document.getElementById(id).classList.remove('hidden');
}

function showHUD() {
  document.getElementById('hud').classList.remove('hidden');
  ['main-menu', 'shop-screen', 'leaderboard-screen', 'gameover-screen', 'pause-screen'].forEach(s => {
    document.getElementById(s).classList.add('hidden');
  });
}

// ───── Game Flow ──────────────────────────────────────────────────────────────
function startGame() {
  saveData.attempts = (saveData.attempts || 0) + 1;
  savePlayerData();
  initGame();
  gameState = 'playing';
  showHUD();
  lastTime = performance.now();
  if (animFrame) cancelAnimationFrame(animFrame);
  animFrame = requestAnimationFrame(gameLoop);
}

function resumeGame() {
  gameState = 'playing';
  showHUD();
  lastTime = performance.now();
}

function triggerGameOver() {
  gameState = 'gameover';

  let newHS = false;
  if (Math.floor(score) > saveData.highscore) {
    saveData.highscore = Math.floor(score);
    newHS = true;
    submitScore(saveData.highscore);
  }
  saveData.coins += coinCount;
  saveData.coins = Math.min(saveData.coins, 99999);
  savePlayerData();

  document.getElementById('go-score').textContent     = Math.floor(score);
  document.getElementById('go-coins').textContent     = coinCount;
  document.getElementById('go-highscore').textContent = newHS ? '🏆 Новый рекорд!' : `Рекорд: ${saveData.highscore}`;
  document.getElementById('go-attempts').textContent  = saveData.attempts || 1;
  document.getElementById('btn-revive').style.display = reviveUsed ? 'none' : '';
  updateMenuUI();

  setTimeout(() => {
    showInterstitialAd(() => { showScreen('gameover-screen'); });
  }, 800);
}

function revivePlayer() {
  if (reviveUsed) return;
  reviveUsed = true;
  lives = 1;
  player.invincible = 150;
  gameState = 'playing';
  showHUD();
  updateHUD();
  lastTime = performance.now();
}

// ───── Ads ────────────────────────────────────────────────────────────────────
function showInterstitialAd(callback) {
  if (!sdkReady || !ysdk) { callback(); return; }
  document.getElementById('ad-overlay').classList.remove('hidden');
  ysdk.adv.showFullscreenAdv({
    callbacks: {
      onClose:  () => { document.getElementById('ad-overlay').classList.add('hidden'); callback(); },
      onError:  () => { document.getElementById('ad-overlay').classList.add('hidden'); callback(); },
    }
  });
}

function showRewardedAd(onRewarded) {
  if (!sdkReady || !ysdk) { onRewarded(); return; }
  document.getElementById('ad-overlay').classList.remove('hidden');
  ysdk.adv.showRewardedVideo({
    callbacks: {
      onRewarded: () => { onRewarded(); },
      onClose:    () => { document.getElementById('ad-overlay').classList.add('hidden'); },
      onError:    () => {
        document.getElementById('ad-overlay').classList.add('hidden');
        showNotification('Реклама недоступна. Попробуйте позже.');
      },
    }
  });
}

// ───── Payments ───────────────────────────────────────────────────────────────
async function buyCoins(productID) {
  if (!yPayments) { showNotification('Платежи недоступны в этом режиме.'); return; }
  try {
    const purchase = await yPayments.purchase({ id: productID });
    applyPurchase(productID, true);
    try { await yPayments.consumePurchase(purchase.purchaseToken); } catch (_) {}
  } catch (e) {
    if (e && e.code !== 'USER_CANCELED') showNotification('Ошибка оплаты. Попробуйте снова.');
  }
}

// ───── Leaderboard ────────────────────────────────────────────────────────────
async function submitScore(sc) {
  if (!yLeaderboard) return;
  try { await yLeaderboard.setLeaderboardScore('main_leaderboard', sc); } catch (_) {}
}

async function loadLeaderboard() {
  const listEl = document.getElementById('leaderboard-list');
  listEl.innerHTML = '<div class="lb-entry">Загрузка...</div>';
  if (!yLeaderboard) {
    listEl.innerHTML = '<div class="lb-entry">Таблица лидеров недоступна в этом режиме.</div>';
    return;
  }
  try {
    const result = await yLeaderboard.getLeaderboardEntries('main_leaderboard', {
      includeUser: true, quantityAround: 5, quantityTop: 10,
    });
    listEl.innerHTML = '';
    result.entries.forEach(entry => {
      const rc = entry.rank === 1 ? 'gold' : entry.rank === 2 ? 'silver' : entry.rank === 3 ? 'bronze' : '';
      const el = document.createElement('div');
      el.className = 'lb-entry';
      el.innerHTML = `
        <span class="lb-rank ${rc}">#${entry.rank}</span>
        <span class="lb-name">${entry.player.publicName || 'Игрок'}</span>
        <span class="lb-score">${entry.score}</span>
      `;
      listEl.appendChild(el);
    });
  } catch (_) {
    listEl.innerHTML = '<div class="lb-entry">Не удалось загрузить таблицу лидеров.</div>';
  }
}

// ───── Shop UI ────────────────────────────────────────────────────────────────
function buildShopUI() { updateShopUI(); buildCoinPacksUI(); }

function updateShopUI() {
  document.getElementById('shop-coins').textContent = saveData.coins;
  const grid = document.getElementById('skin-grid');
  grid.innerHTML = '';
  SKINS.forEach(skin => {
    const owned    = saveData.ownedSkins.includes(skin.id);
    const equipped = saveData.equippedSkin === skin.id;
    const card = document.createElement('div');
    card.className = `skin-card ${equipped ? 'equipped' : owned ? 'owned' : 'locked'}`;
    card.innerHTML = `
      <span class="skin-emoji">${skin.emoji}</span>
      <span>${skin.name}</span>
      ${equipped ? '<span style="color:#ffe000">✓ Одет</span>'
       : owned   ? '<span style="color:#00ffff">Одеть</span>'
                 : `<span class="skin-price">🪙 ${skin.price}</span>`}
    `;
    card.addEventListener('click', () => onSkinClick(skin));
    grid.appendChild(card);
  });
}

function buildCoinPacksUI() {
  const grid = document.getElementById('coin-packs-grid');
  grid.innerHTML = '';
  COIN_PACKS.forEach(pack => {
    const card = document.createElement('div');
    card.className = 'pack-card';
    card.innerHTML = `
      <div class="pack-info">${pack.label}<br><span class="pack-sub">${pack.sub}</span></div>
      <div class="pack-price">${pack.price}</div>
    `;
    card.addEventListener('click', () => buyCoins(pack.id));
    grid.appendChild(card);
  });
}

function onSkinClick(skin) {
  const owned = saveData.ownedSkins.includes(skin.id);
  if (owned) {
    saveData.equippedSkin = skin.id;
    savePlayerData();
    updateShopUI();
    showNotification(`${skin.emoji} ${skin.name} одет!`);
  } else {
    if (saveData.coins >= skin.price) {
      saveData.coins -= skin.price;
      saveData.ownedSkins.push(skin.id);
      saveData.equippedSkin = skin.id;
      savePlayerData();
      updateShopUI();
      showNotification(`${skin.emoji} ${skin.name} куплен!`);
    } else {
      showNotification(`Недостаточно монет! Нужно 🪙 ${skin.price}`);
    }
  }
}

// ───── Notification ───────────────────────────────────────────────────────────
let notifyTimeout = null;
function showNotification(text) {
  const el = document.getElementById('purchase-notify');
  document.getElementById('purchase-notify-text').textContent = text;
  el.classList.remove('hidden');
  if (notifyTimeout) clearTimeout(notifyTimeout);
  notifyTimeout = setTimeout(() => el.classList.add('hidden'), 2500);
}

// ───── Shop Tab Switching ─────────────────────────────────────────────────────
document.querySelectorAll('.shop-tab').forEach(tab => {
  tab.addEventListener('click', () => {
    document.querySelectorAll('.shop-tab').forEach(t => t.classList.remove('active'));
    tab.classList.add('active');
    document.querySelectorAll('.shop-tab-content').forEach(c => c.classList.add('hidden'));
    document.getElementById(`tab-${tab.dataset.tab}`).classList.remove('hidden');
  });
});

// ───── Button Handlers ────────────────────────────────────────────────────────
document.getElementById('btn-play').addEventListener('click', startGame);

document.getElementById('btn-shop').addEventListener('click', () => {
  buildShopUI();
  showScreen('shop-screen');
});

document.getElementById('btn-shop-back').addEventListener('click', () => showScreen('main-menu'));

document.getElementById('btn-leaderboard').addEventListener('click', () => {
  showScreen('leaderboard-screen');
  loadLeaderboard();
});
document.getElementById('btn-lb-back').addEventListener('click', () => showScreen('main-menu'));

document.getElementById('btn-revive').addEventListener('click', () => {
  if (gameState !== 'gameover') return;
  showRewardedAd(() => {
    revivePlayer();
    showNotification('💚 Возрождение! Удачи!');
  });
});

document.getElementById('btn-play-again').addEventListener('click', startGame);
document.getElementById('btn-go-menu').addEventListener('click', () => {
  showScreen('main-menu');
  updateMenuUI();
});

document.getElementById('btn-resume').addEventListener('click', resumeGame);
document.getElementById('btn-pause-menu').addEventListener('click', () => {
  gameState = 'menu';
  showScreen('main-menu');
  updateMenuUI();
});

// ───── Boot / Loading ─────────────────────────────────────────────────────────
async function boot() {
  const bar = document.getElementById('loading-bar');
  let progress = 0;
  const interval = setInterval(() => {
    progress = Math.min(progress + Math.random() * 15, 90);
    bar.style.width = progress + '%';
  }, 120);

  await initSDK();

  clearInterval(interval);
  bar.style.width = '100%';

  await new Promise(r => setTimeout(r, 400));

  const loadingEl = document.getElementById('loading-screen');
  loadingEl.classList.add('fade-out');
  await new Promise(r => setTimeout(r, 500));
  loadingEl.classList.add('hidden');

  gameState = 'menu';
  initGame();
  animFrame = requestAnimationFrame(gameLoop);
  showScreen('main-menu');
  updateMenuUI();
}

boot();

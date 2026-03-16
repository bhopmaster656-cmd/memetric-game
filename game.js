/* ===========================
   MEMETRIC – Rhythm Meme Platformer
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

    // Player auth (optional – anonymous allowed)
    try {
      yPlayer = await ysdk.getPlayer({ scopes: false });
    } catch (_) {
      yPlayer = null;
    }

    // Payments
    try {
      yPayments = await ysdk.getPayments({ signed: true });
    } catch (_) {
      yPayments = null;
    }

    // Leaderboard
    try {
      yLeaderboard = await ysdk.getLeaderboards();
    } catch (_) {
      yLeaderboard = null;
    }

    // Restore purchased items
    if (yPayments) {
      try {
        const purchases = await yPayments.getPurchases();
        purchases.forEach(p => applyPurchase(p.productID, false));
      } catch (_) { /* ignore */ }
    }

    // Load saved data
    loadPlayerData();
  } catch (e) {
    // SDK unavailable (local dev) – continue without it
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
  equippedSkin: 'default'
};

let saveData = { ...DEFAULT_SAVE };

async function loadPlayerData() {
  if (yPlayer) {
    try {
      const d = await yPlayer.getData(['coins', 'highscore', 'ownedSkins', 'equippedSkin']);
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
  { id: 'default',  name: 'Дефолт',   emoji: '😎', price: 0 },
  { id: 'nyan',     name: 'Нян Кэт',  emoji: '🌈', price: 200 },
  { id: 'doge',     name: 'Доге',     emoji: '🐕', price: 350 },
  { id: 'trollface',name: 'Троллфейс',emoji: '😈', price: 500 },
  { id: 'pepe',     name: 'Пепе',     emoji: '🐸', price: 500 },
  { id: 'bonk',     name: 'Бонк',     emoji: '🔨', price: 750 },
  { id: 'chad',     name: 'Чад',      emoji: '😤', price: 1000 },
  { id: 'sparkle',  name: 'Спаркл',   emoji: '✨', price: 1200 },
];

// Yandex in-app purchase products
const COIN_PACKS = [
  { id: 'coins_small',  label: '🪙 × 100',  sub: 'Стартовый набор', coins: 100,  price: '15 ₽' },
  { id: 'coins_medium', label: '🪙 × 500',  sub: 'Выгодный набор',  coins: 500,  price: '49 ₽' },
  { id: 'coins_large',  label: '🪙 × 1500', sub: 'Большой набор',  coins: 1500, price: '99 ₽' },
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

// ───── Canvas / Game State ─────────────────────────────────────────────────────
const canvas = document.getElementById('game-canvas');
const ctx = canvas.getContext('2d');

let W = 0, H = 0;
let dpr = 1;
let gameState = 'loading'; // loading | menu | playing | paused | gameover

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

// ───── Game Objects ───────────────────────────────────────────────────────────
const PLAYER_W = 48;
const PLAYER_H = 48;
const GROUND_Y_FRAC = 0.78;  // ground line at 78% of screen height
const GRAVITY = 0.55;
const JUMP_V = -13.5;
const DOUBLE_JUMP_V = -11;
const SPEED_INIT = 5.5;
const SPEED_MAX = 12;
const SPEED_INC = 0.0008;

let player, obstacles, coins, particles, bgStars, score, coinCount, combo, lives, speed;
let beatTimer, beatInterval, lastBeat;
let reviveUsed;
let animFrame;

const EMOJIS_OBSTACLE = ['💀', '🦠', '☠️', '👾', '🤡'];
const EMOJIS_COIN     = ['🪙', '⭐', '💎'];

function initGame() {
  speed = SPEED_INIT;
  score = 0;
  coinCount = 0;
  combo = 0;
  lives = 3;
  reviveUsed = false;
  beatInterval = 600;
  lastBeat = 0;
  beatTimer = 0;

  const ground = H * GROUND_Y_FRAC;
  player = {
    x: W * 0.18,
    y: ground - PLAYER_H,
    vy: 0,
    onGround: true,
    jumpsLeft: 2,
    squash: 1,
    stretch: 1,
    trailX: [], trailY: [],
    skin: SKINS.find(s => s.id === saveData.equippedSkin) || SKINS[0],
    invincible: 0,
    dead: false,
  };

  obstacles = [];
  coins = [];
  particles = [];
  bgStars = initStars();

  updateHUD();
}

function initStars() {
  const arr = [];
  for (let i = 0; i < 80; i++) {
    arr.push({
      x: Math.random() * W,
      y: Math.random() * H * 0.75,
      r: Math.random() * 2 + 0.5,
      speed: Math.random() * 0.5 + 0.1,
      alpha: Math.random() * 0.5 + 0.3,
    });
  }
  return arr;
}

// ───── Input ──────────────────────────────────────────────────────────────────
function handleJump() {
  if (gameState !== 'playing') return;
  if (player.jumpsLeft > 0) {
    player.vy = player.onGround ? JUMP_V : DOUBLE_JUMP_V;
    player.onGround = false;
    player.jumpsLeft--;
    player.squash = 1.4;
    player.stretch = 0.7;
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

canvas.addEventListener('pointerdown', e => {
  e.preventDefault();
  handleJump();
});

// ───── Particles ─────────────────────────────────────────────────────────────
function spawnJumpParticles() {
  const ground = H * GROUND_Y_FRAC;
  for (let i = 0; i < 8; i++) {
    particles.push({
      x: player.x + PLAYER_W / 2,
      y: player.y + PLAYER_H,
      vx: (Math.random() - 0.5) * 4,
      vy: Math.random() * -3 - 1,
      life: 30,
      maxLife: 30,
      color: `hsl(${Math.random() * 360},100%,70%)`,
      r: Math.random() * 5 + 2,
    });
  }
}

function spawnCoinParticles(x, y) {
  for (let i = 0; i < 12; i++) {
    const angle = (i / 12) * Math.PI * 2;
    particles.push({
      x, y,
      vx: Math.cos(angle) * (Math.random() * 3 + 1),
      vy: Math.sin(angle) * (Math.random() * 3 + 1) - 2,
      life: 25,
      maxLife: 25,
      color: '#ffe000',
      r: Math.random() * 4 + 2,
    });
  }
}

function spawnDeathParticles() {
  for (let i = 0; i < 20; i++) {
    particles.push({
      x: player.x + PLAYER_W / 2,
      y: player.y + PLAYER_H / 2,
      vx: (Math.random() - 0.5) * 10,
      vy: (Math.random() - 0.5) * 10 - 3,
      life: 40,
      maxLife: 40,
      color: `hsl(${Math.random() * 60},100%,60%)`,
      r: Math.random() * 7 + 3,
    });
  }
}

// ───── Obstacle & Coin Spawning ───────────────────────────────────────────────
let spawnTimer = 0;
let spawnInterval = 90;

function maybeSpawnObstacle() {
  spawnTimer++;
  if (spawnTimer < spawnInterval) return;
  spawnTimer = 0;
  spawnInterval = Math.max(45, 90 - score * 0.05);

  const ground = H * GROUND_Y_FRAC;
  const h = Math.random() * (H * 0.12) + H * 0.06;
  const w = Math.random() * 20 + 30;
  const emoji = EMOJIS_OBSTACLE[Math.floor(Math.random() * EMOJIS_OBSTACLE.length)];

  // randomly add platform variant (elevated obstacle)
  const elevated = Math.random() < 0.25 && score > 200;
  const oy = elevated ? ground - h - H * 0.22 : ground - h;

  obstacles.push({ x: W + 20, y: oy, w, h, emoji, elevated });

  // coin after some obstacles
  if (Math.random() < 0.45) {
    const coinEmoji = EMOJIS_COIN[Math.floor(Math.random() * EMOJIS_COIN.length)];
    coins.push({
      x: W + 20 + Math.random() * 60 + 60,
      y: ground - H * 0.18 - Math.random() * H * 0.12,
      w: 28, h: 28,
      emoji: coinEmoji,
      collected: false,
      wobble: Math.random() * Math.PI * 2,
    });
  }
}

// ───── Physics & Collision ────────────────────────────────────────────────────
function updatePlayer() {
  const ground = H * GROUND_Y_FRAC;

  // gravity
  player.vy += GRAVITY;
  player.y += player.vy;

  // trail
  player.trailX.push(player.x + PLAYER_W / 2);
  player.trailY.push(player.y + PLAYER_H / 2);
  if (player.trailX.length > 8) {
    player.trailX.shift();
    player.trailY.shift();
  }

  // squash/stretch recovery
  player.squash += (1 - player.squash) * 0.2;
  player.stretch += (1 - player.stretch) * 0.2;

  // floor
  if (player.y + PLAYER_H >= ground) {
    player.y = ground - PLAYER_H;
    player.vy = 0;
    player.onGround = true;
    player.jumpsLeft = 2;
    if (player.squash < 0.9) { player.squash = 0.7; player.stretch = 1.3; }
  } else {
    player.onGround = false;
  }

  if (player.invincible > 0) player.invincible--;
}

function rectOverlap(ax, ay, aw, ah, bx, by, bw, bh) {
  return ax < bx + bw && ax + aw > bx && ay < by + bh && ay + ah > by;
}

function checkCollisions() {
  if (player.invincible > 0) return;

  for (let i = obstacles.length - 1; i >= 0; i--) {
    const o = obstacles[i];
    const margin = 6;
    if (rectOverlap(
      player.x + margin, player.y + margin,
      PLAYER_W - margin * 2, PLAYER_H - margin * 2,
      o.x, o.y, o.w, o.h
    )) {
      lives--;
      combo = 0;
      updateHUD();
      spawnDeathParticles();
      player.invincible = 90;
      obstacles.splice(i, 1);
      if (lives <= 0) triggerGameOver();
      break;
    }
  }

  for (let i = coins.length - 1; i >= 0; i--) {
    const c = coins[i];
    if (!c.collected && rectOverlap(
      player.x + 6, player.y + 6, PLAYER_W - 12, PLAYER_H - 12,
      c.x, c.y, c.w, c.h
    )) {
      c.collected = true;
      coinCount++;
      saveData.coins++;
      combo++;
      score += 10 * Math.max(1, Math.floor(combo / 5));
      spawnCoinParticles(c.x + c.w / 2, c.y + c.h / 2);
      coins.splice(i, 1);
      updateHUD();
    }
  }
}

// ───── Beat / Rhythm ──────────────────────────────────────────────────────────
function updateBeat(now) {
  if (now - lastBeat >= beatInterval) {
    lastBeat = now;
    beatInterval = Math.max(380, 600 - score * 0.15);
    onBeat();
  }
}

function onBeat() {
  // flash score
  const hudScore = document.getElementById('hud-score');
  hudScore.style.transform = 'scale(1.25)';
  setTimeout(() => { hudScore.style.transform = ''; }, 100);
  // spawn pulse particle
  particles.push({
    x: W * 0.5, y: H * GROUND_Y_FRAC,
    vx: 0, vy: -0.5,
    life: 20, maxLife: 20,
    color: 'rgba(255,0,255,0.3)',
    r: W * 0.4,
    pulse: true,
  });
}

// ───── Main Game Loop ─────────────────────────────────────────────────────────
let lastTime = 0;
let frameCount = 0;

function gameLoop(ts) {
  if (gameState !== 'playing') { lastTime = ts; animFrame = requestAnimationFrame(gameLoop); return; }

  const dt = Math.min(ts - lastTime, 50);
  lastTime = ts;
  frameCount++;

  // speed up
  speed = Math.min(SPEED_MAX, SPEED_INIT + score * SPEED_INC);
  score += dt * 0.01;

  updateBeat(ts);
  updatePlayer();
  maybeSpawnObstacle();

  // move obstacles
  for (let i = obstacles.length - 1; i >= 0; i--) {
    obstacles[i].x -= speed;
    if (obstacles[i].x + obstacles[i].w < -20) obstacles.splice(i, 1);
  }

  // move coins
  coins.forEach(c => {
    c.x -= speed;
    c.wobble += 0.06;
  });
  coins = coins.filter(c => c.x + c.w > -20);

  // update particles
  for (let i = particles.length - 1; i >= 0; i--) {
    const p = particles[i];
    p.x += p.vx;
    p.y += p.vy;
    p.life--;
    if (p.pulse) { p.vx = 0; p.vy = 0; }
    if (p.life <= 0) particles.splice(i, 1);
  }

  // scroll stars
  bgStars.forEach(s => {
    s.x -= s.speed;
    if (s.x < 0) { s.x = W; s.y = Math.random() * H * 0.75; }
  });

  checkCollisions();
  draw();

  animFrame = requestAnimationFrame(gameLoop);
}

// ───── Drawing ────────────────────────────────────────────────────────────────
function draw() {
  ctx.clearRect(0, 0, W, H);
  drawBG();
  drawParticles();
  drawGround();
  drawCoins();
  drawObstacles();
  drawPlayer();
}

function drawBG() {
  // sky gradient
  const grad = ctx.createLinearGradient(0, 0, 0, H);
  grad.addColorStop(0, '#0d0020');
  grad.addColorStop(0.6, '#0d0d1a');
  grad.addColorStop(1, '#1a0030');
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, W, H);

  // stars
  bgStars.forEach(s => {
    ctx.globalAlpha = s.alpha;
    ctx.fillStyle = '#fff';
    ctx.beginPath();
    ctx.arc(s.x, s.y, s.r, 0, Math.PI * 2);
    ctx.fill();
  });
  ctx.globalAlpha = 1;

  // distant city silhouette
  ctx.fillStyle = 'rgba(80,0,120,0.35)';
  const buildingData = [
    [0.05, 0.65, 0.04, 0.13],
    [0.1,  0.60, 0.05, 0.18],
    [0.17, 0.62, 0.04, 0.16],
    [0.24, 0.55, 0.06, 0.23],
    [0.32, 0.63, 0.04, 0.15],
    [0.38, 0.58, 0.05, 0.20],
    [0.5,  0.50, 0.07, 0.28],
    [0.58, 0.60, 0.04, 0.18],
    [0.65, 0.55, 0.06, 0.23],
    [0.73, 0.63, 0.04, 0.15],
    [0.80, 0.57, 0.05, 0.21],
    [0.87, 0.65, 0.04, 0.13],
    [0.93, 0.60, 0.05, 0.18],
  ];
  buildingData.forEach(([bx, by, bw, bh]) => {
    ctx.fillRect(bx * W, by * H, bw * W, bh * H);
  });

  // neon floor glow
  const groundY = H * GROUND_Y_FRAC;
  const glowGrad = ctx.createLinearGradient(0, groundY - 30, 0, groundY + 10);
  glowGrad.addColorStop(0, 'rgba(255,0,255,0)');
  glowGrad.addColorStop(1, 'rgba(255,0,255,0.18)');
  ctx.fillStyle = glowGrad;
  ctx.fillRect(0, groundY - 30, W, 40);
}

function drawGround() {
  const groundY = H * GROUND_Y_FRAC;

  // grid lines (cyberpunk perspective grid)
  ctx.strokeStyle = 'rgba(255,0,255,0.12)';
  ctx.lineWidth = 1;
  const scroll = (frameCount * speed * 0.5) % (W / 6);
  for (let i = 0; i < 7; i++) {
    const lx = i * (W / 6) - scroll;
    ctx.beginPath();
    ctx.moveTo(lx, groundY);
    ctx.lineTo(W / 2, H * 1.5);
    ctx.stroke();
  }
  // horizontal grid lines
  for (let row = 0; row < 6; row++) {
    const t = row / 5;
    const gy = groundY + t * (H - groundY);
    ctx.beginPath();
    ctx.moveTo(0, gy);
    ctx.lineTo(W, gy);
    ctx.globalAlpha = 0.08 + t * 0.04;
    ctx.stroke();
  }
  ctx.globalAlpha = 1;

  // main ground line
  ctx.strokeStyle = '#ff00ff';
  ctx.lineWidth = 2;
  ctx.shadowColor = '#ff00ff';
  ctx.shadowBlur = 8;
  ctx.beginPath();
  ctx.moveTo(0, groundY);
  ctx.lineTo(W, groundY);
  ctx.stroke();
  ctx.shadowBlur = 0;
}

function drawPlayer() {
  const cx = player.x + PLAYER_W / 2;
  const cy = player.y + PLAYER_H / 2;
  const sw = PLAYER_W * player.squash;
  const sh = PLAYER_H * player.stretch;

  // trail
  for (let i = 0; i < player.trailX.length; i++) {
    const alpha = (i / player.trailX.length) * 0.35;
    ctx.globalAlpha = alpha;
    ctx.fillStyle = '#ff00ff';
    const ts = (i / player.trailX.length) * sw * 0.9;
    ctx.fillRect(player.trailX[i] - ts / 2, player.trailY[i] - ts / 2, ts, ts);
  }
  ctx.globalAlpha = 1;

  // invincibility flash
  if (player.invincible > 0 && Math.floor(player.invincible / 5) % 2 === 0) return;

  // body glow
  ctx.shadowColor = '#ff00ff';
  ctx.shadowBlur = 14;

  ctx.save();
  ctx.translate(cx, cy);
  ctx.scale(player.squash, player.stretch);

  // Draw emoji character
  ctx.font = `${Math.round(sw * 0.9)}px serif`;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText(player.skin.emoji, 0, 0);

  ctx.restore();
  ctx.shadowBlur = 0;
}

function drawObstacles() {
  obstacles.forEach(o => {
    ctx.shadowColor = '#ff4400';
    ctx.shadowBlur = 10;
    ctx.font = `${Math.round(o.w * 1.1)}px serif`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'bottom';
    ctx.fillText(o.emoji, o.x + o.w / 2, o.y + o.h);
    ctx.shadowBlur = 0;

    // hitbox debug (disabled)
    // ctx.strokeStyle='red'; ctx.strokeRect(o.x,o.y,o.w,o.h);
  });
}

function drawCoins() {
  coins.forEach(c => {
    const bob = Math.sin(c.wobble) * 4;
    ctx.shadowColor = '#ffe000';
    ctx.shadowBlur = 8;
    ctx.font = `${c.w}px serif`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(c.emoji, c.x + c.w / 2, c.y + c.h / 2 + bob);
    ctx.shadowBlur = 0;
  });
}

function drawParticles() {
  particles.forEach(p => {
    const alpha = p.life / p.maxLife;
    if (p.pulse) {
      ctx.globalAlpha = alpha * 0.3;
      ctx.strokeStyle = '#ff00ff';
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.r * (1 - alpha) * 2, 0, Math.PI * 2);
      ctx.stroke();
      ctx.globalAlpha = 1;
    } else {
      ctx.globalAlpha = alpha;
      ctx.fillStyle = p.color;
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.r * alpha, 0, Math.PI * 2);
      ctx.fill();
      ctx.globalAlpha = 1;
    }
  });
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
    // Retrigger CSS animation by resetting the animation property
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

  // Update highscore
  let newHS = false;
  if (Math.floor(score) > saveData.highscore) {
    saveData.highscore = Math.floor(score);
    newHS = true;
    submitScore(saveData.highscore);
  }
  saveData.coins += coinCount;
  saveData.coins = Math.min(saveData.coins, 99999);
  savePlayerData();

  document.getElementById('go-score').textContent = Math.floor(score);
  document.getElementById('go-coins').textContent = coinCount;
  document.getElementById('go-highscore').textContent = newHS ? '🏆 Новый рекорд!' : `Рекорд: ${saveData.highscore}`;
  document.getElementById('btn-revive').style.display = reviveUsed ? 'none' : '';
  updateMenuUI();

  // Show interstitial ad after game over (with small delay)
  setTimeout(() => {
    showInterstitialAd(() => {
      showScreen('gameover-screen');
    });
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
      onClose: (wasShown) => {
        document.getElementById('ad-overlay').classList.add('hidden');
        callback();
      },
      onError: () => {
        document.getElementById('ad-overlay').classList.add('hidden');
        callback();
      }
    }
  });
}

function showRewardedAd(onRewarded) {
  if (!sdkReady || !ysdk) {
    onRewarded(); return;
  }
  document.getElementById('ad-overlay').classList.remove('hidden');
  ysdk.adv.showRewardedVideo({
    callbacks: {
      onRewarded: () => {
        onRewarded();
      },
      onClose: () => {
        document.getElementById('ad-overlay').classList.add('hidden');
      },
      onError: () => {
        document.getElementById('ad-overlay').classList.add('hidden');
        showNotification('Реклама недоступна. Попробуйте позже.');
      }
    }
  });
}

// ───── Payments ───────────────────────────────────────────────────────────────
async function buyCoins(productID) {
  if (!yPayments) {
    showNotification('Платежи недоступны в этом режиме.');
    return;
  }
  try {
    const purchase = await yPayments.purchase({ id: productID });
    applyPurchase(productID, true);
    // Consume the purchase so it can be purchased again
    try { await yPayments.consumePurchase(purchase.purchaseToken); } catch (_) {}
  } catch (e) {
    if (e && e.code !== 'USER_CANCELED') {
      showNotification('Ошибка оплаты. Попробуйте снова.');
    }
  }
}

// ───── Leaderboard ────────────────────────────────────────────────────────────
async function submitScore(score) {
  if (!yLeaderboard) return;
  try {
    await yLeaderboard.setLeaderboardScore('main_leaderboard', score);
  } catch (_) {}
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
      includeUser: true,
      quantityAround: 5,
      quantityTop: 10,
    });
    listEl.innerHTML = '';
    result.entries.forEach(entry => {
      const rankClass = entry.rank === 1 ? 'gold' : entry.rank === 2 ? 'silver' : entry.rank === 3 ? 'bronze' : '';
      const el = document.createElement('div');
      el.className = 'lb-entry';
      el.innerHTML = `
        <span class="lb-rank ${rankClass}">#${entry.rank}</span>
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
function buildShopUI() {
  updateShopUI();
  buildCoinPacksUI();
}

function updateShopUI() {
  document.getElementById('shop-coins').textContent = saveData.coins;
  const grid = document.getElementById('skin-grid');
  grid.innerHTML = '';

  SKINS.forEach(skin => {
    const owned   = saveData.ownedSkins.includes(skin.id);
    const equipped = saveData.equippedSkin === skin.id;

    const card = document.createElement('div');
    card.className = `skin-card ${equipped ? 'equipped' : owned ? 'owned' : 'locked'}`;
    card.innerHTML = `
      <span class="skin-emoji">${skin.emoji}</span>
      <span>${skin.name}</span>
      ${equipped ? '<span style="color:#ffe000">✓ Одет</span>' :
        owned    ? '<span style="color:#00ffff">Одеть</span>' :
                   `<span class="skin-price">🪙 ${skin.price}</span>`}
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
  // Fake loading progress
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

  // Start background animation
  gameState = 'menu';
  initGame();
  animFrame = requestAnimationFrame(gameLoop);
  showScreen('main-menu');
  updateMenuUI();
}

boot();

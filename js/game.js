/* ============================================================
   NEON GRAVITY — complete game engine
   A cyberpunk gravity-flip auto-runner inspired by Mad Dex.

   Core mechanics
   ──────────────
   • Auto-runner: Kay moves right automatically.
   • Gravity flip (SHIFT / Z): toggles gravity direction.
     Red glow = gravity pulls DOWN, Blue glow = gravity pulls UP.
   • Jump (SPACE / ↑): impulse opposite to gravity.
   • Gravity Anchor (X / Q): throw a magnetic anchor. It sticks to
     the next surface it hits. Press again to be pulled to it
     instantly. Max 2 anchors per section; terminals restore them.
   • Destructible bridges collapse as you run across them.
   • Drones match your gravity polarity.
   ============================================================ */

'use strict';

// ── CANVAS SETUP ─────────────────────────────────────────────
const CVS_W = 800, CVS_H = 400;

const canvas = document.getElementById('canvas');
canvas.width  = CVS_W;
canvas.height = CVS_H;
const ctx = canvas.getContext('2d');

// Scale canvas to window while preserving aspect ratio
function fitCanvas() {
  const scaleX = window.innerWidth  / CVS_W;
  const scaleY = window.innerHeight / CVS_H;
  const scale  = Math.min(scaleX, scaleY);
  canvas.style.width  = (CVS_W * scale) + 'px';
  canvas.style.height = (CVS_H * scale) + 'px';
}
window.addEventListener('resize', fitCanvas);
fitCanvas();

// ── CONSTANTS ────────────────────────────────────────────────
const GRAVITY         = 2200;   // px/s²
const MAX_FALL        = 1050;   // px/s terminal velocity
const MOVE_SPEED      = 265;    // px/s auto-run
const JUMP_VEL        = 760;    // px/s jump impulse magnitude
const PW              = 26;     // player width
const PH              = 26;     // player height
const ANCHOR_THROW_V  = 680;    // anchor projectile speed
const ANCHOR_PULL_V   = 950;    // pull-toward-anchor speed
const MAX_ANCHORS     = 2;      // anchors per level section
const FLOOR_Y         = 368;    // top of main floor band
const CEIL_H          = 32;     // height of ceiling band
const TILE            = 32;     // tile unit

// ── COLOUR PALETTE ───────────────────────────────────────────
const COL = {
  bg:         '#04040e',
  platform:   '#0c1020',
  platEdge:   '#2850a8',
  platGlow:   '#4878e8',
  spike:      '#ff2040',
  spikeGlow:  '#ff2040',
  laserBeam:  '#ff3c00',
  laserGlow:  'rgba(255,80,0,0.35)',
  fieldRed:   'rgba(255,30,50,0.22)',
  fieldBlue:  'rgba(30,60,255,0.22)',
  terminal:   '#28ff78',
  termGlow:   '#28ff78',
  drone:      '#f840f0',
  droneGlow:  '#f840f0',
  anchor:     '#f0f030',
  anchorGlow: '#f0f030',
  bridge:     '#1c2840',
  bridgeEdge: '#3060c0',
  goal:       '#30ffe8',
  goalGlow:   '#30ffe8',
  playerDown: '#ff5040',  // gravity-down glow
  playerUp:   '#4050ff',  // gravity-up glow
  playerFill: '#d8d8f8',
  waveFill:   'rgba(180,0,255,0.12)',
  waveGlow:   '#b000ff',
  ghost:      'rgba(150,150,255,0.25)',
};

// ── INPUT ────────────────────────────────────────────────────
const keysHeld = {};
const keysOnce = {};

window.addEventListener('keydown', e => {
  if (!keysHeld[e.code]) keysOnce[e.code] = true;
  keysHeld[e.code] = true;
});
window.addEventListener('keyup', e => {
  keysHeld[e.code] = false;
});

function held(code)  { return !!keysHeld[code]; }
function once(code)  {
  if (keysOnce[code]) { keysOnce[code] = false; return true; }
  return false;
}
function anyOnce(...codes) { return codes.some(c => once(c)); }

// ── UTILS ────────────────────────────────────────────────────
function aabb(ax,ay,aw,ah, bx,by,bw,bh) {
  return ax < bx+bw && ax+aw > bx && ay < by+bh && ay+ah > by;
}
function clamp(v,lo,hi) { return Math.max(lo,Math.min(hi,v)); }
function rnd(n) { return Math.floor(Math.random()*n); }
function pick(arr) { return arr[rnd(arr.length)]; }

// ── LEVEL DATA ───────────────────────────────────────────────
// Each level is built from "segments" — groups of objects.
// Types: 'solid' | 'spike' | 'laser_h' | 'laser_v' |
//        'field_red' | 'field_blue' | 'terminal' |
//        'bridge' | 'grav_wave' | 'goal'

function makePlatform(x,y,w,h)   { return { x,y,w,h, type:'solid'     }; }
function makeSpike(x,y,w,h)      { return { x,y,w,h, type:'spike'     }; }
function makeLaserH(x,y,len)     { return { x,y, w:len, h:4, type:'laser_h', active:false, timer:0, period:2.2, phase:0 }; }
function makeLaserV(x,y,len)     { return { x,y, w:4, h:len, type:'laser_v', active:false, timer:0, period:1.8, phase:1 }; }
function makeTerminal(x,y)       { return { x,y, w:28, h:54, type:'terminal', used:false }; }
function makeBridge(x,y,w)       { return { x,y, w, h:TILE, type:'bridge', segments:buildBridgeSegs(x,y,w), alive:true }; }
function makeFieldRed(x,y,w,h)   { return { x,y,w,h, type:'field_red'  }; }
function makeFieldBlue(x,y,w,h,targetX,targetY) { return { x,y,w,h, type:'field_blue', targetX, targetY }; }
function makeGravWave(x,y,w,h,dir) { return { x,y,w,h, type:'grav_wave', dir, strength:1400 }; }
function makeGoal(x,y)           { return { x,y, w:36, h:72, type:'goal' }; }
function makeDrone(x,y,patrol)   { return { x,y, w:24, h:18, vx:60, vy:0, patrol, gravDir:1, alive:true, hitFlash:0 }; }

function buildBridgeSegs(bx,by,bw) {
  const segs = [];
  const count = Math.ceil(bw / TILE);
  for (let i=0; i<count; i++) {
    segs.push({ x:bx+i*TILE, y:by, w:TILE, h:TILE, falling:false, vy:0, alpha:1 });
  }
  return segs;
}

// ─────────────────────────────────────────────
// LEVEL 1 — Нижние Уровни (Lower Depths)
// Tutorial: jump → gravity flip → anchor bridge crossing
// ─────────────────────────────────────────────
function buildLevel1() {
  const platforms = [
    // Main floor
    makePlatform(   0, FLOOR_Y, 2300, TILE),
    makePlatform(2500, FLOOR_Y, 1700, TILE),
    makePlatform(4400, FLOOR_Y, 2900, TILE),
    // Main ceiling
    makePlatform(   0,       0, 7400, CEIL_H),
    // Floating platforms (mid)
    makePlatform( 320, 256,  96, TILE),
    makePlatform( 550, 192,  64, TILE),
    makePlatform( 820, 256, 128, TILE),
    makePlatform(1100, 192,  96, TILE),
    makePlatform(1350, 256,  80, TILE),
    makePlatform(1650, 192,  96, TILE),
    makePlatform(1950, 256, 128, TILE),
    // Ceiling platforms (hooks for gravity-flip)
    makePlatform( 620,  32, 160, TILE),
    makePlatform( 900,  32, 128, TILE),
    makePlatform(1200,  32, 160, TILE),
    makePlatform(1500,  32, 128, TILE),
    makePlatform(2700, 256, 128, TILE),
    makePlatform(3000, 192,  96, TILE),
    makePlatform(3300, 256, 160, TILE),
    makePlatform(3600, 192, 128, TILE),
    makePlatform(4000,  32, 200, TILE),
    makePlatform(4700, 256,  96, TILE),
    makePlatform(5100, 192, 128, TILE),
    makePlatform(5500, 256,  96, TILE),
    makePlatform(5900, 192, 128, TILE),
    makePlatform(6300, 256, 160, TILE),
    makePlatform(6700, 192,  96, TILE),
  ];

  const hazards = [
    // Floor spikes
    makeSpike( 420, FLOOR_Y-20, 20, 20),
    makeSpike( 760, FLOOR_Y-20, 20, 20),
    makeSpike(1050, FLOOR_Y-20, 20, 20),
    makeSpike(1300, FLOOR_Y-20, 20, 20),
    makeSpike(1600, FLOOR_Y-20, 20, 20),
    makeSpike(1900, FLOOR_Y-20, 20, 20),
    makeSpike(2150, FLOOR_Y-20, 20, 20),
    // After gap
    makeSpike(2700, FLOOR_Y-20, 20, 20),
    makeSpike(2900, FLOOR_Y-20, 20, 20),
    makeSpike(3100, FLOOR_Y-20, 20, 20),
    makeSpike(3400, FLOOR_Y-20, 20, 20),
    makeSpike(3700, FLOOR_Y-20, 20, 20),
    makeSpike(4000, FLOOR_Y-20, 20, 20),
    // Ceiling spikes
    makeSpike( 700, CEIL_H, 20, 20),
    makeSpike(1100, CEIL_H, 20, 20),
    makeSpike(1400, CEIL_H, 20, 20),
    makeSpike(1800, CEIL_H, 20, 20),
    makeSpike(3200, CEIL_H, 20, 20),
    makeSpike(3700, CEIL_H, 20, 20),
    // Lasers
    makeLaserH(4600, 160, 200),
    makeLaserH(5200, 280, 180),
    makeLaserH(5800, 160, 200),
    // Gravity wave zones
    makeGravWave(6000, CEIL_H, 300, CVS_H - CEIL_H - TILE, -1),
  ];

  const bridges = [
    makeBridge(2300, FLOOR_Y, 200),
  ];

  const terminals = [
    makeTerminal(2200, FLOOR_Y - 54),
    makeTerminal(5000, FLOOR_Y - 54),
  ];

  // Fields — put in hazards so collision + rendering both work
  hazards.push(makeFieldRed( 4500, 200, 60, 168));
  hazards.push(makeFieldBlue(6500, 160, 60, 180, 6600, 120));

  const enemies = [
    makeDrone( 900, FLOOR_Y - 18, { minX: 800, maxX:1100, surface:'floor' }),
    makeDrone(1600, FLOOR_Y - 18, { minX:1500, maxX:1800, surface:'floor' }),
    makeDrone(1100,       CEIL_H, { minX: 950, maxX:1300, surface:'ceil'  }),
    makeDrone(2800, FLOOR_Y - 18, { minX:2700, maxX:3000, surface:'floor' }),
    makeDrone(3300,       CEIL_H, { minX:3100, maxX:3500, surface:'ceil'  }),
    makeDrone(4700, FLOOR_Y - 18, { minX:4600, maxX:5000, surface:'floor' }),
    makeDrone(5400,       CEIL_H, { minX:5200, maxX:5700, surface:'ceil'  }),
    makeDrone(6000, FLOOR_Y - 18, { minX:5900, maxX:6300, surface:'floor' }),
    makeDrone(6600,       CEIL_H, { minX:6400, maxX:6800, surface:'ceil'  }),
  ];

  const goal = makeGoal(7100, FLOOR_Y - 72);

  return {
    id: 1,
    name: 'Нижние Уровни',
    subtitle: 'LOWER DEPTHS',
    startX: 80, startY: FLOOR_Y - PH,
    levelW: 7500,
    platforms, hazards, bridges, terminals, enemies, goal,
    introTip: 'SHIFT: flip gravity   X: anchor',
  };
}

// ─────────────────────────────────────────────
// LEVEL 2 — Индустриальные Трущобы (Industrial Slums)
// ─────────────────────────────────────────────
function buildLevel2() {
  const platforms = [
    makePlatform(   0, FLOOR_Y, 1800, TILE),
    makePlatform(1950, FLOOR_Y,  800, TILE),
    makePlatform(2900, FLOOR_Y, 1500, TILE),
    makePlatform(4600, FLOOR_Y,  700, TILE),
    makePlatform(5500, FLOOR_Y, 3500, TILE),
    makePlatform(   0,       0, 9100, CEIL_H),
    // Floating
    makePlatform( 280, 256,  80, TILE),
    makePlatform( 520, 192,  80, TILE),
    makePlatform( 780, 256,  64, TILE),
    makePlatform(1050, 192,  96, TILE),
    makePlatform(1400, 256,  96, TILE),
    makePlatform(1700,  32, 200, TILE),
    makePlatform(2100, 256,  96, TILE),
    makePlatform(2500, 192,  64, TILE),
    makePlatform(3100, 256,  96, TILE),
    makePlatform(3500, 192,  80, TILE),
    makePlatform(3900, 256, 128, TILE),
    makePlatform(4200, 192,  80, TILE),
    makePlatform(4800,  32, 200, TILE),
    makePlatform(5100, 256, 128, TILE),
    makePlatform(5600, 192,  96, TILE),
    makePlatform(5900, 256,  64, TILE),
    makePlatform(6200, 192,  96, TILE),
    makePlatform(6500, 256, 128, TILE),
    makePlatform(6900,  32, 200, TILE),
    makePlatform(7200, 256,  96, TILE),
    makePlatform(7500, 192,  80, TILE),
    makePlatform(7800, 256, 128, TILE),
    makePlatform(8200, 192,  96, TILE),
  ];

  const h = [];
  // Floor spikes — denser pattern
  for (const sx of [300,480,700,920,1150,1380,1600,2100,2300,2500,3000,3200,3500,3800,4100,4700,5100,5400,5700,6000,6300,6600,7000,7400,7800,8200]) {
    h.push(makeSpike(sx, FLOOR_Y-20, 20, 20));
  }
  // Ceiling spikes
  for (const sx of [500,800,1100,1500,1900,2300,2700,3100,3600,4100,4600,5200,5700,6200,6700,7200,7700]) {
    h.push(makeSpike(sx, CEIL_H, 20, 20));
  }
  // Lasers — more and faster
  h.push(makeLaserH( 800,  60, 200));
  h.push(makeLaserH(1300, 290, 200));
  h.push(makeLaserV(2000,  32, 340));
  h.push(makeLaserH(2700, 130, 220));
  h.push(makeLaserH(3300, 270, 200));
  h.push(makeLaserV(4000,  32, 340));
  h.push(makeLaserH(4700, 100, 200));
  h.push(makeLaserH(5300, 260, 220));
  h.push(makeLaserV(6000,  32, 340));
  h.push(makeLaserH(6500, 150, 200));
  h.push(makeLaserH(7200,  60, 220));
  h.push(makeLaserV(7800,  32, 340));
  h.push(makeLaserH(8200, 200, 180));
  // Gravity waves
  h.push(makeGravWave(2900, CEIL_H, 350, CVS_H - CEIL_H - TILE, -1));
  h.push(makeGravWave(5600, CEIL_H, 400, CVS_H - CEIL_H - TILE,  1));
  h.push(makeGravWave(7600, CEIL_H, 300, CVS_H - CEIL_H - TILE, -1));

  const bridges = [
    makeBridge(1800, FLOOR_Y, 150),
    makeBridge(2750, FLOOR_Y, 150),
    makeBridge(4400, FLOOR_Y, 200),
  ];

  const terminals = [
    makeTerminal(1700, FLOOR_Y - 54),
    makeTerminal(4400, FLOOR_Y - 54),
    makeTerminal(7400, FLOOR_Y - 54),
  ];

  // Fields — add to h so collision + rendering both work
  h.push(makeFieldRed (1300, 100, 60, 290));
  h.push(makeFieldRed (5800, 100, 60, 290));
  h.push(makeFieldBlue(3700, 160, 60, 180, 3800, 120));
  h.push(makeFieldBlue(6800, 160, 60, 180, 6900, 120));

  const enemies = [];
  for (const [ex, ey, mn, mx, surf] of [
    [ 600, FLOOR_Y-18,  500, 700,  'floor'],
    [1100,      CEIL_H, 900,1300,  'ceil' ],
    [1700, FLOOR_Y-18, 1600,1900,  'floor'],
    [2200, FLOOR_Y-18, 2100,2500,  'floor'],
    [2700,      CEIL_H, 2500,2900, 'ceil' ],
    [3200, FLOOR_Y-18, 3100,3500,  'floor'],
    [3700,      CEIL_H, 3500,3900, 'ceil' ],
    [4200, FLOOR_Y-18, 4100,4500,  'floor'],
    [4800, FLOOR_Y-18, 4700,5100,  'floor'],
    [5300,      CEIL_H, 5100,5500, 'ceil' ],
    [5900, FLOOR_Y-18, 5700,6100,  'floor'],
    [6400,      CEIL_H, 6200,6600, 'ceil' ],
    [6800, FLOOR_Y-18, 6700,7000,  'floor'],
    [7300,      CEIL_H, 7100,7500, 'ceil' ],
    [7700, FLOOR_Y-18, 7600,7900,  'floor'],
    [8100,      CEIL_H, 7900,8300, 'ceil' ],
  ]) {
    enemies.push(makeDrone(ex, ey, { minX:mn, maxX:mx, surface:surf }));
  }

  const goal = makeGoal(8700, FLOOR_Y - 72);

  return {
    id: 2,
    name: 'Индустриальные Трущобы',
    subtitle: 'INDUSTRIAL SLUMS',
    startX: 80, startY: FLOOR_Y - PH,
    levelW: 9100,
    platforms, hazards: h, bridges, terminals, enemies, goal,
    bgTint: '#060410',
    introTip: 'Lasers flash — time your crossing',
  };
}

// ─────────────────────────────────────────────
// LEVEL 3 — Верхние Сферы (Upper Spheres)
// Hardest — ends at the Architect boss arena
// ─────────────────────────────────────────────
function buildLevel3() {
  const platforms = [
    makePlatform(   0, FLOOR_Y, 1200, TILE),
    makePlatform(1300, FLOOR_Y,  800, TILE),
    makePlatform(2300, FLOOR_Y, 1200, TILE),
    makePlatform(3700, FLOOR_Y,  700, TILE),
    makePlatform(4600, FLOOR_Y, 1400, TILE),
    makePlatform(6200, FLOOR_Y,  600, TILE),
    makePlatform(7000, FLOOR_Y, 3500, TILE),
    makePlatform(   0,       0,10600, CEIL_H),
    // Floating mid-platforms
    makePlatform( 250, 224,  80, TILE),
    makePlatform( 450, 160,  64, TILE),
    makePlatform( 700, 224,  96, TILE),
    makePlatform( 950, 160,  80, TILE),
    makePlatform(1400, 224,  96, TILE),
    makePlatform(1700, 160,  64, TILE),
    makePlatform(2000, 224,  80, TILE),
    makePlatform(2400, 224,  96, TILE),
    makePlatform(2700, 160,  80, TILE),
    makePlatform(3000, 224, 128, TILE),
    makePlatform(3800, 224,  64, TILE),
    makePlatform(4100, 160,  96, TILE),
    makePlatform(4400, 224,  80, TILE),
    makePlatform(4700, 224,  96, TILE),
    makePlatform(5000, 160,  80, TILE),
    makePlatform(5400, 224,  96, TILE),
    makePlatform(5700,  32, 160, TILE),
    makePlatform(6300, 224,  64, TILE),
    makePlatform(6600, 160,  80, TILE),
    makePlatform(7100, 224,  96, TILE),
    makePlatform(7400, 160,  80, TILE),
    makePlatform(7700, 224, 128, TILE),
    makePlatform(8100, 160,  96, TILE),
    makePlatform(8500, 224, 128, TILE),
    makePlatform(8900, 160,  96, TILE),
    makePlatform(9300, 224,  80, TILE),
    makePlatform(9600,  32, 200, TILE),
  ];

  const h = [];
  for (const sx of [350,550,750,1000,1350,1600,1850,2200,2600,2900,3300,3600,3900,4200,4500,4800,5100,5500,5800,6100,6500,6900,7200,7600,8000,8400,8800,9200,9700]) {
    h.push(makeSpike(sx, FLOOR_Y-20, 20, 20));
  }
  for (const sx of [400,700,1000,1400,1800,2200,2600,3000,3500,4000,4500,5000,5500,6000,6500,7000,7500,8000,8500,9000,9500]) {
    h.push(makeSpike(sx, CEIL_H, 20, 20));
  }
  // Dense lasers
  for (const [x,y,len,vert] of [
    [ 600,  32,340,true ], [ 900,200,160,false],
    [1400,  32,340,true ], [1800,140,180,false],
    [2100,  32,340,true ], [2500,220,180,false],
    [2900,  32,340,true ], [3200, 80,200,false],
    [3500,  32,340,true ], [3900,200,180,false],
    [4300,  32,340,true ], [4700,120,200,false],
    [5200,  32,340,true ], [5600,200,160,false],
    [6100,  32,340,true ], [6600,140,180,false],
    [7100,  32,340,true ], [7500, 80,200,false],
    [8000,  32,340,true ], [8400,180,200,false],
    [8900,  32,340,true ], [9300,120,180,false],
  ]) {
    h.push(vert ? makeLaserV(x,y,len) : makeLaserH(x,y,len));
  }
  // Gravity waves
  h.push(makeGravWave(1200, CEIL_H, 400, CVS_H - CEIL_H - TILE, -1));
  h.push(makeGravWave(3000, CEIL_H, 350, CVS_H - CEIL_H - TILE,  1));
  h.push(makeGravWave(5000, CEIL_H, 400, CVS_H - CEIL_H - TILE, -1));
  h.push(makeGravWave(6800, CEIL_H, 300, CVS_H - CEIL_H - TILE,  1));
  h.push(makeGravWave(8500, CEIL_H, 400, CVS_H - CEIL_H - TILE, -1));
  // Red/blue fields
  h.push(makeFieldRed (1100, 100, 60, 290));
  h.push(makeFieldRed (4000, 100, 60, 290));
  h.push(makeFieldRed (7600, 100, 60, 290));
  h.push(makeFieldBlue(2500, 160, 60, 180, 2600, 120));
  h.push(makeFieldBlue(5500, 160, 60, 180, 5600, 120));
  h.push(makeFieldBlue(9000, 160, 60, 180, 9100, 120));

  const bridges = [
    makeBridge(1200, FLOOR_Y, 100),
    makeBridge(2200, FLOOR_Y, 100),
    makeBridge(3600, FLOOR_Y, 100),
    makeBridge(4500, FLOOR_Y, 100),
    makeBridge(6100, FLOOR_Y, 100),
  ];

  const terminals = [
    makeTerminal(1250, FLOOR_Y - 54),
    makeTerminal(3650, FLOOR_Y - 54),
    makeTerminal(6150, FLOOR_Y - 54),
    makeTerminal(9000, FLOOR_Y - 54),
  ];

  const enemies = [];
  for (const [ex, ey, mn, mx, surf] of [
    [ 400, FLOOR_Y-18,  300, 500, 'floor'],
    [ 700,      CEIL_H,  600, 900, 'ceil' ],
    [1100, FLOOR_Y-18, 1000,1200, 'floor'],
    [1500,      CEIL_H, 1300,1700, 'ceil' ],
    [1900, FLOOR_Y-18, 1800,2100, 'floor'],
    [2300, FLOOR_Y-18, 2200,2500, 'floor'],
    [2700,      CEIL_H, 2500,2900, 'ceil' ],
    [3100, FLOOR_Y-18, 3000,3300, 'floor'],
    [3500,      CEIL_H, 3300,3700, 'ceil' ],
    [4000, FLOOR_Y-18, 3900,4200, 'floor'],
    [4500,      CEIL_H, 4300,4700, 'ceil' ],
    [4900, FLOOR_Y-18, 4800,5100, 'floor'],
    [5300,      CEIL_H, 5100,5500, 'ceil' ],
    [5800, FLOOR_Y-18, 5700,6000, 'floor'],
    [6300,      CEIL_H, 6200,6500, 'ceil' ],
    [6700, FLOOR_Y-18, 6600,6900, 'floor'],
    [7200,      CEIL_H, 7100,7400, 'ceil' ],
    [7700, FLOOR_Y-18, 7600,7900, 'floor'],
    [8100,      CEIL_H, 8000,8300, 'ceil' ],
    [8600, FLOOR_Y-18, 8500,8800, 'floor'],
    [9100,      CEIL_H, 9000,9300, 'ceil' ],
    [9600, FLOOR_Y-18, 9500,9800, 'floor'],
  ]) {
    enemies.push(makeDrone(ex, ey, { minX:mn, maxX:mx, surface:surf }));
  }

  const goal = makeGoal(10100, FLOOR_Y - 72);

  return {
    id: 3,
    name: 'Верхние Сферы',
    subtitle: 'UPPER SPHERES',
    startX: 80, startY: FLOOR_Y - PH,
    levelW: 10700,
    platforms, hazards: h, bridges, terminals, enemies, goal,
    bgTint: '#040810',
    introTip: 'Use anchors to survive the gauntlet!',
  };
}

const LEVEL_BUILDERS = [buildLevel1, buildLevel2, buildLevel3];

// ── PLAYER ───────────────────────────────────────────────────
class Player {
  constructor(x, y) {
    this.reset(x, y);
  }

  reset(x, y) {
    this.x = x;
    this.y = y;
    this.vx = 0;
    this.vy = 0;
    this.gravDir  = 1;   // 1=down, -1=up
    this.grounded = false;
    this.dead     = false;
    this.anchors  = [];   // active anchor objects
    this.anchorsLeft = MAX_ANCHORS;
    // Visual trail
    this.trail = [];
    // Flip/jump cooldowns
    this._flipCd  = 0;
    this._jumpCd  = 0;
    this._anchCd  = 0;
    // Ghost data (replay of last run)
    this.ghostTrail   = [];
    this.recordTrail  = [];
  }

  get color() { return this.gravDir === 1 ? COL.playerDown : COL.playerUp; }

  update(dt, level) {
    // ── INPUT ──
    const jumpNow  = anyOnce('Space','ArrowUp','KeyW');
    const flipNow  = anyOnce('ShiftLeft','ShiftRight','KeyZ');
    const anchorNow= anyOnce('KeyX','KeyQ');
    const restart  = held('KeyR');

    if (restart) { this.dead = true; return; }

    this._flipCd  = Math.max(0, this._flipCd  - dt);
    this._jumpCd  = Math.max(0, this._jumpCd  - dt);
    this._anchCd  = Math.max(0, this._anchCd  - dt);

    // Gravity flip
    if (flipNow && this._flipCd <= 0) {
      this.gravDir *= -1;
      this.vy *= -0.4;
      this.grounded = false;
      this._flipCd = 0.12;
    }

    // Jump
    if (jumpNow && this.grounded && this._jumpCd <= 0) {
      this.vy = -JUMP_V * this.gravDir;
      this.grounded = false;
      this._jumpCd = 0.1;
    }

    // Anchor
    if (anchorNow && this._anchCd <= 0) {
      this._handleAnchorInput(level);
      this._anchCd = 0.15;
    }

    // ── PHYSICS ──
    this.vx = MOVE_SPEED;
    this.vy += GRAVITY * this.gravDir * dt;
    this.vy  = clamp(this.vy, -MAX_FALL, MAX_FALL);

    // X move
    this.x += this.vx * dt;
    // Clamp left edge (don't go back)
    if (this.x < 0) { this.x = 0; }

    // Y move
    this.y += this.vy * dt;

    // ── PLATFORM COLLISION (Y) ──
    this.grounded = false;

    // Build a live platform list (bridges contribute active segments)
    const allPlats = [...level.platforms];
    for (const b of level.bridges) {
      if (!b.alive) continue;
      for (const s of b.segments) {
        if (s.alpha > 0.5 && !s.falling) allPlats.push(s);
      }
    }

    for (const p of allPlats) {
      if (!aabb(this.x, this.y, PW, PH, p.x, p.y, p.w, p.h)) continue;
      if (this.gravDir === 1) {
        // Landing on top
        if (this.vy >= 0 && this.y + PH - this.vy*dt <= p.y + 4) {
          this.y = p.y - PH;
          this.vy = 0;
          this.grounded = true;
        } else if (this.vy < 0 && this.y - this.vy*dt >= p.y + p.h - 4) {
          this.y = p.y + p.h;
          this.vy = 0;
        }
      } else {
        // Gravity up — hang on bottom
        if (this.vy <= 0 && this.y - this.vy*dt >= p.y + p.h - 4) {
          this.y = p.y + p.h;
          this.vy = 0;
          this.grounded = true;
        } else if (this.vy > 0 && this.y + PH - this.vy*dt <= p.y + 4) {
          this.y = p.y - PH;
          this.vy = 0;
        }
      }
    }

    // ── BOUNDS ──
    if (this.y + PH > CVS_H + 40 || this.y < -40) {
      this.dead = true;
    }

    // ── HAZARD COLLISION ──
    for (const h of level.hazards) {
      if (h.type === 'spike' || h.type === 'field_red') {
        if (aabb(this.x+4, this.y+4, PW-8, PH-8, h.x, h.y, h.w, h.h)) {
          this.dead = true;
        }
      }
      if ((h.type === 'laser_h' || h.type === 'laser_v') && h.active) {
        if (aabb(this.x+4, this.y+4, PW-8, PH-8, h.x, h.y, h.w, h.h)) {
          this.dead = true;
        }
      }
      if (h.type === 'field_blue') {
        if (aabb(this.x+4, this.y+4, PW-8, PH-8, h.x, h.y, h.w, h.h)) {
          this.x = h.targetX;
          this.y = h.targetY;
          this.vy = 0;
        }
      }
      if (h.type === 'grav_wave') {
        if (aabb(this.x, this.y, PW, PH, h.x, h.y, h.w, h.h)) {
          this.vy += h.dir * h.strength * dt;
        }
      }
    }

    // ── TERMINAL COLLISION ──
    for (const t of level.terminals) {
      if (!t.used && aabb(this.x, this.y, PW, PH, t.x, t.y, t.w, t.h)) {
        this.anchorsLeft = MAX_ANCHORS;
        // Also restore anchors array
        this.anchors = [];
        t.used = true;
      }
    }

    // ── DRONE COLLISION ──
    for (const d of level.enemies) {
      if (!d.alive) continue;
      if (aabb(this.x+2, this.y+2, PW-4, PH-4, d.x, d.y, d.w, d.h)) {
        this.dead = true;
      }
    }

    // ── BRIDGE TRIGGER ──
    for (const b of level.bridges) {
      if (!b.alive) continue;
      for (const s of b.segments) {
        if (s.falling || s.alpha <= 0) continue;
        if (aabb(this.x, this.y + PH, PW, 4, s.x, s.y, s.w, 4)) {
          s.falling = true;
          s.vy = 0;
        }
      }
    }

    // ── UPDATE ANCHORS ──
    this._updateAnchors(dt, level);

    // ── TRAIL ──
    this.recordTrail.push({ x: this.x + PW/2, y: this.y + PH/2, g: this.gravDir, t: 0 });
    for (const t of this.trail) t.t += dt;
    this.trail = this.trail.filter(t => t.t < 0.25);
    this.trail.push({ x: this.x + PW/2, y: this.y + PH/2, g: this.gravDir, t: 0 });
  }

  _handleAnchorInput(level) {
    // Check if we have a stuck anchor to activate
    const stuck = this.anchors.find(a => a.stuck && a.alive);
    if (stuck) {
      this._pullToAnchor(stuck);
      return;
    }
    // Throw new anchor if we have quota
    if (this.anchorsLeft <= 0) return;
    const throwVy = this.gravDir === 1 ? -ANCHOR_THROW_V * 0.7 : ANCHOR_THROW_V * 0.7;
    const a = {
      x:    this.x + PW / 2,
      y:    this.y + PH / 2,
      vx:   ANCHOR_THROW_V,
      vy:   throwVy,
      alive: true,
      stuck: false,
      age:   0,
    };
    this.anchors.push(a);
    this.anchorsLeft--;
  }

  _pullToAnchor(a) {
    const dx = a.x - (this.x + PW/2);
    const dy = a.y - (this.y + PH/2);
    const dist = Math.hypot(dx, dy) || 1;
    this.vx = (dx/dist) * ANCHOR_PULL_V;
    this.vy = (dy/dist) * ANCHOR_PULL_V;
    a.alive = false;
  }

  _updateAnchors(dt, level) {
    const allPlats = [...level.platforms];
    for (const b of level.bridges) {
      if (!b.alive) continue;
      for (const s of b.segments) {
        if (!s.falling) allPlats.push(s);
      }
    }

    for (const a of this.anchors) {
      if (!a.alive) continue;
      a.age += dt;
      if (a.age > 8) { a.alive = false; continue; }
      if (a.stuck)   continue;

      a.x += a.vx * dt;
      a.y += a.vy * dt;
      a.vy += GRAVITY * 0.3 * dt; // light gravity on anchor

      // Stick to walls / ceiling / floor
      for (const p of allPlats) {
        if (aabb(a.x-4, a.y-4, 8, 8, p.x, p.y, p.w, p.h)) {
          a.stuck = true;
          a.vx = 0; a.vy = 0;
          break;
        }
      }
      if (a.y < 0)         { a.y = 0; a.stuck = true; a.vx = 0; a.vy = 0; }
      if (a.y > CVS_H)     { a.y = CVS_H; a.stuck = true; a.vx = 0; a.vy = 0; }
      if (a.x < 0 || a.x > level.levelW + CVS_W) a.alive = false;
    }

    this.anchors = this.anchors.filter(a => a.alive);
  }
}

// ── BRIDGE UPDATE ─────────────────────────────────────────────
function updateBridges(bridges, dt) {
  for (const b of bridges) {
    for (const s of b.segments) {
      if (!s.falling) continue;
      s.vy += GRAVITY * 0.8 * dt;
      s.y  += s.vy * dt;
      s.alpha = Math.max(0, 1 - s.y / 600);
    }
  }
}

// ── DRONE UPDATE ─────────────────────────────────────────────
function updateDrones(drones, playerGravDir, dt) {
  for (const d of drones) {
    if (!d.alive) continue;

    // Match player gravity
    d.gravDir = playerGravDir;
    const surfY = d.gravDir === 1
      ? FLOOR_Y - d.h
      : CEIL_H;
    d.y = surfY;

    // Patrol
    d.x += d.vx * dt;
    if (d.x < d.patrol.minX || d.x > d.patrol.maxX - d.w) {
      d.vx *= -1;
    }

    // Flash
    if (d.hitFlash > 0) d.hitFlash -= dt;
  }
}

// ── LASER UPDATE ─────────────────────────────────────────────
function updateLasers(hazards, dt) {
  for (const h of hazards) {
    if (h.type !== 'laser_h' && h.type !== 'laser_v') continue;
    h.timer += dt;
    if (h.timer >= h.period) h.timer -= h.period;
    h.active = h.timer < h.period / 2;
  }
}

// ── CAMERA ───────────────────────────────────────────────────
class Camera {
  constructor() { this.x = 0; this.y = 0; }

  follow(px, levelW) {
    const targetX = px - CVS_W * 0.3;
    this.x = clamp(targetX, 0, Math.max(0, levelW - CVS_W));
  }
}

// ── RENDERER ─────────────────────────────────────────────────
function glow(color, blur) {
  ctx.shadowColor = color;
  ctx.shadowBlur  = blur;
}
function noGlow() {
  ctx.shadowColor = 'transparent';
  ctx.shadowBlur  = 0;
}

function drawBackground(cam, levelData) {
  // Sky gradient
  const grad = ctx.createLinearGradient(0,0,0,CVS_H);
  grad.addColorStop(0, '#040412');
  grad.addColorStop(1, '#090920');
  ctx.fillStyle = grad;
  ctx.fillRect(0,0,CVS_W,CVS_H);

  // Distant city silhouette (parallax 0.2)
  const px = -cam.x * 0.18;
  ctx.fillStyle = '#0b0b1e';
  const buildings = [
    [0,  260,70, 140], [80, 280,50,120], [140,240,80,160], [240,270,60,130],
    [310,255,90,145], [420,275,50,125], [480,250,70,150], [570,260,80,140],
    [660,280,60,120], [730,265,75,135], [810,275,55,125], [880,258,85,142],
    [970,270,65,130],[1050,285,45,115],[1100,255,80,145],
  ];
  for (const [bx,by,bw,bh] of buildings) {
    ctx.fillRect(((bx + px) % (CVS_W+200)) - 100, by, bw, bh);
  }

  // Faint scanlines
  ctx.fillStyle = 'rgba(0,0,40,0.18)';
  for (let y=0; y<CVS_H; y+=4) {
    ctx.fillRect(0, y, CVS_W, 2);
  }
}

function drawPlatform(p, camX) {
  const sx = p.x - camX;
  if (sx + p.w < -10 || sx > CVS_W + 10) return;

  ctx.fillStyle = COL.platform;
  ctx.fillRect(sx, p.y, p.w, p.h);
  // Neon edge top
  glow(COL.platGlow, 8);
  ctx.fillStyle = COL.platEdge;
  ctx.fillRect(sx, p.y, p.w, 2);
  // Neon edge bottom
  ctx.fillRect(sx, p.y + p.h - 2, p.w, 2);
  noGlow();
}

function drawBridge(b, camX) {
  for (const s of b.segments) {
    if (s.alpha <= 0) continue;
    const sx = s.x - camX;
    ctx.globalAlpha = s.alpha;
    ctx.fillStyle   = COL.bridge;
    ctx.fillRect(sx, s.y, s.w, s.h);
    glow(COL.bridgeEdge, 6);
    ctx.fillStyle = COL.bridgeEdge;
    ctx.fillRect(sx, s.y, s.w, 2);
    noGlow();
    ctx.globalAlpha = 1;
  }
}

function drawSpike(h, camX) {
  const sx = h.x - camX;
  if (sx+h.w < -5 || sx > CVS_W+5) return;
  glow(COL.spikeGlow, 10);
  ctx.fillStyle = COL.spike;
  ctx.beginPath();
  const tip = h.y < FLOOR_Y / 2
    ? h.y + h.h  // ceiling spike → tip points down
    : h.y;       // floor spike → tip points up
  const base = h.y < FLOOR_Y / 2 ? h.y : h.y + h.h;
  ctx.moveTo(sx + h.w/2, tip);
  ctx.lineTo(sx,         base);
  ctx.lineTo(sx + h.w,   base);
  ctx.closePath();
  ctx.fill();
  noGlow();
}

function drawLaser(h, camX) {
  const sx = h.x - camX;
  if (sx + h.w < -10 || sx > CVS_W + 10) return;
  if (!h.active) {
    ctx.fillStyle = 'rgba(255,60,0,0.18)';
    ctx.fillRect(sx, h.y, h.w, h.h);
  } else {
    glow(COL.laserBeam, 20);
    ctx.fillStyle = COL.laserBeam;
    ctx.fillRect(sx, h.y, h.w, h.h);
    // Bright core
    glow('#fff', 6);
    ctx.fillStyle = '#fff8f0';
    if (h.type === 'laser_h') {
      ctx.fillRect(sx, h.y + h.h/2 - 1, h.w, 2);
    } else {
      ctx.fillRect(sx + h.w/2 - 1, h.y, 2, h.h);
    }
    noGlow();
  }
}

function drawField(h, camX) {
  const sx = h.x - camX;
  if (sx + h.w < -5 || sx > CVS_W + 5) return;
  ctx.fillStyle = h.type === 'field_red' ? COL.fieldRed : COL.fieldBlue;
  ctx.fillRect(sx, h.y, h.w, h.h);
  const glowC = h.type === 'field_red' ? '#ff2040' : '#2040ff';
  glow(glowC, 12);
  ctx.strokeStyle = glowC;
  ctx.lineWidth   = 2;
  ctx.strokeRect(sx, h.y, h.w, h.h);
  noGlow();
}

function drawTerminal(t, camX) {
  const sx = t.x - camX;
  if (t.used) {
    ctx.fillStyle = '#101828';
    ctx.fillRect(sx, t.y, t.w, t.h);
    return;
  }
  glow(COL.termGlow, 14);
  ctx.fillStyle = '#0a2014';
  ctx.fillRect(sx, t.y, t.w, t.h);
  ctx.fillStyle = COL.terminal;
  ctx.font = 'bold 18px Courier New';
  ctx.textAlign = 'center';
  ctx.fillText('⊕', sx + t.w/2, t.y + t.h - 10);
  // Blinking indicator
  if (Math.floor(Date.now()/400) % 2 === 0) {
    ctx.fillStyle = COL.terminal;
    ctx.fillRect(sx + 4, t.y + 4, t.w - 8, 4);
  }
  noGlow();
  ctx.textAlign = 'left';
}

function drawGravWave(h, camX, time) {
  const sx = h.x - camX;
  if (sx + h.w < -5 || sx > CVS_W + 5) return;
  ctx.fillStyle = COL.waveFill;
  ctx.fillRect(sx, h.y, h.w, h.h);
  // Ripple lines
  glow(COL.waveGlow, 6);
  ctx.strokeStyle = 'rgba(180,0,255,0.4)';
  ctx.lineWidth   = 1;
  const period = 24;
  const offset = (time * 40) % period;
  for (let dy = offset; dy < h.h; dy += period) {
    ctx.beginPath();
    ctx.moveTo(sx, h.y + dy);
    ctx.lineTo(sx + h.w, h.y + dy);
    ctx.stroke();
  }
  noGlow();
}

function drawGoal(g, camX, time) {
  const sx = g.x - camX;
  const pulse = 0.7 + 0.3 * Math.sin(time * 4);
  glow(COL.goalGlow, 20 * pulse);
  ctx.fillStyle = COL.goal;
  ctx.fillRect(sx, g.y, g.w, g.h);
  // Inner portal swirl
  ctx.fillStyle = '#002838';
  ctx.fillRect(sx+6, g.y+6, g.w-12, g.h-12);
  glow(COL.goalGlow, 12);
  ctx.strokeStyle = COL.goal;
  ctx.lineWidth   = 2;
  ctx.strokeRect(sx, g.y, g.w, g.h);
  // GOAL label
  ctx.fillStyle = COL.goal;
  ctx.font = 'bold 10px Courier New';
  ctx.textAlign = 'center';
  ctx.fillText('EXIT', sx + g.w/2, g.y + g.h/2 + 4);
  noGlow();
  ctx.textAlign = 'left';
}

function drawDrone(d, camX, time) {
  if (!d.alive) return;
  const sx = d.x - camX;
  if (sx + d.w < -10 || sx > CVS_W + 10) return;
  const pulse = 0.7 + 0.3 * Math.sin(time * 6 + d.x);
  glow(COL.droneGlow, 12 * pulse);
  ctx.fillStyle = d.hitFlash > 0 ? '#fff' : COL.drone;
  // Body
  ctx.fillRect(sx, d.y, d.w, d.h);
  // Eye
  ctx.fillStyle = '#fff';
  ctx.fillRect(sx + d.w/2 - 3, d.y + 5, 6, 6);
  ctx.fillStyle = '#000';
  ctx.fillRect(sx + d.w/2 - 1, d.y + 7, 3, 3);
  noGlow();
}

function drawAnchor(a, camX, time) {
  const sx = a.x - camX;
  const pulse = 0.7 + 0.3 * Math.sin(time * 8);
  glow(COL.anchorGlow, a.stuck ? 16 * pulse : 8);
  ctx.fillStyle = COL.anchor;
  ctx.beginPath();
  ctx.arc(sx, a.y, 6, 0, Math.PI*2);
  ctx.fill();
  if (a.stuck) {
    ctx.strokeStyle = COL.anchor;
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.arc(sx, a.y, 10, 0, Math.PI*2);
    ctx.stroke();
  }
  noGlow();
}

function drawPlayer(player, camX, time) {
  const sx = player.x - camX;

  // Ghost trail
  for (const t of player.trail) {
    const alpha = (1 - t.t / 0.25) * 0.35;
    ctx.globalAlpha = alpha;
    ctx.fillStyle = t.g === 1 ? COL.playerDown : COL.playerUp;
    ctx.fillRect(t.x - camX - PW/2, t.y - PH/2, PW, PH);
  }
  ctx.globalAlpha = 1;

  // Main body
  const glowC = player.color;
  glow(glowC, 22);
  ctx.fillStyle = COL.playerFill;
  ctx.fillRect(sx, player.y, PW, PH);

  // Neon outline
  glow(glowC, 10);
  ctx.strokeStyle = glowC;
  ctx.lineWidth   = 2;
  ctx.strokeRect(sx, player.y, PW, PH);

  // Eye / visor
  const eyeY = player.gravDir === 1 ? player.y + 6 : player.y + PH - 10;
  ctx.fillStyle = glowC;
  ctx.fillRect(sx + 4, eyeY, PW - 8, 4);

  // Gravity direction indicator chevron
  ctx.fillStyle = glowC;
  const cy = player.gravDir === 1 ? player.y + PH + 4 : player.y - 8;
  ctx.beginPath();
  ctx.moveTo(sx + PW/2, cy + (player.gravDir === 1 ? 4 : -4));
  ctx.lineTo(sx + PW/2 - 6, cy);
  ctx.lineTo(sx + PW/2 + 6, cy);
  ctx.closePath();
  ctx.fill();
  noGlow();
}

function drawGhostTrail(ghostTrail, camX) {
  if (!ghostTrail.length) return;
  ctx.globalAlpha = 0.18;
  for (const pt of ghostTrail) {
    ctx.fillStyle = pt.g === 1 ? COL.playerDown : COL.playerUp;
    ctx.fillRect(pt.x - camX - PW/2, pt.y - PH/2, PW, PH);
  }
  ctx.globalAlpha = 1;
}

function drawHUD(player, levelData) {
  // Gravity indicator
  const arrow = document.getElementById('grav-arrow');
  if (player.gravDir === 1) {
    arrow.textContent = '↓';
    arrow.classList.remove('up');
  } else {
    arrow.textContent = '↑';
    arrow.classList.add('up');
  }

  // Anchor dots
  for (let i=0; i<MAX_ANCHORS; i++) {
    const dot = document.getElementById('adot'+i);
    if (dot) dot.classList.toggle('empty', i >= player.anchorsLeft);
  }

  // Level label
  document.getElementById('level-label').textContent = levelData.subtitle;

  // Tip
  const tipEl = document.getElementById('hud-tip');
  if (tipEl && levelData.introTip) {
    tipEl.textContent = levelData.introTip;
  }
}

// ── GAME STATE MACHINE ────────────────────────────────────────
const STATE = { MENU:0, PLAYING:1, DEAD:2, WIN:3, COMPLETE:4 };

class Game {
  constructor() {
    this.state      = STATE.MENU;
    this.levelIndex = 0;
    this.levelData  = null;
    this.player     = null;
    this.camera     = new Camera();
    this.time       = 0;
    this._lastGhost = [];

    this._bindUI();
  }

  _bindUI() {
    const $ = id => document.getElementById(id);
    $('btn-play')    .onclick = () => this.startLevel(0);
    $('btn-retry')   .onclick = () => this.startLevel(this.levelIndex);
    $('btn-menu-d')  .onclick = () => this.showMenu();
    $('btn-next')    .onclick = () => {
      const next = this.levelIndex + 1;
      if (next < LEVEL_BUILDERS.length) {
        this.startLevel(next);
      } else {
        this._showScreen('screen-complete');
      }
    };
    $('btn-menu-w')  .onclick = () => this.showMenu();
    $('btn-restart') .onclick = () => this.startLevel(0);
  }

  showMenu() {
    this.state = STATE.MENU;
    document.getElementById('hud').classList.add('hidden');
    this._showScreen('screen-menu');
  }

  startLevel(index) {
    this.levelIndex = index;
    this.levelData  = LEVEL_BUILDERS[index]();
    this.player     = new Player(this.levelData.startX, this.levelData.startY);
    this.player.ghostTrail = this._lastGhost.slice();
    this.camera     = new Camera();
    this.time       = 0;
    this.state      = STATE.PLAYING;

    this._showScreen(null);
    document.getElementById('hud').classList.remove('hidden');
  }

  _showScreen(id) {
    ['screen-menu','screen-dead','screen-win','screen-complete'].forEach(s => {
      document.getElementById(s).classList.remove('active');
    });
    if (id) document.getElementById(id).classList.add('active');
  }

  update(dt) {
    if (this.state !== STATE.PLAYING) return;

    this.time += dt;

    const lv = this.levelData;
    const pl = this.player;

    // Update subsystems
    updateBridges(lv.bridges, dt);
    updateDrones(lv.enemies, pl.gravDir, dt);
    updateLasers(lv.hazards, dt);

    // Update player
    pl.update(dt, lv);

    // Camera
    this.camera.follow(pl.x, lv.levelW);

    // Goal check
    if (!pl.dead && aabb(pl.x, pl.y, PW, PH, lv.goal.x, lv.goal.y, lv.goal.w, lv.goal.h)) {
      this._levelComplete();
      return;
    }

    // Death
    if (pl.dead) {
      this._lastGhost = pl.recordTrail.slice();
      this.state = STATE.DEAD;
      document.getElementById('death-msg').textContent =
        'Level ' + (this.levelIndex + 1) + ' — Retry?';
      this._showScreen('screen-dead');
    }
  }

  _levelComplete() {
    this._lastGhost = this.player.recordTrail.slice();
    this.state = STATE.WIN;
    const messages = [
      'Кей покинул Нижние Уровни!',
      'Промышленные трущобы позади!',
      'Сестра ждёт тебя на Верхних Сферах!',
    ];
    document.getElementById('win-msg').textContent =
      messages[this.levelIndex] || 'Sector cleared!';

    if (this.levelIndex + 1 >= LEVEL_BUILDERS.length) {
      // Last level — go to complete
      this._showScreen('screen-complete');
    } else {
      this._showScreen('screen-win');
    }
  }

  render() {
    if (this.state !== STATE.PLAYING) return;

    const lv = this.levelData;
    const pl = this.player;
    const cam = this.camera;

    // Background
    drawBackground(cam, lv);

    // Ghost (best run replay)
    drawGhostTrail(pl.ghostTrail, cam.x);

    // Gravity wave zones
    for (const h of lv.hazards) {
      if (h.type === 'grav_wave') drawGravWave(h, cam.x, this.time);
    }

    // Fields
    for (const h of lv.hazards) {
      if (h.type === 'field_red' || h.type === 'field_blue') drawField(h, cam.x);
    }

    // Bridges
    for (const b of lv.bridges) drawBridge(b, cam.x);

    // Platforms
    for (const p of lv.platforms) drawPlatform(p, cam.x);

    // Hazards
    for (const h of lv.hazards) {
      if (h.type === 'spike')   drawSpike(h, cam.x);
      if (h.type === 'laser_h' || h.type === 'laser_v') drawLaser(h, cam.x);
    }

    // Terminals
    for (const t of lv.terminals) drawTerminal(t, cam.x);

    // Goal
    drawGoal(lv.goal, cam.x, this.time);

    // Enemies
    for (const d of lv.enemies) drawDrone(d, cam.x, this.time);

    // Anchors
    for (const a of pl.anchors) drawAnchor(a, cam.x, this.time);

    // Player
    drawPlayer(pl, cam.x, this.time);

    // HUD
    drawHUD(pl, lv);

    // Level progress bar (bottom edge)
    const progress = clamp(pl.x / lv.levelW, 0, 1);
    ctx.fillStyle = 'rgba(0,0,0,0.5)';
    ctx.fillRect(0, CVS_H - 3, CVS_W, 3);
    glow(COL.platGlow, 4);
    ctx.fillStyle = COL.platGlow;
    ctx.fillRect(0, CVS_H - 3, CVS_W * progress, 3);
    noGlow();
  }
}

// ── MAIN LOOP ────────────────────────────────────────────────
const game = new Game();
let lastTime = null;
const MAX_DT  = 1/20; // cap at 20fps minimum

function loop(ts) {
  requestAnimationFrame(loop);
  if (lastTime === null) { lastTime = ts; return; }
  const dt = Math.min((ts - lastTime) / 1000, MAX_DT);
  lastTime = ts;

  ctx.clearRect(0, 0, CVS_W, CVS_H);

  game.update(dt);
  game.render();
}

requestAnimationFrame(loop);

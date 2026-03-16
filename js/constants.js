/**
 * Game constants – building definitions, resource types, game config.
 */

/* ─── Resources ───────────────────────────────────────────────────────────── */
const RESOURCES = ['gold', 'food', 'wood', 'stone', 'tools', 'goods'];

const RESOURCE_ICONS = {
    gold:  '🪙', food:  '🌾', wood:  '🪵',
    stone: '🪨', tools: '⚒️',  goods: '📦',
};

const RESOURCE_NAMES = {
    gold: 'Золото', food: 'Еда', wood: 'Дерево',
    stone: 'Камень', tools: 'Инструменты', goods: 'Товары',
};

/* ─── Building types ──────────────────────────────────────────────────────── */
const BUILDING_DEFS = {
    /* ── Housing ─────────────────────────────────────────────────────────── */
    cottage: {
        name: 'Хижина', category: 'housing', emoji: '🏠',
        color: '#c9956a', borderColor: '#8B5E3C',
        cost: { gold: 50, wood: 10 },
        size: { w: 44, h: 44 },
        maxResidents: 2, taxPerResident: 3,
        description: 'Скромное жильё для 2 жителей. Даёт небольшой налог.',
        unlockDay: 1,
    },
    house: {
        name: 'Дом', category: 'housing', emoji: '🏡',
        color: '#d4a373', borderColor: '#8B5E3C',
        cost: { gold: 100, wood: 20 },
        size: { w: 52, h: 52 },
        maxResidents: 4, taxPerResident: 5,
        description: 'Уютный дом для 4 жителей.',
        unlockDay: 3,
    },
    mansion: {
        name: 'Особняк', category: 'housing', emoji: '🏰',
        color: '#e8c99a', borderColor: '#8B5E3C',
        cost: { gold: 400, wood: 60, stone: 30 },
        size: { w: 72, h: 72 },
        maxResidents: 6, taxPerResident: 20,
        description: 'Роскошное жильё для знати. Высокий налог, но жители требовательны.',
        unlockDay: 15,
    },

    /* ── Food ────────────────────────────────────────────────────────────── */
    farm: {
        name: 'Ферма', category: 'food', emoji: '🌾',
        color: '#95c17a', borderColor: '#4a7c39',
        cost: { gold: 80, wood: 20 },
        size: { w: 64, h: 56 },
        maxWorkers: 3, produces: { food: 8 }, interval: 10,
        description: 'Производит еду. Нужны рабочие.',
        unlockDay: 1,
    },
    hunting: {
        name: 'Охотничий домик', category: 'food', emoji: '🏹',
        color: '#7da568', borderColor: '#4a7c39',
        cost: { gold: 60, wood: 15 },
        size: { w: 48, h: 48 },
        maxWorkers: 2, produces: { food: 5 }, interval: 12,
        description: 'Охотники добывают дичь в лесу.',
        unlockDay: 1,
    },
    fishery: {
        name: 'Рыбацкая хижина', category: 'food', emoji: '🎣',
        color: '#6aaccc', borderColor: '#2a7090',
        cost: { gold: 70, wood: 18 },
        size: { w: 48, h: 52 },
        maxWorkers: 2, produces: { food: 6 }, interval: 11,
        description: 'Рыбаки ловят рыбу в реках и озёрах.',
        unlockDay: 2,
    },

    /* ── Industry ─────────────────────────────────────────────────────────── */
    lumbermill: {
        name: 'Лесопилка', category: 'industry', emoji: '🪓',
        color: '#a0785a', borderColor: '#6b4226',
        cost: { gold: 100, wood: 10, tools: 5 },
        size: { w: 60, h: 56 },
        maxWorkers: 3, produces: { wood: 10 }, interval: 10,
        description: 'Заготавливает древесину.',
        unlockDay: 2,
    },
    quarry: {
        name: 'Каменоломня', category: 'industry', emoji: '⛏️',
        color: '#9c9c8e', borderColor: '#666660',
        cost: { gold: 120, wood: 20, tools: 8 },
        size: { w: 64, h: 56 },
        maxWorkers: 4, produces: { stone: 8 }, interval: 12,
        description: 'Добывает камень для строительства.',
        unlockDay: 3,
    },
    smithy: {
        name: 'Кузница', category: 'industry', emoji: '⚒️',
        color: '#8a6a4a', borderColor: '#4a3020',
        cost: { gold: 150, stone: 20, wood: 15 },
        size: { w: 56, h: 56 },
        maxWorkers: 2, produces: { tools: 6 }, consumes: { wood: 3 }, interval: 15,
        description: 'Кует инструменты и оружие.',
        unlockDay: 5,
    },
    mine: {
        name: 'Шахта', category: 'industry', emoji: '⛏️',
        color: '#7a6a5a', borderColor: '#4a3a2a',
        cost: { gold: 200, wood: 30, tools: 15 },
        size: { w: 60, h: 60 },
        maxWorkers: 5, produces: { stone: 12, tools: 3 }, interval: 14,
        description: 'Глубокая шахта — больше ресурсов, больше риска.',
        unlockDay: 10,
    },

    /* ── Commerce ─────────────────────────────────────────────────────────── */
    market: {
        name: 'Рынок', category: 'commerce', emoji: '🏪',
        color: '#e8b84b', borderColor: '#b8880b',
        cost: { gold: 200, wood: 40, stone: 20 },
        size: { w: 72, h: 64 },
        maxWorkers: 4, produces: { goods: 5, gold: 10 }, consumes: { food: 2, tools: 1 }, interval: 20,
        description: 'Торговый рынок. Торговцы привлекают путешественников.',
        unlockDay: 6,
    },
    tavern: {
        name: 'Таверна', category: 'commerce', emoji: '🍺',
        color: '#c07a30', borderColor: '#7a4a10',
        cost: { gold: 150, wood: 30, stone: 10 },
        size: { w: 56, h: 56 },
        maxWorkers: 3, happinessBonus: 8, produces: { gold: 6 }, consumes: { food: 2 }, interval: 18,
        description: 'Таверна поднимает настроение жителям и приносит доход.',
        unlockDay: 4,
    },

    /* ── Civic ────────────────────────────────────────────────────────────── */
    townhall: {
        name: 'Ратуша', category: 'civic', emoji: '🏛️',
        color: '#c9a84c', borderColor: '#8a6800',
        cost: { gold: 500, wood: 80, stone: 60 },
        size: { w: 80, h: 80 },
        unique: true, unlockLaws: true, happinessBonus: 5,
        description: 'Центр управления городом. Открывает законы и указы.',
        unlockDay: 1,
    },
    church: {
        name: 'Церковь', category: 'civic', emoji: '⛪',
        color: '#d4c5a9', borderColor: '#9a8a6a',
        cost: { gold: 300, wood: 40, stone: 60 },
        size: { w: 64, h: 72 },
        happinessBonus: 12,
        description: 'Церковь приносит духовное спокойствие и счастье жителям.',
        unlockDay: 8,
    },
    school: {
        name: 'Школа', category: 'civic', emoji: '📚',
        color: '#8ab4d4', borderColor: '#4a7494',
        cost: { gold: 250, wood: 50, stone: 30 },
        size: { w: 64, h: 60 },
        maxWorkers: 2, skillBonus: 0.2, happinessBonus: 6,
        description: 'Школа повышает навыки жителей и открывает новые пути.',
        unlockDay: 10,
    },
    castle: {
        name: 'Замок', category: 'civic', emoji: '🏰',
        color: '#a09080', borderColor: '#605040',
        cost: { gold: 1000, stone: 150, wood: 50 },
        size: { w: 100, h: 100 },
        unique: true, prestigeBonus: 20, happinessBonus: 15,
        description: 'Величественный замок — символ процветания и мощи.',
        unlockDay: 20,
    },
    well: {
        name: 'Колодец', category: 'civic', emoji: '🪣',
        color: '#7ab4d4', borderColor: '#3a7494',
        cost: { gold: 40, stone: 10 },
        size: { w: 28, h: 28 },
        happinessBonus: 3,
        description: 'Обеспечивает жителей чистой водой.',
        unlockDay: 1,
    },
    garden: {
        name: 'Сад', category: 'civic', emoji: '🌳',
        color: '#68b468', borderColor: '#2a742a',
        cost: { gold: 60, wood: 5 },
        size: { w: 52, h: 52 },
        happinessBonus: 6,
        description: 'Красивый сад радует жителей и украшает город.',
        unlockDay: 1,
    },
};

/* ─── Laws / Decrees ──────────────────────────────────────────────────────── */
const LAW_DEFS = {
    education: {
        name: 'Обязательное образование',
        cost: { gold: 100 },
        upkeep: { gold: 5 },
        effect: 'skillBonus +0.3, happiness +5',
        description: 'Все дети посещают школу. Жители умнее, дети наследуют больше навыков.',
        requires: 'school',
    },
    support_poor: {
        name: 'Поддержка бедных',
        cost: { gold: 50 },
        upkeep: { gold: 8 },
        effect: 'happiness +10 для бедных',
        description: 'Государство помогает беднякам. Их счастье растёт, но казна тощает.',
        requires: null,
    },
    market_tariff: {
        name: 'Торговые пошлины',
        cost: { gold: 0 },
        upkeep: { gold: 0 },
        effect: 'gold +15/day, happiness -3 для торговцев',
        description: 'Налог с торговцев на рынке. Доход растёт, но торговцы недовольны.',
        requires: 'market',
    },
    night_watch: {
        name: 'Ночная стража',
        cost: { gold: 80 },
        upkeep: { gold: 10 },
        effect: 'crime -30, happiness +5',
        description: 'Стражники патрулируют улицы ночью. Преступность снижается.',
        requires: null,
    },
    festival: {
        name: 'Ежегодный праздник',
        cost: { gold: 150 },
        upkeep: { gold: 15 },
        effect: 'happiness +20 раз в сезон',
        description: 'Ежегодный городской праздник поднимает настрой всех жителей.',
        requires: 'townhall',
    },
};

/* ─── Career / Skills ─────────────────────────────────────────────────────── */
const CAREERS = {
    idle:    { name: 'Безработный',  emoji: '😴', skill: null },
    farmer:  { name: 'Фермер',       emoji: '👨‍🌾', skill: 'farming' },
    hunter:  { name: 'Охотник',      emoji: '🏹', skill: 'hunting' },
    fisher:  { name: 'Рыбак',        emoji: '🎣', skill: 'fishing' },
    logger:  { name: 'Лесоруб',      emoji: '🪓', skill: 'logging' },
    miner:   { name: 'Шахтёр',       emoji: '⛏️', skill: 'mining' },
    smith:   { name: 'Кузнец',       emoji: '⚒️', skill: 'smithing' },
    trader:  { name: 'Торговец',     emoji: '🛒', skill: 'trading' },
    innkeeper: { name: 'Трактирщик', emoji: '🍺', skill: 'innkeeping' },
    builder: { name: 'Строитель',    emoji: '👷', skill: 'building' },
    scholar: { name: 'Учёный',       emoji: '📚', skill: 'scholarship' },
    noble:   { name: 'Знать',        emoji: '👑', skill: 'governance' },
    priest:  { name: 'Священник',    emoji: '⛪', skill: 'religion' },
};

const BUILDING_TO_CAREER = {
    farm: 'farmer', hunting: 'hunter', fishery: 'fisher',
    lumbermill: 'logger', quarry: 'miner', mine: 'miner',
    smithy: 'smith', market: 'trader', tavern: 'innkeeper',
    school: 'scholar', church: 'priest',
    townhall: 'noble', castle: 'noble',
};

/* ─── Game config ─────────────────────────────────────────────────────────── */
const CONFIG = {
    worldWidth: 2400,
    worldHeight: 2000,
    tileSize: 32,
    initialGold: 500,
    initialResources: { food: 60, wood: 40, stone: 20, tools: 10, goods: 0 },
    ticksPerDay: 120,        // game ticks in one "day"
    baseHappiness: 70,
    foodPerResident: 0.02,   // food consumed per tick per resident
    roadCost: 2,             // gold per road segment
    minHappinessAlert: 30,
    maxPopulation: 500,

    // Demolish refund rates (fraction of original cost returned)
    demolishRefundWood:  0.4,
    demolishRefundStone: 0.4,
    demolishRefundGold:  0.2,

    // Market tariff daily income (when law is active)
    marketTariffDailyIncome: 15,

    // Minimum margin (px) for buildability checks
    buildableCheckMargin: 4,
};

/* ─── Terrain tile types ──────────────────────────────────────────────────── */
const TERRAIN = {
    DEEP_WATER: 0, WATER: 1, SAND: 2, GRASS: 3,
    FOREST: 4,     HILL: 5,  MOUNTAIN: 6,
};

const TERRAIN_COLORS = {
    [TERRAIN.DEEP_WATER]: '#1a4d7a',
    [TERRAIN.WATER]:      '#2a7abc',
    [TERRAIN.SAND]:       '#d4c17a',
    [TERRAIN.GRASS]:      '#5a9a44',
    [TERRAIN.FOREST]:     '#2d6a2d',
    [TERRAIN.HILL]:       '#9a8a6a',
    [TERRAIN.MOUNTAIN]:   '#7a7a7a',
};

/* ─── Colour palettes for buildings ──────────────────────────────────────── */
const SEASON_COLORS = {
    spring: { grass: '#5ab84a', tree: '#2d7a2d' },
    summer: { grass: '#4a9a3a', tree: '#1d6a1d' },
    autumn: { grass: '#9a8a4a', tree: '#c07a30' },
    winter: { grass: '#c8d8e8', tree: '#8898a8' },
};

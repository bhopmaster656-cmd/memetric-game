'use strict';

const CONFIG = {
  GRID_COLS: 6,
  GRID_ROWS: 5,
  CELL_SIZE: 80,
  CELL_PAD: 6,
  STARTING_CREDITS: 50,
  INCOME_INTERVAL: 1000,
  SAVE_INTERVAL: 15000,
  SAVE_KEY: 'neocity_v2',
  BASE_COST: 10,
  COST_GROWTH: 1.18,
  SELL_RATIO: 0.5,
  MAX_TIER: 10,
};

/* Building definitions — tiers 1-10.
 * Colors are vivid, saturated values suited for solid 3-D box rendering. */
const BUILDINGS = [
  {
    id: 1,
    name: 'Нано-Под',
    color: '#29b6f6',   // sky blue
    incomePerSec: 1,
    desc: 'Минимальный жилой модуль ИИ-эпохи',
  },
  {
    id: 2,
    name: 'Дата-Узел',
    color: '#ab47bc',   // vivid purple
    incomePerSec: 4,
    desc: 'Базовый узел обработки данных',
  },
  {
    id: 3,
    name: 'Нейро-Ячейка',
    color: '#26c6da',   // teal
    incomePerSec: 12,
    desc: 'Ячейка нейронной сети',
  },
  {
    id: 4,
    name: 'Квантум-Хаб',
    color: '#ffa726',   // orange
    incomePerSec: 36,
    desc: 'Квантовый вычислительный узел',
  },
  {
    id: 5,
    name: 'Голо-Башня',
    color: '#ec407a',   // hot pink
    incomePerSec: 108,
    desc: 'Голографическая башня связи',
  },
  {
    id: 6,
    name: 'ИИ-Ядро',
    color: '#42a5f5',   // vivid blue
    incomePerSec: 324,
    desc: 'Ядро искусственного интеллекта',
  },
  {
    id: 7,
    name: 'Кибер-Нексус',
    color: '#ff7043',   // deep orange
    incomePerSec: 972,
    desc: 'Кибернетический узел связи',
  },
  {
    id: 8,
    name: 'Тех-Шпиль',
    color: '#5c6bc0',   // indigo
    incomePerSec: 2916,
    desc: 'Передовой технологический шпиль',
  },
  {
    id: 9,
    name: 'Сингулярность',
    color: '#ce93d8',   // soft violet
    incomePerSec: 8748,
    desc: 'Узел технологической сингулярности',
  },
  {
    id: 10,
    name: 'Нео-Центр',
    color: '#ffca28',   // golden amber
    incomePerSec: 26244,
    desc: 'Эпицентр города будущего',
  },
];

const QUESTS = [
  { id: 1, text: 'Постройте первое здание', target: 'builds', value: 1, reward: 20 },
  { id: 2, text: 'Объедините 2 здания', target: 'merges', value: 1, reward: 50 },
  { id: 3, text: 'Достигните уровня 3 (Нейро-Ячейка)', target: 'tier', value: 3, reward: 100 },
  { id: 4, text: 'Накопите 500 кредитов', target: 'credits', value: 500, reward: 200 },
  { id: 5, text: 'Постройте 10 зданий', target: 'builds', value: 10, reward: 300 },
  { id: 6, text: 'Достигните уровня 5 (Голо-Башня)', target: 'tier', value: 5, reward: 800 },
  { id: 7, text: 'Объедините 10 зданий', target: 'merges', value: 10, reward: 1500 },
  { id: 8, text: 'Достигните уровня 7 (Кибер-Нексус)', target: 'tier', value: 7, reward: 5000 },
  { id: 9, text: 'Постройте 30 зданий', target: 'builds', value: 30, reward: 10000 },
  { id: 10, text: 'Достигните Нео-Центра (уровень 10)!', target: 'tier', value: 10, reward: 50000 },
];

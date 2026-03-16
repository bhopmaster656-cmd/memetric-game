/**
 * Random events – moral dilemmas, city crises, opportunities.
 * Each event has a title, description, and 2-3 choices with effects.
 */

const EVENT_POOL = [
    {
        id: 'refugees',
        title: '🏃 Беженцы у ворот',
        desc: 'К вашему городу подошли беженцы из разорённой деревни. Они голодны и измотаны. Принять их?',
        choices: [
            {
                text: '✅ Принять всех',
                effect: { food: -30, population: +8, happiness: +5, gold: -20 },
                outcome: 'Беженцы обустроились. Город стал больше, но еды поубавилось.',
            },
            {
                text: '🔸 Принять только ремесленников',
                effect: { food: -10, population: +3, happiness: -5 },
                outcome: 'Мастеровые влились в ряды горожан. Остальные ушли восвояси.',
            },
            {
                text: '❌ Прогнать',
                effect: { happiness: -10, gold: 0 },
                outcome: 'Ворота закрыты. Беженцы ушли, проклиная город.',
            },
        ],
        minDay: 10, weight: 8,
    },
    {
        id: 'plague',
        title: '☠️ Хворь в городе',
        desc: 'По городу распространилась болезнь. Несколько жителей слегли с лихорадкой.',
        choices: [
            {
                text: '💊 Потратить золото на знахаря',
                effect: { gold: -80, happiness: +10 },
                outcome: 'Знахарь остановил болезнь. Жители благодарны.',
            },
            {
                text: '🔒 Карантин (заблокировать торговлю)',
                effect: { gold: -30, happiness: -5 },
                outcome: 'Карантин сработал, но торговля встала.',
            },
            {
                text: '🙏 Молиться и ждать',
                effect: { happiness: -20, population: -3 },
                outcome: 'Несколько жителей не пережили болезнь. Народ ропщет.',
            },
        ],
        minDay: 20, weight: 5,
    },
    {
        id: 'merchant',
        title: '🛒 Богатый купец',
        desc: 'В город прибыл богатый купец. Он предлагает сделку: купит весь ваш запас дерева за тройную цену.',
        choices: [
            {
                text: '💰 Продать весь лес',
                effect: { wood: -50, gold: +150, happiness: +5 },
                outcome: 'Отличная сделка! Казна пополнена. Строительство немного замедлится.',
            },
            {
                text: '🔸 Продать половину',
                effect: { wood: -25, gold: +75 },
                outcome: 'Разумный выбор. Купец доволен, запасы сохранены.',
            },
            {
                text: '❌ Отказать',
                effect: { happiness: -3 },
                outcome: 'Купец уехал ни с чем. Жители шептались о упущенной возможности.',
            },
        ],
        minDay: 5, weight: 10,
    },
    {
        id: 'fire',
        title: '🔥 Пожар!',
        desc: 'В одном из кварталов вспыхнул пожар! Нужно срочно реагировать.',
        choices: [
            {
                text: '🚒 Бросить всех на тушение',
                effect: { gold: -50, happiness: +3, wood: -10 },
                outcome: 'Пожар потушен с минимальным ущербом. Жители хвалят правителя.',
            },
            {
                text: '💰 Нанять пожарных бригадиров',
                effect: { gold: -120, happiness: +8 },
                outcome: 'Профессионалы справились быстро. Ни один дом не пострадал.',
            },
            {
                text: '😐 Ждать — само потухнет',
                effect: { happiness: -15, population: -2, wood: -5 },
                outcome: 'Огонь уничтожил несколько домов. Жители в ярости.',
            },
        ],
        minDay: 15, weight: 6,
    },
    {
        id: 'drought',
        title: '☀️ Засуха',
        desc: 'Лето выдалось небывало жарким. Поля высыхают, урожай под угрозой.',
        choices: [
            {
                text: '🪣 Прорыть ирригационные каналы',
                effect: { gold: -100, stone: -20, food: +50 },
                outcome: 'Каналы спасли урожай. Фермеры вздохнули с облегчением.',
            },
            {
                text: '📦 Закупить еду у соседей',
                effect: { gold: -60, food: +80 },
                outcome: 'Закупка обошлась дорого, но голод предотвращён.',
            },
            {
                text: '🙏 Объявить пост и молебен',
                effect: { food: -20, happiness: -8 },
                outcome: 'Молебен не помог природе. Запасы еды сократились.',
            },
        ],
        minDay: 30, weight: 7,
    },
    {
        id: 'inventor',
        title: '⚙️ Известный изобретатель',
        desc: 'В город прибыл знаменитый изобретатель. Он готов обустроить мастерскую в обмен на ресурсы и поддержку.',
        choices: [
            {
                text: '🏗️ Обеспечить его всем',
                effect: { gold: -80, tools: -20, happiness: +10 },
                outcome: 'Изобретатель открыл мастерскую. Производство инструментов возросло на 20%.',
            },
            {
                text: '❌ Отказать',
                effect: { happiness: -5 },
                outcome: 'Изобретатель уехал в соседний город. Обидно...',
            },
        ],
        minDay: 25, weight: 4,
    },
    {
        id: 'festival_proposal',
        title: '🎉 Предложение праздника',
        desc: 'Горожане хотят устроить ярмарку. Это поднимет настроение, но потребует ресурсов.',
        choices: [
            {
                text: '🎊 Устроить пышный праздник',
                effect: { gold: -100, food: -30, goods: -10, happiness: +25 },
                outcome: 'Праздник удался! Весь город гуляет и веселится.',
            },
            {
                text: '🔸 Скромная ярмарка',
                effect: { gold: -30, food: -10, happiness: +12 },
                outcome: 'Небольшой праздник прошёл хорошо. Все довольны.',
            },
            {
                text: '❌ Сейчас не время',
                effect: { happiness: -5 },
                outcome: 'Жители разочарованы. Настроение упало.',
            },
        ],
        minDay: 15, weight: 9,
    },
    {
        id: 'bandits',
        title: '⚔️ Налётчики!',
        desc: 'Банда разбойников появилась у городских стен. Торговые пути под угрозой.',
        choices: [
            {
                text: '⚔️ Снарядить стражу',
                effect: { gold: -60, tools: -10, happiness: +8 },
                outcome: 'Стража отогнала бандитов. Торговля возобновилась.',
            },
            {
                text: '💰 Откупиться',
                effect: { gold: -100, happiness: -5 },
                outcome: 'Дорого, но мирно. Бандиты ушли с выкупом.',
            },
            {
                text: '🙈 Игнорировать',
                effect: { gold: -40, happiness: -12, goods: -20 },
                outcome: 'Разбойники ограбили торговый обоз. Потери значительные.',
            },
        ],
        minDay: 20, weight: 6,
    },
    {
        id: 'noble_visit',
        title: '👑 Визит вельможи',
        desc: 'К вам прибыл знатный вельможа из столицы. Он оценит ваш город и расскажет королю.',
        choices: [
            {
                text: '🎁 Устроить пышный приём',
                effect: { gold: -150, goods: -20, happiness: +15 },
                outcome: 'Вельможа уехал в восторге. Репутация города выросла.',
            },
            {
                text: '🍽️ Скромно принять',
                effect: { gold: -40, food: -15 },
                outcome: 'Приём прошёл нормально. Отношения с двором нейтральны.',
            },
            {
                text: '😑 Принять холодно',
                effect: { happiness: -8 },
                outcome: 'Вельможа уехал недовольным. Жители смущены грубостью.',
            },
        ],
        minDay: 35, weight: 5,
    },
    {
        id: 'mine_accident',
        title: '⛏️ Обвал в шахте',
        desc: 'В шахте произошёл обвал. Несколько шахтёров заперты под землёй.',
        choices: [
            {
                text: '🚨 Немедленно начать спасение',
                effect: { gold: -80, tools: -15, happiness: +10 },
                outcome: 'Спасатели вытащили всех шахтёров. Город облегчённо вздохнул.',
            },
            {
                text: '😢 Закрыть шахту — слишком опасно',
                effect: { happiness: -10, stone: -20 },
                outcome: 'Шахта закрыта. Семьи скорбят. Добыча камня упала.',
            },
        ],
        minDay: 25, weight: 4,
    },
];

class EventSystem extends EventEmitter {
    constructor() {
        super();
        this._pending   = [];      // queued events to show
        this._shown     = new Set();
        this._cooldown  = 0;
        this._minInterval = 45;    // days between events
    }

    tick(day, population) {
        this._cooldown = Math.max(0, this._cooldown - 1);
        if (this._cooldown > 0) return null;

        // Weigh events
        const available = EVENT_POOL.filter(e =>
            day >= e.minDay &&
            !this._shown.has(e.id) &&
            !this._pending.find(p => p.id === e.id)
        );

        if (available.length === 0) return null;

        // Random trigger (roughly every _minInterval days in game)
        const chance = population > 0 ? 0.008 + population * 0.00002 : 0.005;
        if (Math.random() > chance) return null;

        // Weighted pick
        const totalWeight = available.reduce((s, e) => s + (e.weight || 1), 0);
        let r = Math.random() * totalWeight;
        for (const e of available) {
            r -= (e.weight || 1);
            if (r <= 0) {
                this._pending.push(e);
                this._cooldown = this._minInterval;
                return e;
            }
        }
        return null;
    }

    /** Pop next pending event */
    next() { return this._pending.shift() || null; }
    hasPending() { return this._pending.length > 0; }

    /**
     * Apply choice effects to economy and residents.
     * Returns the outcome string.
     */
    applyChoice(event, choiceIndex, economy, residentManager) {
        const choice = event.choices[choiceIndex];
        if (!choice) return '';

        const eff = choice.effect || {};
        if (eff.gold   !== undefined) eff.gold   > 0 ? economy.add('gold', eff.gold) : economy.sub('gold', -eff.gold);
        if (eff.food   !== undefined) eff.food   > 0 ? economy.add('food', eff.food) : economy.sub('food', -eff.food);
        if (eff.wood   !== undefined) eff.wood   > 0 ? economy.add('wood', eff.wood) : economy.sub('wood', -eff.wood);
        if (eff.stone  !== undefined) eff.stone  > 0 ? economy.add('stone', eff.stone) : economy.sub('stone', -eff.stone);
        if (eff.tools  !== undefined) eff.tools  > 0 ? economy.add('tools', eff.tools) : economy.sub('tools', -eff.tools);
        if (eff.goods  !== undefined) eff.goods  > 0 ? economy.add('goods', eff.goods) : economy.sub('goods', -eff.goods);

        if (eff.happiness !== undefined) {
            for (const r of residentManager.alive()) {
                r.happiness = clamp(r.happiness + eff.happiness, 0, 100);
            }
        }
        if (eff.population !== undefined && eff.population > 0) {
            for (let i = 0; i < eff.population; i++) {
                residentManager.spawn(Math.random() < 0.5, [], []);
            }
        }
        if (eff.population !== undefined && eff.population < 0) {
            const alive = residentManager.alive();
            const toRemove = Math.min(-eff.population, alive.length - 1);
            for (let i = 0; i < toRemove; i++) {
                alive[i].alive = false;
            }
        }

        this._shown.add(event.id);
        this.emit('resolved', event, choiceIndex, choice.outcome);
        return choice.outcome;
    }

    getHistory() { return [...this._shown]; }
}

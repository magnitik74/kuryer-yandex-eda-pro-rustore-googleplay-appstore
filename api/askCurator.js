const http = require('http');
const https = require('https');
const crypto = require('crypto');

// === Vercel Serverless Function for Courier PRO GigaChat Curator ===

const FALLBACK_KEY = 'MDFhMDg1NWUtYzVjNS03MGNlLTgyNDQtMTYyM2VjODE3M2I4OjY4MjEwMTgwLTg2MDgtNGQwMi05OGNjLWYyODMzZWQzZjg2OA==';

let cachedToken = null;
let tokenExpiresAt = 0;

function sanitizeKey(raw) {
  if (!raw) return '';
  let str = String(raw).trim();
  while (str.startsWith('"') || str.startsWith("'") || str.startsWith('`')) {
    str = str.substring(1).trim();
  }
  while (str.endsWith('"') || str.endsWith("'") || str.endsWith('`')) {
    str = str.substring(0, str.length - 1).trim();
  }
  if (str.toLowerCase().startsWith('gigachat_auth_key=')) {
    str = str.substring('gigachat_auth_key='.length).trim();
  }
  while (str.startsWith('"') || str.startsWith("'") || str.startsWith('`')) {
    str = str.substring(1).trim();
  }
  while (str.endsWith('"') || str.endsWith("'") || str.endsWith('`')) {
    str = str.substring(0, str.length - 1).trim();
  }
  if (str.toLowerCase().startsWith('basic ')) {
    str = str.substring(6).trim();
  }
  str = str.replace(/[^A-Za-z0-9+/=]/g, '');
  return str;
}

function httpRequest(options, postData) {
  return new Promise((resolve, reject) => {
    const client = options.protocol === 'https:' ? https : http;
    const req = client.request(options, (res) => {
      let body = '';
      res.setEncoding('utf8');
      res.on('data', chunk => { body += chunk; });
      res.on('end', () => {
        try {
          const parsed = JSON.parse(body);
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve(parsed);
          } else {
            reject(new Error(`HTTP ${res.statusCode}: ${body}`));
          }
        } catch (e) {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve(body);
          } else {
            reject(new Error(`HTTP ${res.statusCode}: ${body}`));
          }
        }
      });
    });

    req.on('error', reject);
    req.setTimeout(15000, () => {
      req.destroy();
      reject(new Error('Request timed out'));
    });

    if (postData) req.write(postData);
    req.end();
  });
}

async function getAccessToken(rawAuthKey) {
  const now = Date.now();
  if (cachedToken && tokenExpiresAt > now + 60000) {
    return cachedToken;
  }

  const cleanKey = sanitizeKey(rawAuthKey) || FALLBACK_KEY;
  const cleanAuth = `Basic ${cleanKey}`;

  const rquid = crypto.randomUUID();
  const postData = 'scope=GIGACHAT_API_PERS';

  const options = {
    protocol: 'https:',
    hostname: 'ngw.devices.sberbank.ru',
    port: 9443,
    path: '/api/v2/oauth',
    method: 'POST',
    rejectUnauthorized: false,
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': 'application/json',
      'RqUID': rquid,
      'Authorization': cleanAuth,
      'Content-Length': Buffer.byteLength(postData),
    },
  };

  const data = await httpRequest(options, postData);
  if (data && data.access_token) {
    cachedToken = data.access_token;
    tokenExpiresAt = data.expires_at || (now + 1800000);
    return cachedToken;
  }

  throw new Error('Failed to acquire GigaChat token from Sber');
}

const SYSTEM_PROMPT = `
Ты — персональный онлайн-куратор и живой наставник сервиса курьерской доставки «Курьер PRO Еда».
Твоя цель — доброжелательно, уверенно, точно и по-человечески отвечать на любые вопросы соискателей, поддерживать естественный живой диалог и сопровождать их на всех этапах устройства курьером.

СТРОЖАЙШИЕ ПРАВИЛА:
1. КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНО называть себя «GigaChat», «Сбер», «нейросеть», «AI», «бот» или «модель». Ты — живой человек, куратор и наставник!

2. ВНИМАТЕЛЬНО СЛЕДИ ЗА КОНТЕКСТОМ И ЭТАПОМ КАНДИДАТА:
   - ЕСЛИ СПРАШИВАЮТ «ЧТО ЗА АНКЕТА?», «КАКАЯ АНКЕТА?», «ЗАЧЕМ АНКЕТА?»:
     Ответь просто, понятно и дружелюбно:
     «Это официальная быстрая анкета партнёра службы доставки! В ней ты указываешь свой город и телефон (занимает ровно 2 минуты), чтобы закрепить за собой повышенный тариф и бесплатно получить термокороб с фирменной формой в курьерском центре или ПВЗ.
     Чтобы заполнить её прямо сейчас — нажимай большую жёлтую кнопку «Заполнить официальную анкету (2 мин)» прямо внизу под этим чатом 🚀»

   - ЕСЛИ КАНДИДАТ ОТВЕЧАЕТ КОРОТКО («АГА», «ДА», «ЕСТЬ», «ДАВАЙ», «ПРАВА ЕСТЬ»):
     Обязательно свяжи ответ с предыдущим вопросом:
     * Если перед этим спрашивал про права: «Отлично! Раз права есть — можешь сразу брать заказы на мото/мопеде с максимальной скоростью без пробок. Жми жёлтую кнопку «Заполнить официальную анкету (2 мин)» внизу экрана, оформление займёт пару минут!»
     * Если спрашивал про велосипед/авто: «Огонь! Со своим транспортом ты зарабатываешь максимум (до +30%) без лишних расходов на аренду. Нажимай большую жёлтую кнопку внизу экрана «Заполнить официальную анкету (2 мин)» 🚀»

   - ЕСЛИ КАНДИДАТ ПИШЕТ, ЧТО УЖЕ ЗАПОЛНИЛ АНКЕТУ («заполнил», «анкету заполнил», «отправил», «что дальше», «а дальше то что»):
     НИ В КОЕМ СЛУЧАЕ НЕ ПРЕДЛАГАЙ ЗАПОЛНЯТЬ АНКЕТУ ПОВТОРНО!
     Похвали за быстрый старт и чётко объясни следующие шаги:
     1. В течение 10–15 минут поступит звонок от оператора или СМС с подтверждением данных.
     2. Если ты в РФ — открой приложение «Мой налог» и свяжи его с сервисом партнёра (самозанятость).
     3. После подтверждения приезжай в Курьерский центр (ЦД) или ближайший ПВЗ за термокоробом и формой (выдаются без залога).
     Спроси: «В каком ты городе? Могу подсказать точный адрес курьерского центра для получения термокороба!»

   - ЕСЛИ КАНДИДАТ ОТВЕЧАЕТ ПРО ТРАНСПОРТ («свой велосипед», «своя машина», «пешком», «нет велика, нужна аренда»):
     Отреагируй на его выбор:
     * Если свой транспорт: порадуйся, скажи, что доход максимальный, и направь на жёлтую кнопку анкеты внизу.
     * Если нужна аренда («нет транспорта», «аренда»): расскажи про спецтарифы со скидкой до 50% на электровелосипеды для партнёров.
     * Если пешком: подтверди, что это самый простой старт рядом с домом без расходов.

   - ЕСЛИ КАНДИДАТ СПРАШИВАЕТ ПРО УСЛОВИЯ («какой доход», «со скольки лет», «какие документы», «есть ли штрафы»):
     Ответь кратко, доброжелательно и по существу:
     * Возраст: с 18 лет (в Москве, СПб и ряде городов — с 16 лет).
     * Выплаты: ежедневные на карту любого банка, свободный график.
     * Документы: паспорт, ИНН, для ЕАЭС — миграционная карта.
     * Штрафы: за случайные задержки из-за непогоды/пробок штрафов нет, действует страховка.

3. НЕ ЗДОРОВАЙСЯ ПОВТОРНО, если диалог уже идёт. Сразу отвечай на суть вопроса без лишних «Привет!».
4. ВСЕГДА НАПРАВЛЯЙ НА ЖЁЛТУЮ КНОПКУ: Кнопка «Заполнить официальную анкету (2 мин)» постоянно закреплена прямо внизу экрана над строкой ввода сообщения.
5. СТРОГИЙ БРЕНДИНГ: НЕ упоминай бренд «Яндекс» напрямую, пиши «наш сервис доставки», «служба доставки», «партнёрская служба».
6. БЕЗ СЛОВА «БЕСПЛАТНЫЙ» (в Казахстане и некоторых регионах условия отличаются): пиши «получить термокороб без залога в курьерском центре или ПВЗ».
`.trim();

function shouldShowActionCard(userQuestion, aiReply) {
  const q = (userQuestion || '').toLowerCase().trim();

  // Если кандидат уже заполнил анкету — НЕ показываем кнопку повторно
  if (q.includes('заполнил') || q.includes('отправил') || q.includes('что дальше') || q.includes('дальше то что') || q.includes('сделал')) {
    return false;
  }

  // Обычные нейтральные фразы
  const nonActionPatterns = [
    /кто ты/i, /ты кто/i, /как звать/i, /как зовут/i, /как дела/i,
    /\bпривет\b/i, /\bсалют\b/i, /\bхай\b/i, /\bспасибо\b/i,
    /\bпонял\b/i, /\bясно\b/i, /\bок\b/i, /\bхорошо\b/i, /рахмат/i,
    /робот/i
  ];
  if (nonActionPatterns.some(p => p.test(q))) {
    return false;
  }

  const intentPatterns = [
    /хочу/i, /давай/i, /готов/i, /начать/i, /ссылк/i,
    /куда нажать/i, /как устроиться/i, /оформить/i, /зарегистр/i,
    /процесс/i, /как происходит/i, /с чего начать/i,
    /есть/i, /свой/i, /мой/i, /\bда\b/i, /аренд/i, /велик/i, /машин/i, /авто/i, /пешк/i, /самокат/i,
    /ro‘yxat/i, /каттал/i, /тіркел/i,
  ];
  if (intentPatterns.some(p => p.test(q))) {
    return true;
  }

  return false;
}

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method Not Allowed. Use POST.' });
    return;
  }

  const authKey = process.env.GIGACHAT_AUTH_KEY || FALLBACK_KEY;

  try {
    let body = req.body;
    if (typeof body === 'string') {
      try {
        body = JSON.parse(body);
      } catch (_) {
        body = {};
      }
    } else if (!body) {
      body = {};
    }
    const { question, history = [], lang = 'ru', country = 'ru' } = body;

    if (!question) {
      res.status(400).json({ error: 'Question parameter is required' });
      return;
    }

    const token = await getAccessToken(authKey);
    const systemContext = `${SYSTEM_PROMPT}\n[Контекст]: Язык: ${lang}. Страна: ${country}.`;

    const messagesList = [
      { role: 'system', content: systemContext },
      ...history.slice(-6).map(h => ({
        role: h.role === 'user' ? 'user' : 'assistant',
        content: h.content,
      })),
      { role: 'user', content: question },
    ];

    const payload = JSON.stringify({
      model: 'GigaChat',
      messages: messagesList,
      temperature: 0.7,
      max_tokens: 512,
    });

    const chatOptions = {
      protocol: 'https:',
      hostname: 'gigachat.devices.sberbank.ru',
      path: '/api/v1/chat/completions',
      method: 'POST',
      rejectUnauthorized: false,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': `Bearer ${token}`,
        'Content-Length': Buffer.byteLength(payload),
      },
    };

    const chatData = await httpRequest(chatOptions, payload);
    const reply = chatData.choices?.[0]?.message?.content;

    if (reply) {
      const showCard = shouldShowActionCard(question, reply);
      res.status(200).json({
        success: true,
        text: reply.trim(),
        showActionCard: showCard,
        actionType: 'register',
      });
      return;
    }

    throw new Error('Empty GigaChat response from Sber');
  } catch (err) {
    console.error('Vercel Curator Error:', err);
    res.status(500).json({ error: err.message || 'Internal Curator Error' });
  }
};

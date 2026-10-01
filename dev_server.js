const http = require('http');
const https = require('https');
const crypto = require('crypto');

const PORT = 8081;
const GIGACHAT_KEY = "MDFhMDg1NWUtYzVjNS03MGNlLTgyNDQtMTYyM2VjODE3M2I4OjY4MjEwMTgwLTg2MDgtNGQwMi05OGNjLWYyODMzZWQzZjg2OA==";

let cachedToken = null;
let tokenExpiresAt = 0;

function httpRequest(options, postData) {
  return new Promise((resolve, reject) => {
    const client = options.protocol === 'https:' ? https : http;
    const req = client.request(options, (res) => {
      let body = '';
      res.setEncoding('utf8');
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(body);
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve(parsed);
          } else {
            reject(new Error(`HTTP ${res.statusCode}: ${body}`));
          }
        } catch (e) {
          resolve(body);
        }
      });
    });

    req.on('error', reject);
    req.setTimeout(15000, () => {
      req.destroy();
      reject(new Error('Request timed out'));
    });

    if (postData) {
      req.write(postData);
    }
    req.end();
  });
}

async function getAccessToken() {
  const now = Date.now();
  if (cachedToken && tokenExpiresAt > now + 60000) {
    return cachedToken;
  }

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
      'Authorization': `Basic ${GIGACHAT_KEY}`,
      'Content-Length': Buffer.byteLength(postData),
    },
  };

  const data = await httpRequest(options, postData);
  if (data && data.access_token) {
    cachedToken = data.access_token;
    tokenExpiresAt = data.expires_at || (now + 1800000);
    return cachedToken;
  }
  throw new Error('Failed to obtain GigaChat token');
}

const SYSTEM_PROMPT = `
Ты — персональный онлайн-куратор сервиса курьерской доставки «Курьер PRO Еда».
Твоя цель — доброжелательно, уверенно и по-человечески помогать соискателям устроиться курьером.

СТРОЖАЙШИЕ ПРАВИЛА:
1. КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНО называть себя «GigaChat», «Сбер», «нейросеть», «AI», «бот» или «модель». Ты — живой человек, наставник и личный куратор соискателей!
   Если спрашивают «кто ты?», «ты кто?», «ты кто бро?», «ты робот?», «как тебя зовут?»:
   Отвечай спокойно и по-человечески:
   «Я твой личный куратор и наставник в сервисе доставки. Помогаю соискателям устроиться курьером: рассказываю про доход, график, документы и получение экипировки. Тебе подсказать по условиям или хочешь оформиться?»

2. НЕ ЗДОРОВАЙСЯ ПОВТОРНО:
   - Здороваться («Привет! 👋») можно ТОЛЬКО один раз в самом первом сообщении.
   - По ходу диалога КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНО здороваться снова («Привет», «Салют», «Здравствуйте») и заново представляться. Сразу отвечай на вопрос соискателя!

3. НЕ НАВЯЗЫВАЙ КНОПКУ РЕГИСТРАЦИИ НА ОБЫЧНЫЕ ВОПРОСЫ («НЕ ПУЛЯЙСЯ ССЫЛКАМИ»):
   - Если пользователь задаёт вопросы («кто ты бро?», «как дела?», «какие документы?», «со скольки лет?», «какой доход?», «есть ли штрафы?»):
     Просто дружелюбно, понятно и по существу ответь на вопрос! НЕ говори «нажимай кнопку прямо сейчас», не дави!

4. КОГДА КАНДИДАТ ГОТОВ ИЛИ ХОЧЕТ ОФОРМИТЬСЯ («хочу», «давай», «готов», «как начать», «куда нажать», «скинь анкету», «скинь ссылку», «зарегистрироваться», «как устроиться»):
   - НЕ задавай соискателю встречных допросов («расскажи о себе», «сколько тебе лет», «в каком ты городе», «с чего начнём»)!
   - Сразу чётко направь на кнопку под сообщением:
     «Отлично! Нажимай кнопку «Регистрация» прямо под этим сообщением и заполни официальную анкету партнёра — это займёт всего пару минут. Сразу после этого сможешь получить экипировку и выйти на первые заказы. Если возникнут вопросы на любом этапе — пиши сюда, я всегда на связи!»

5. БЕЗ СЛОВА «БЕСПЛАТНЫЙ» (СТРОГО):
   - НИКОГДА не пиши «бесплатный термокороб» или «без залога» (в Казахстане и некоторых регионах условия могут отличаться).
   - Всегда пиши: «получить термокороб и всё необходимое для работы в курьерском центре или ПВЗ».

6. СТРОГИЙ БРЕНДИНГ:
   - НИКОГДА не упоминай названия «Яндекс», «Яндекс Еда», «Яндекс Про», «Яндекс Доставка». Всегда используй: «наш сервис доставки», «официальная служба доставки», «партнёрская служба».

7. УСЛОВИЯ И ДОХОД:
   - Доход: Выплаты каждый день на карту любого банка. График полностью свободный (от 1-2 часов в день). Доход до 250 000 ₽ в месяц для автокурьеров по РФ.
   - Ошибки регистрации (не приходит СМС / сбой анкеты): отключить VPN, очистить кэш приложения.
   - Кнопка «Регистрация» находится прямо под сообщением. Не пиши URL-ссылок и заглушек в тексте.
`.trim();

function shouldShowActionCard(userQuestion, aiReply) {
  const q = (userQuestion || '').toLowerCase().trim();
  const a = (aiReply || '').toLowerCase().trim();

  // 1. Информационные вопросы и смолток — НИКОГДА не спамить кнопкой/ссылкой
  const nonActionPatterns = [
    /кто ты/i, /ты кто/i, /как звать/i, /как зовут/i, /как дела/i,
    /\bпривет\b/i, /\bсалют\b/i, /\bхай\b/i, /\bку\b/i, /\bспасибо\b/i,
    /\bпонял\b/i, /\bясно\b/i, /\bок\b/i, /\bхорошо\b/i, /рахмат/i,
    /документ/i, /паспорт/i, /возраст/i, /\bлет\b/i, /штраф/i, /налог/i,
    /робот/i
  ];
  if (nonActionPatterns.some(p => p.test(q))) {
    return false;
  }

  // 2. Прямое намерение регистрации или запрос ссылки
  const intentPatterns = [
    /хочу/i, /давай/i, /готов/i, /начать/i, /ссылк/i, /анкет/i,
    /куда нажать/i, /как устроиться/i, /оформить/i, /зарегистр/i,
    /ro‘yxat/i, /каттал/i, /тіркел/i,
  ];
  if (intentPatterns.some(p => p.test(q))) {
    return true;
  }

  // 3. Если ответ ассистента явно указывает нажать на кнопку регистрации
  if (a.includes('кнопк') && (a.includes('регистрац') || a.includes('анкет'))) {
    return true;
  }

  return false;
}

const server = http.createServer(async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  if (req.method === 'POST' && req.url === '/askCurator') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', async () => {
      try {
        const { question, history = [], lang = 'ru', country = 'ru' } = JSON.parse(body || '{}');
        if (!question) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'question is required' }));
          return;
        }

        console.log(`[Curator Gateway] Вопрос соискателя: "${question}" (история: ${history.length} сообщ.)`);

        const token = await getAccessToken();
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

        const chatRes = await httpRequest(chatOptions, payload);
        const choices = chatRes && chatRes.choices;
        if (choices && choices.length > 0 && choices[0].message) {
          const reply = choices[0].message.content.trim();
          const showCard = shouldShowActionCard(question, reply);
          console.log(`[Curator Gateway] Ответ GigaChat: "${reply}" [showCard: ${showCard}]`);
          res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
          res.end(JSON.stringify({
            success: true,
            text: reply,
            showActionCard: showCard,
            actionType: 'register',
          }));
          return;
        }

        throw new Error('Empty GigaChat response');
      } catch (err) {
        console.error('[Curator Gateway] Ошибка:', err.message);
        res.writeHead(500, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ error: err.message, fallback: true }));
      }
    });
    return;
  }

  res.writeHead(404);
  res.end();
});

server.listen(PORT, () => {
  console.log(`[Curator Gateway] Запущен на http://localhost:${PORT}/askCurator`);
});

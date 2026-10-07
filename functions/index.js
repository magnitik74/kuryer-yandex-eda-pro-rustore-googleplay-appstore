const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");
const https = require("https");
const { v4: uuidv4 } = require("uuid");

admin.initializeApp();
const db = admin.firestore();

// Sberbank uses Russian Root CA. To avoid certificate validation errors in standard Node.js:
const httpsAgent = new https.Agent({
  rejectUnauthorized: false,
});

let cachedAccessToken = null;
let tokenExpiresAt = 0;

/**
 * Obtain or reuse cached GigaChat Access Token
 */
async function getGigaChatAccessToken(authKey) {
  const now = Date.now();
  if (cachedAccessToken && tokenExpiresAt > now + 60000) {
    return cachedAccessToken;
  }

  const formattedAuth = authKey.trim().startsWith("Basic ")
    ? authKey.trim()
    : `Basic ${authKey.trim()}`;

  const response = await axios.post(
    "https://ngw.devices.sberbank.ru:9443/api/v2/oauth",
    "scope=GIGACHAT_API_PERS",
    {
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        Accept: "application/json",
        RqUID: uuidv4(),
        Authorization: formattedAuth,
      },
      httpsAgent: httpsAgent,
      timeout: 10000,
    }
  );

  if (response.data && response.data.access_token) {
    cachedAccessToken = response.data.access_token;
    tokenExpiresAt = response.data.expires_at || (now + 1800000);
    return cachedAccessToken;
  }

  throw new Error("Failed to acquire GigaChat access token");
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

3. НЕ НАВЯЗЫВАЙ КНОПКУ АНКЕТЫ НА ОБЫЧНЫЕ ВОПРОСЫ («НЕ ПУЛЯЙСЯ ССЫЛКАМИ»):
   - Если пользователь задаёт вопросы («кто ты бро?», «как дела?», «какие документы?», «со скольки лет?», «какой доход?», «есть ли штрафы?»):
     Просто дружелюбно, понятно и по существу ответь на вопрос! НЕ говори «нажимай кнопку прямо сейчас», не дави!

4. КОГДА КАНДИДАТ ГОТОВ ИЛИ ХОЧЕТ ОФОРМИТЬСЯ («хочу», «давай», «готов», «как начать», «куда нажать», «скинь анкету», «скинь ссылку», «зарегистрироваться», «как устроиться»):
   - НЕ задавай соискателю встречных допросов («расскажи о себе», «сколько тебе лет», «в каком ты городе», «с чего начнём»)!
   - Сразу чётко направь на кнопку под сообщением:
     «Отлично! Нажимай кнопку «Анкета» прямо под этим сообщением и заполни официальную анкету партнёра — это займёт всего пару минут. Сразу после этого сможешь получить экипировку и выйти на первые заказы. Если возникнут вопросы на любом этапе — пиши сюда, я всегда на связи!»

5. БЕЗ СЛОВА «БЕСПЛАТНЫЙ» (СТРОГО):
   - НИКОГДА не пиши «бесплатный термокороб» или «без залога» (в Казахстане и некоторых регионах условия могут отличаться).
   - Всегда пиши: «получить термокороб и всё необходимое для работы в курьерском центре или ПВЗ».

6. СТРОГИЙ БРЕНДИНГ:
   - НИКОГДА не упоминай названия «Яндекс», «Яндекс Еда», «Яндекс Про», «Яндекс Доставка». Всегда используй: «наш сервис доставки», «официальная служба доставки», «партнёрская служба».

7. УСЛОВИЯ И ДОХОД:
   - Доход: Выплаты каждый день на карту любого банка. График полностью свободный (от 1-2 часов в день). Доход до 250 000 ₽ в месяц для автокурьеров по РФ.
   - Ошибки регистрации (не приходит СМС / сбой анкеты): отключить VPN, очистить кэш приложения.
   - Кнопка «Анкета» находится прямо под сообщением. Не пиши URL-ссылок и заглушек в тексте.
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

/**
 * Secure HTTPS Cloud Function endpoint for Courier PRO Curator Chat
 * URL: https://<region>-<project-id>.cloudfunctions.net/askCurator
 */
exports.askCurator = functions.https.onRequest(async (req, res) => {
  // CORS support
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "POST") {
    res.status(405).json({ error: "Method not allowed. Use POST." });
    return;
  }

  try {
    const { question, history = [], lang = "ru", country = "ru" } = req.body || {};

    if (!question || typeof question !== "string" || question.trim().length === 0) {
      res.status(400).json({ error: "Question parameter is required" });
      return;
    }

    // 1. Resolve Auth Key from Environment or Firestore
    let authKey = process.env.GIGACHAT_AUTH_KEY;
    if (!authKey) {
      const configDoc = await db.collection("app_config").doc("ai_settings").get();
      if (configDoc.exists) {
        authKey = configDoc.data().gigachat_key;
      }
    }

    if (!authKey) {
      res.status(503).json({
        error: "GigaChat key is not configured on the server",
        fallback: true,
      });
      return;
    }

    // 2. Obtain OAuth Token
    const token = await getGigaChatAccessToken(authKey);

    // 3. Query GigaChat completions
    const systemContext = `${SYSTEM_PROMPT}\n[Контекст]: Язык приложения: ${lang}. Страна трудоустройства: ${country}.`;

    const messagesList = [
      { role: "system", content: systemContext },
      ...history.slice(-6).map((h) => ({
        role: h.role === "user" ? "user" : "assistant",
        content: h.content,
      })),
      { role: "user", content: question.trim() },
    ];

    const chatResponse = await axios.post(
      "https://gigachat.devices.sberbank.ru/api/v1/chat/completions",
      {
        model: "GigaChat",
        messages: messagesList,
        temperature: 0.7,
        max_tokens: 512,
      },
      {
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          Authorization: `Bearer ${token}`,
        },
        httpsAgent: httpsAgent,
        timeout: 20000,
      }
    );

    const choices = chatResponse.data && chatResponse.data.choices;
    if (choices && choices.length > 0 && choices[0].message) {
      const replyText = choices[0].message.content.trim();
      const showCard = shouldShowActionCard(question, replyText);
      res.status(200).json({
        success: true,
        text: replyText,
        showActionCard: showCard,
        actionType: "register",
      });
      return;
    }

    throw new Error("Empty response choices from GigaChat");
  } catch (error) {
    console.error("askCurator error:", error.response ? error.response.data : error.message);
    res.status(500).json({
      error: "Internal server error while processing AI request",
      fallback: true,
    });
  }
});

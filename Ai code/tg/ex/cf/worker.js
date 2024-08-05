// 使用可选链操作符来安全地访问 SUBSCRIBERS_KV
const SUBSCRIBERS = globalThis.SUBSCRIBERS_KV;

// 替换为您的 Telegram Bot Token
const TELEGRAM_BOT_TOKEN = 'YOUR_TELEGRAM_BOT_TOKEN';

// 用于在没有 KV 存储时在内存中临时存储订阅者
let inMemorySubscribers = [];

async function handleRequest(request) {
  const url = new URL(request.url);
  const path = url.pathname;

  if (path === '/webhook') {
    return handleWebhook(request);
  } else if (path === '/cron') {
    return handleCron();
  } else {
    return new Response('Not Found', { status: 404 });
  }
}

async function handleWebhook(request) {
  try {
    const update = await request.json();
    if (update.message && update.message.text) {
      const chatId = update.message.chat.id;
      const text = update.message.text;

      if (text === '/start' || text === '/help') {
        await sendTelegramMessage(chatId, getHelpMessage());
      } else if (text === '/subscribe') {
        await subscribe(chatId);
      } else if (text === '/unsubscribe') {
        await unsubscribe(chatId);
      } else if (['/usd', '/hkd', '/gbp', '/eur', '/all'].includes(text)) {
        await handleCurrencyQuery(chatId, text.slice(1));
      }
    }
    return new Response('OK');
  } catch (error) {
    console.error('Error in handleWebhook:', error);
    return new Response('Error', { status: 500 });
  }
}

async function handleCron() {
  try {
    const rates = await getRates();
    const subscribers = await getSubscribers();
    
    for (const chatId of subscribers) {
      await sendUpdateMessage(chatId, rates);
    }
    return new Response('Cron job completed');
  } catch (error) {
    console.error('Error in handleCron:', error);
    return new Response('Error', { status: 500 });
  }
}

async function getRates() {
  const url = 'https://www.boc.cn/sourcedb/whpj/';
  const response = await fetch(url);
  const html = await response.text();
  
  const result = {};
  const currencies = ['美元', '港币', '英镑', '欧元'];
  
  const regex = /<td>(.*?)<\/td>/g;
  let match;
  let currentCurrency = null;
  let count = 0;

  while ((match = regex.exec(html)) !== null) {
    const value = match[1].trim();
    if (currencies.includes(value)) {
      currentCurrency = value;
      count = 0;
      result[currentCurrency] = {};
    } else if (currentCurrency) {
      count++;
      if (count === 1) result[currentCurrency].buyRate = value;
      if (count === 3) result[currentCurrency].sellRate = value;
    }
  }
  
  return result;
}

function getHongKongTime() {
  return new Date().toLocaleString('zh-HK', {
    timeZone: 'Asia/Hong_Kong',
    hour12: false,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  });
}

function formatRateMessage(currency, rate) {
  const timeStr = getHongKongTime();
  return `${currency}汇率 (每100${currency}):\n买入价: ${rate.buyRate || '无数据'} 人民币\n卖出价: ${rate.sellRate || '无数据'} 人民币\n更新时间: ${timeStr} (香港时间)`;
}

async function sendTelegramMessage(chatId, text) {
  const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`;
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      chat_id: chatId,
      text: text,
    }),
  });
  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`);
  }
}

async function getSubscribers() {
  if (SUBSCRIBERS) {
    return await SUBSCRIBERS.get('list', 'json') || [];
  } else {
    return inMemorySubscribers;
  }
}

async function setSubscribers(subscribers) {
  if (SUBSCRIBERS) {
    await SUBSCRIBERS.put('list', JSON.stringify(subscribers));
  } else {
    inMemorySubscribers = subscribers;
  }
}

async function subscribe(chatId) {
  let subscribers = await getSubscribers();
  if (!subscribers.includes(chatId)) {
    subscribers.push(chatId);
    await setSubscribers(subscribers);
    await sendTelegramMessage(chatId, '您已成功订阅每5小时汇率更新。');
  } else {
    await sendTelegramMessage(chatId, '您已经订阅了汇率更新。');
  }
}

async function unsubscribe(chatId) {
  let subscribers = await getSubscribers();
  const index = subscribers.indexOf(chatId);
  if (index > -1) {
    subscribers.splice(index, 1);
    await setSubscribers(subscribers);
    await sendTelegramMessage(chatId, '您已成功取消订阅汇率更新。');
  } else {
    await sendTelegramMessage(chatId, '您当前没有订阅汇率更新。');
  }
}

async function handleCurrencyQuery(chatId, currency) {
  const rates = await getRates();
  if (currency === 'all') {
    let message = '所有汇率信息:\n\n';
    ['美元', '港币', '英镑', '欧元'].forEach(curr => {
      if (rates[curr]) {
        message += formatRateMessage(curr, rates[curr]) + '\n\n';
      } else {
        message += `${curr}: 无法获取汇率信息\n\n`;
      }
    });
    message += '注意: 所有汇率均以100单位外币兑换人民币显示。';
    await sendTelegramMessage(chatId, message);
  } else {
    const currencyMap = { usd: '美元', hkd: '港币', gbp: '英镑', eur: '欧元' };
    const mappedCurrency = currencyMap[currency];
    if (rates[mappedCurrency]) {
      const message = formatRateMessage(mappedCurrency, rates[mappedCurrency]);
      await sendTelegramMessage(chatId, message);
    } else {
      await sendTelegramMessage(chatId, `抱歉,未能获取${mappedCurrency}的汇率信息。`);
    }
  }
}

async function sendUpdateMessage(chatId, rates) {
  const currentTime = new Date();
  const nextUpdateTime = new Date(currentTime.getTime() + 5 * 60 * 60 * 1000); // 添加5小时
  
  let message = '每5小时汇率更新:\n\n';
  ['美元', '港币', '英镑', '欧元'].forEach(currency => {
    if (rates[currency]) {
      message += formatRateMessage(currency, rates[currency]) + '\n\n';
    } else {
      message += `${currency}: 无法获取汇率信息\n\n`;
    }
  });
  message += '注意: 所有汇率均以100单位外币兑换人民币显示。\n';
  message += `下次更新预计时间: ${nextUpdateTime.toLocaleString('zh-HK', { timeZone: 'Asia/Hong_Kong' })} (香港时间)`;
  
  await sendTelegramMessage(chatId, message);
}

function getHelpMessage() {
  return `
欢迎使用汇率查询机器人!
以下是可用的命令:

/usd - 查询美元汇率
/hkd - 查询港币汇率
/gbp - 查询英镑汇率
/eur - 查询欧元汇率
/all - 查询所有汇率
/subscribe - 订阅每5小时更新
/unsubscribe - 取消订阅
/help - 显示此帮助信息

注意: 所有汇率均以100单位外币兑换人民币显示。
订阅后，您将每5小时收到一次汇率更新。
  `;
}

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request));
});

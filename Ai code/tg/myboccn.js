// exchange_rate_bot.js
const TelegramBot = require('node-telegram-bot-api');
const https = require('https');
const cron = require('node-cron');
const fs = require('fs');

// 替换为您的Telegram Bot Token
const token = 'YOUR_TELEGRAM_BOT_TOKEN';

const bot = new TelegramBot(token, {polling: true});

// 存储订阅者的文件
const SUBSCRIBERS_FILE = 'subscribers.json';

// 读取订阅者列表
let subscribers = [];
try {
  const data = fs.readFileSync(SUBSCRIBERS_FILE, 'utf8');
  subscribers = JSON.parse(data);
} catch (err) {
  console.log('No existing subscribers file, starting with empty list');
}

// 保存订阅者列表到文件
function saveSubscribers() {
  fs.writeFileSync(SUBSCRIBERS_FILE, JSON.stringify(subscribers));
}

function httpsGet(url) {
  return new Promise((resolve, reject) => {
    https.get(url, {
      headers: {
        'Accept-Charset': 'UTF-8'
      }
    }, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        resolve(data);
      });
    }).on('error', (err) => {
      reject(err);
    });
  });
}

async function getRates() {
  const url = 'https://www.boc.cn/sourcedb/whpj/';
  const currencies = ['美元', '港币', '英镑', '欧元'];
  
  const html = await httpsGet(url);
  
  const result = {};
  
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

// 帮助信息
const helpMessage = `
欢迎使用汇率查询机器人!
以下是可用的命令:

/usd - 查询美元汇率
/hkd - 查询港币汇率
/gbp - 查询英镑汇率
/eur - 查询欧元汇率
/all - 查询所有汇率
/subscribe - 订阅每小时更新
/unsubscribe - 取消订阅
/help - 显示此帮助信息

注意: 所有汇率均以100单位外币兑换人民币显示。
订阅后，您将每小时收到一次汇率更新。

如需任何帮助，请随时使用 /help 命令。
`;

// 处理 /start 命令和新用户
bot.onText(/\/start/, (msg) => {
  const chatId = msg.chat.id;
  bot.sendMessage(chatId, helpMessage);
});

// 处理 /help 命令
bot.onText(/\/help/, (msg) => {
  const chatId = msg.chat.id;
  bot.sendMessage(chatId, helpMessage);
});

// 处理各种货币查询命令
async function handleCurrencyQuery(msg, currency) {
  const chatId = msg.chat.id;
  try {
    const rates = await getRates();
    if (rates[currency]) {
      const message = formatRateMessage(currency, rates[currency]);
      bot.sendMessage(chatId, message);
    } else {
      bot.sendMessage(chatId, `抱歉,未能获取${currency}的汇率信息。`);
    }
  } catch (error) {
    console.error('获取汇率信息时出错:', error);
    bot.sendMessage(chatId, '抱歉,获取汇率信息时出错。请稍后再试。');
  }
}

bot.onText(/\/usd/, (msg) => handleCurrencyQuery(msg, '美元'));
bot.onText(/\/hkd/, (msg) => handleCurrencyQuery(msg, '港币'));
bot.onText(/\/gbp/, (msg) => handleCurrencyQuery(msg, '英镑'));
bot.onText(/\/eur/, (msg) => handleCurrencyQuery(msg, '欧元'));

// 查询所有汇率
bot.onText(/\/all/, async (msg) => {
  const chatId = msg.chat.id;
  try {
    const rates = await getRates();
    let message = '所有汇率信息:\n\n';
    ['美元', '港币', '英镑', '欧元'].forEach(currency => {
      if (rates[currency]) {
        message += formatRateMessage(currency, rates[currency]) + '\n\n';
      } else {
        message += `${currency}: 无法获取汇率信息\n\n`;
      }
    });
    message += '注意: 所有汇率均以100单位外币兑换人民币显示。';
    bot.sendMessage(chatId, message);
  } catch (error) {
    console.error('获取汇率信息时出错:', error);
    bot.sendMessage(chatId, '抱歉,获取汇率信息时出错。请稍后再试。');
  }
});

// 订阅功能
bot.onText(/\/subscribe/, (msg) => {
  const chatId = msg.chat.id;
  if (!subscribers.includes(chatId)) {
    subscribers.push(chatId);
    saveSubscribers();
    bot.sendMessage(chatId, '您已成功订阅每小时汇率更新。您将在每小时整点收到最新的汇率信息。');
  } else {
    bot.sendMessage(chatId, '您已经订阅了汇率更新。如需取消订阅，请使用 /unsubscribe 命令。');
  }
});

// 取消订阅功能
bot.onText(/\/unsubscribe/, (msg) => {
  const chatId = msg.chat.id;
  const index = subscribers.indexOf(chatId);
  if (index > -1) {
    subscribers.splice(index, 1);
    saveSubscribers();
    bot.sendMessage(chatId, '您已成功取消订阅汇率更新。如需重新订阅，请使用 /subscribe 命令。');
  } else {
    bot.sendMessage(chatId, '您当前没有订阅汇率更新。如需订阅，请使用 /subscribe 命令。');
  }
});

// 向所有订阅者发送更新
async function sendUpdateToSubscribers() {
  try {
    const rates = await getRates();
    let message = '每小时汇率更新:\n\n';
    ['美元', '港币', '英镑', '欧元'].forEach(currency => {
      if (rates[currency]) {
        message += formatRateMessage(currency, rates[currency]) + '\n\n';
      } else {
        message += `${currency}: 无法获取汇率信息\n\n`;
      }
    });
    message += '注意: 所有汇率均以100单位外币兑换人民币显示。';

    subscribers.forEach(chatId => {
      bot.sendMessage(chatId, message).catch(error => {
        console.error(`Error sending message to ${chatId}:`, error);
      });
    });
  } catch (error) {
    console.error('发送更新时出错:', error);
  }
}

// 设置定时任务，每小时执行一次
cron.schedule('0 * * * *', () => {
  console.log('Sending hourly update');
  sendUpdateToSubscribers();
});

// 添加错误处理
bot.on('polling_error', (error) => {
  console.error('Bot polling error:', error);
});

// 处理新成员加入
bot.on('new_chat_members', (msg) => {
  const chatId = msg.chat.id;
  bot.sendMessage(chatId, helpMessage);
});

console.log('汇率查询机器人已启动');

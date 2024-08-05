#!/bin/bash

# 确保我们在正确的目录
cd "$(dirname "$0")"

# 安装所需的 npm 包
npm install node-telegram-bot-api node-cron

# 全局安装 pm2
npm install -g pm2

# 使用完整路径启动 pm2
npx pm2 start myboccn.js --name "myboccn"

# 保存 pm2 进程列表，以便在服务器重启时自动恢复
npx pm2 save

# 设置 pm2 开机自启
npx pm2 startup

echo "Bot has been started. You can check its status using 'npx pm2 status'"

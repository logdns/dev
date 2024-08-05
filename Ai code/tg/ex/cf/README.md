# 使用说明

## 步骤 1：创建 Worker

在 Cloudflare Workers 中创建一个新的 Worker。

## 步骤 2：粘贴代码

将你准备的代码复制粘贴到 Worker 编辑器中。

## 步骤 3：替换 Telegram Bot Token 

找到代码中的 `YOUR_TELEGRAM_BOT_TOKEN` 并替换为你的实际 Telegram Bot Token。

## 步骤 4：KV 命名空间配置

### 如果你有 KV 命名空间：

- 在 Cloudflare Workers 的设置中，创建一个名为 `SUBSCRIBERS_KV` 的 KV 命名空间。
- 将这个 KV 命名空间绑定到你的 Worker。

## 步骤 5：部署 Worker

将 Worker 部署到 Cloudflare。

## 步骤 6：设置 Telegram Webhook

在浏览器中打开以下 URL，确保替换 `YOUR_BOT_TOKEN` 和 `YOUR_WORKER_URL`：
```
https://api.telegram.org/botYOUR_BOT_TOKEN/setWebhook?url=YOUR_WORKER_URL/webhook
```

## 步骤 7：设置 Cron 触发器

### 添加 Cron 触发器：

- 在 Worker 的 "Triggers" 标签中添加一个新的 Cron 触发器。
- 使用 Cron 表达式 `0 */5 * * *`（每5小时运行一次）。
- 设置 Path 为 `/cron`。

---

这个代码包含了，包括每5小时更新一次，显示下次更新时间，以及在没有 KV 存储时使用内存存储的备选方案。(为什么是5个小时,因为CF免费版本一天只能5次,超过需要付费计划)

如果你在设置或使用过程中遇到任何问题，或者需要进一步的修改，请随时告诉我！

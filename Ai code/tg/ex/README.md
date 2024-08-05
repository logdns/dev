# 使用说明

## 安装 Node.js 和 npm

确保您已经安装了所需的 npm，使用以下命令下载并运行 NodeSource 的安装脚本（举例安装 Node.js 16.x 版本）:

```sh
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt install -y nodejs
```

## 验证安装

安装完成后，你可以用以下命令来检查 Node.js 和 npm 是否成功安装，及其版本信息:

```sh
node -v
npm -v
```

## 配置机器人代码

将 `myboccn.js` 代码中的 `YOUR_TELEGRAM_BOT_TOKEN` 替换为您的实际 Telegram 机器人 token。

## 设置脚本权限

```sh
chmod +x myboccn.sh
```

## 运行和管理机器人

运行后，您的机器人将在后台持续运行。您可以使用以下命令来管理它：

- 查看运行状态：

  ```sh
  pm2 status
  ```

- 查看日志：

  ```sh
  pm2 logs myboccn
  ```

- 重启机器人：

  ```sh
  pm2 restart myboccn
  ```

- 停止机器人：

  ```sh
  pm2 stop myboccn
  ```

- 启动机器人：

  ```sh
  pm2 start myboccn
  ```

## 机器人的功能

这个机器人现在具有以下功能：

- 查询单个货币汇率（美元、港币、英镑、欧元）
- 查询所有支持的货币汇率
- 订阅和取消订阅每小时更新
- 每小时自动向订阅者发送汇率更新
- 显示帮助信息
- 新用户加入时自动发送欢迎消息和使用说明

如果您需要进一步的修改或有任何其他需求，请随时告诉我。

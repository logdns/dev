#!/bin/bash

# 哪吒面板完全卸载脚本
# 适用于Ubuntu和Debian系统

# 检查是否以root权限运行
if [ "$(id -u)" != "0" ]; then
   echo "此脚本需要root权限执行"
   echo "请使用 sudo bash $0 运行"
   exit 1
fi

echo "开始卸载哪吒面板..."

# 停止哪吒服务（如果存在）
echo "停止哪吒服务..."
systemctl stop nezha-agent 2>/dev/null || true
systemctl stop nezha-dashboard 2>/dev/null || true

# 禁用服务
echo "禁用哪吒服务..."
systemctl disable nezha-agent 2>/dev/null || true
systemctl disable nezha-dashboard 2>/dev/null || true

# 删除服务文件
echo "删除服务文件..."
rm -f /etc/systemd/system/nezha-agent.service
rm -f /etc/systemd/system/nezha-dashboard.service
rm -f /lib/systemd/system/nezha-agent.service
rm -f /lib/systemd/system/nezha-dashboard.service

# 删除程序文件
echo "删除程序文件..."
rm -rf /opt/nezha
rm -rf /etc/nezha
rm -rf /usr/local/nezha

# 删除日志文件
echo "删除日志文件..."
rm -rf /var/log/nezha

# 重新加载 systemd
echo "重新加载systemd..."
systemctl daemon-reload

# 清除可能存在的apt包（如果有的话）
if command -v apt >/dev/null 2>&1; then
  echo "检查并清除apt包..."
  apt purge nezha-* -y 2>/dev/null || true
fi

echo "哪吒面板已完全移除"
echo "如果有其他手动安装的文件，可能需要手动删除"

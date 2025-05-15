#!/bin/bash

# 哪吒面板完全卸载脚本
# 该脚本将停止并移除哪吒面板的所有组件和相关文件

echo "开始卸载哪吒面板..."

# 停止哪吒服務
echo "停止哪吒服务..."
systemctl stop nezha-agent
systemctl stop nezha-dashboard

# 禁用服務
echo "禁用哪吒服务..."
systemctl disable nezha-agent
systemctl disable nezha-dashboard

# 刪除服務檔案
echo "删除服务文件..."
rm -f /etc/systemd/system/nezha-agent.service
rm -f /etc/systemd/system/nezha-dashboard.service

# 刪除程式文件
echo "删除程序文件..."
rm -rf /opt/nezha
rm -rf /etc/nezha

# 刪除日誌文件
echo "删除日志文件..."
rm -rf /var/log/nezha

# 重新載入 systemd
echo "重新加载systemd..."
systemctl daemon-reload

echo "哪吒面板已完全移除"

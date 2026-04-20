#!/bin/bash

# --- 配置区 ---
SAVE_DIR="/www/wwwroot/data/ips"
SAVE_FILE="${SAVE_DIR}/cdn_ips_combined.txt"
TEMP_FILE="/tmp/cdn_ips_raw.tmp"
SCRIPT_PATH=$(readlink -f "$0")

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- 1. 环境初始化设置 ---
setup_env() {
    echo -e "${BLUE}[设置]${NC} 正在检查并安装必要组件 (curl, grep, sed, cron)..."
    apt update -qq && apt install -y curl grep sed cron > /dev/null 2>&1
    mkdir -p "$SAVE_DIR"
    echo -e "${GREEN}环境配置完成！${NC} 目录 $SAVE_DIR 已就绪。"
}

# --- 2. 更新 IP 列表 (彻底修复行粘连错误) ---
update_ips() {
    echo -e "${BLUE}[更新]${NC} 开始获取 CDN IP 列表..."
    
    # 清空临时文件
    : > "$TEMP_FILE"

    # 获取 Cloudflare
    echo -n " -> 获取 Cloudflare..."
    curl -s "https://www.cloudflare.com/ips-v4/" >> "$TEMP_FILE"
    echo "" >> "$TEMP_FILE" # 强制换行

    # 获取 Fastly
    echo -n " -> 获取 Fastly..."
    curl -s "https://api.fastly.com/public-ip-list" >> "$TEMP_FILE"
    echo "" >> "$TEMP_FILE" # 强制换行

    # 获取 Akamai
    echo -n " -> 获取 Akamai..."
    curl -s "https://raw.githubusercontent.com/platformbuilds/Akamai-ASN-and-IPs-List/refs/heads/master/akamai_ip_list.lst" >> "$TEMP_FILE"
    echo "" >> "$TEMP_FILE" # 强制换行

    # 最终处理：
    # 1. 使用 grep -oE 提取所有符合 IP 或 CIDR 格式的内容（这会自动将粘连在同一行的 IP 拆分成多行）
    # 2. 排序并去重
    if [ -f "$TEMP_FILE" ]; then
        grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?\b" "$TEMP_FILE" | sort -u > "$SAVE_FILE"
        echo -e "${GREEN} OK${NC}"
        echo -e "${BLUE}[结果]${NC} 合并完成。总计: ${YELLOW}$(wc -l < "$SAVE_FILE")${NC} 条唯一记录。"
        rm -f "$TEMP_FILE"
    fi
}

# --- 3. 查看状态 ---
show_status() {
    echo -e "\n${BLUE}=== 系统状态查看 ===${NC}"
    if [ -f "$SAVE_FILE" ]; then
        echo -e "数据文件: ${GREEN}存在${NC}"
        echo -e "数据行数: ${YELLOW}$(wc -l < "$SAVE_FILE")${NC}"
        echo -e "最后更新: $(date -r "$SAVE_FILE" '+%Y-%m-%d %H:%M:%S')"
        echo -e "文件预览 (前3行):"
        head -n 3 "$SAVE_FILE" | sed 's/^/  /'
    else
        echo -e "数据文件: ${RED}未生成${NC}"
    fi

    CRON_CHECK=$(crontab -l 2>/dev/null | grep "$SCRIPT_PATH")
    if [ -n "$CRON_CHECK" ]; then
        echo -e "定时任务: ${GREEN}已启用${NC}"
    else
        echo -e "定时任务: ${RED}未设置${NC}"
    fi
}

# --- 4. 设置定时任务 ---
set_cron() {
    (crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH"; echo "0 3 * * 1 /bin/bash $SCRIPT_PATH --auto") | crontab -
    echo -e "${GREEN}定时任务已设置成功！${NC} (每周一凌晨 3:00 更新)"
}

# --- 5. 清除所有设置 ---
clear_all() {
    read -p "确定要删除所有数据和定时任务吗？(y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH" | crontab -
        rm -rf "$SAVE_DIR"
        echo -e "${YELLOW}所有设置与数据已清理。${NC}"
    else
        echo "操作取消。"
    fi
}

# --- 自动运行模式 (用于 Cron) ---
if [ "$1" == "--auto" ]; then
    update_ips
    exit 0
fi

# --- 交互主菜单 ---
while true; do
    echo -e "\n${YELLOW}CDN IP 集合管理工具${NC}"
    echo -e "---------------------------"
    echo "1. 初始化设置 (安装依赖)"
    echo -e "2. ${GREEN}立即更新 (修复粘连)${NC}"
    echo "3. 查看状态"
    echo "4. 开启自动更新任务"
    echo -e "5. ${RED}清除所有设置${NC}"
    echo "6. 退出"
    echo -e "---------------------------"
    read -p "请输入选项 [1-6]: " choice

    case $choice in
        1) setup_env ;;
        2) update_ips ;;
        3) show_status ;;
        4) set_cron ;;
        5) clear_all ;;
        6) exit 0 ;;
        *) echo -e "${RED}无效输入${NC}" ;;
    esac
done

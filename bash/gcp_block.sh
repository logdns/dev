
#!/bin/bash



# ====================================================

# 脚本名称: gcp_block.sh

# 功能: 谷歌云 CDN 拦截脚本 (支持自动纠错与定时更新)

# ====================================================



IPSET_NAME="gcp_block_cdn"

IP_URL="https://soft.xinai.de/public/ips/cdn_ips_combined.txt"

IP_FILE="/tmp/cdn_ips_combined.txt"

SCRIPT_PATH=$(readlink -f "$0")



# --- 环境检测 ---

check_env() {

    echo "🔍 正在检查运行环境..."

    local pkgs=(curl jq iptables ipset)

    local missing=()

    for pkg in "${pkgs[@]}"; do

        if ! command -v "$pkg" &> /dev/null; then

            missing+=("$pkg")

        fi

    done

    if [ ${#missing[@]} -ne 0 ]; then

        echo "❌ 缺少必要组件: ${missing[*]}"

        exit 1

    fi

    echo "✅ 环境检查通过。"

}



# --- 设置拦截 (核心功能) ---

setup_block() {

    check_env

    echo "📥 正在下载并过滤 IP 列表..."

    

    if ! curl -fsSL "$IP_URL" | tr -d '\r' | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?' > "$IP_FILE"; then

        echo "❌ 下载失败，请检查网络。"

        return 1

    fi



    clear_rules &> /dev/null



    echo "📦 创建 ipset 集合: $IPSET_NAME"

    ipset create "$IPSET_NAME" hash:net



    echo "⚡ 正在校验并批量导入数据 (Restore 模式)..."

    {

        echo "create $IPSET_NAME hash:net -exist"

        while read -r ip; do

            first_byte=$(echo "$ip" | cut -d. -f1)

            if [[ "$first_byte" -le 255 ]]; then

                echo "add $IPSET_NAME $ip"

            fi

        done < "$IP_FILE"

    } | ipset restore



    echo "🚧 注入 iptables 拦截规则..."

    iptables -I INPUT  -m set --match-set "$IPSET_NAME" src -j DROP

    iptables -I OUTPUT -m set --match-set "$IPSET_NAME" dst -j DROP

    

    rm -f "$IP_FILE"

    local final_count=$(ipset list "$IPSET_NAME" | grep "Number of entries" | awk '{print $4}')

    echo "✅ 拦截已生效。当前条目: $final_count"

    setup_cron

}



# --- 清除规则 ---

clear_rules() {

    echo "🧹 正在清理相关规则..."

    while iptables -D INPUT  -m set --match-set "$IPSET_NAME" src -j DROP 2>/dev/null; do :; done

    while iptables -D OUTPUT -m set --match-set "$IPSET_NAME" dst -j DROP 2>/dev/null; do :; done

    if ipset list -n | grep -qw "$IPSET_NAME"; then

        ipset flush "$IPSET_NAME"

        ipset destroy "$IPSET_NAME"

    fi

    echo "✅ 清理完成。"

}



# --- 查询验证 ---

verify_status() {

    echo "📊 --- 当前拦截状态 ---"

    if ipset list -n | grep -qw "$IPSET_NAME"; then

        local count=$(ipset list "$IPSET_NAME" | grep "Number of entries" | awk '{print $4}')

        echo "🔹 状态: 运行中 | 条目: $count"

    else

        echo "🔸 状态: 未运行"

    fi

}



# --- 定时任务 ---

setup_cron() {

    local cron_job="0 3 * * * $SCRIPT_PATH update > /dev/null 2>&1"

    if ! crontab -l 2>/dev/null | grep -q "$SCRIPT_PATH"; then

        (crontab -l 2>/dev/null; echo "$cron_job") | crontab -

        echo "⏰ 已设置每日凌晨 3:00 自动更新。"

    fi

}



# --- 交互菜单 ---

menu() {

    echo -e "\n1. 立即设置/更新拦截\n2. 清除所有拦截规则\n3. 查询当前拦截状态\n4. 退出"

    read -p "请选择操作 [1-4]: " choice

    case $choice in

        1) setup_block ;;

        2) clear_rules; crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH" | crontab -; echo "⏰ 定时任务已移除。" ;;

        3) verify_status ;;

        4) exit 0 ;;

        *) menu ;;

    esac

}



# --- 入口控制 ---

if [ "${1:-}" == "update" ]; then

    setup_block

else

    if [ "$EUID" -ne 0 ]; then

        echo "❌ 请以 root 身份运行。"

        exit 1

    fi

    sed -i 's/\r$//' "$SCRIPT_PATH" 2>/dev/null

    menu

fi


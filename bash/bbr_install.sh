#!/bin/bash

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
PLAIN='\033[0m'

# 显示横幅
show_banner() {
    clear
    echo -e "${BLUE}=====================================${PLAIN}"
    echo -e "${BLUE}       BBR 管理脚本 v1.2           ${PLAIN}"
    echo -e "${BLUE}=====================================${PLAIN}"
    echo ""
}

# 检查是否以root权限运行
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}错误：请使用root权限运行此脚本${PLAIN}"
        exit 1
    fi
}

# 检查系统版本
check_system() {
    if [[ -f /etc/debian_version ]]; then
        OS="debian"
    elif [[ -f /etc/lsb-release ]]; then
        OS="ubuntu"
    else
        echo -e "${RED}错误：此脚本仅支持Debian和Ubuntu系统${PLAIN}"
        exit 1
    fi
}

# 检查内核版本
check_kernel() {
    kernel_version=$(uname -r | cut -d- -f1)
    if [[ $(echo $kernel_version | awk -F. '{print $1}') -lt 5 ]]; then
        echo -e "${YELLOW}警告：建议使用5.x或更高版本的内核以获得更好的性能${PLAIN}"
        read -p "是否继续？[y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# 显示当前BBR状态
show_status() {
    echo -e "${BLUE}系统信息：${PLAIN}"
    echo -e "操作系统：$(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo -e "内核版本：$(uname -r)"
    echo -e "\n${BLUE}BBR状态：${PLAIN}"
    
    if lsmod | grep -q "tcp_bbr"; then
        echo -e "BBR模块：${GREEN}已加载${PLAIN}"
    else
        echo -e "BBR模块：${RED}未加载${PLAIN}"
    fi
    
    current_cc=$(sysctl -n net.ipv4.tcp_congestion_control)
    echo -e "当前拥塞控制算法：${GREEN}${current_cc}${PLAIN}"
    echo -e "当前队列调度算法：${GREEN}$(sysctl -n net.core.default_qdisc)${PLAIN}"
    
    # 显示可用的拥塞控制算法
    available_cc=$(cat /proc/sys/net/ipv4/tcp_available_congestion_control)
    echo -e "可用的拥塞控制算法：${GREEN}${available_cc}${PLAIN}"
    echo
}

# 启用BBR
enable_bbr() {
    echo -e "${BLUE}正在启用BBR...${PLAIN}"
    
    # 首先删除可能存在的冲突配置
    rm -f /etc/sysctl.d/99-network-default.conf
    
    # 加载BBR模块
    modprobe tcp_bbr
    
    # 确保模块加载
    if ! lsmod | grep -q "tcp_bbr"; then
        echo -e "${RED}BBR模块加载失败${PLAIN}"
        return 1
    fi
    
    # 添加到永久模块列表（如果不存在）
    if ! grep -q "tcp_bbr" /etc/modules-load.d/modules.conf 2>/dev/null; then
        echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
    fi
    
    # 使用更高的优先级数字确保最后加载
    cat > /etc/sysctl.d/99-zzz-bbr-custom.conf << EOF
# BBR配置
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

# 网络性能优化
net.core.rmem_max=26214400
net.core.wmem_max=26214400
net.core.rmem_default=1048576
net.core.wmem_default=1048576
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_slow_start_after_idle=0

# 其他网络优化
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=30
net.ipv4.tcp_keepalive_time=1200
net.ipv4.ip_local_port_range=10000 65000
net.ipv4.tcp_max_syn_backlog=8192
net.ipv4.tcp_max_tw_buckets=5000
net.ipv4.tcp_mtu_probing=1
net.ipv4.tcp_timestamps=1
net.ipv4.tcp_sack=1
EOF
    
    # 直接设置当前运行的参数
    sysctl -w net.core.default_qdisc=fq >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    
    # 应用所有 sysctl 设置
    sysctl --system >/dev/null 2>&1
    
    # 再次验证设置是否生效
    sleep 1
    current_cc=$(sysctl -n net.ipv4.tcp_congestion_control)
    current_qdisc=$(sysctl -n net.core.default_qdisc)
    
    if [[ "$current_cc" == "bbr" && "$current_qdisc" == "fq" ]]; then
        echo -e "${GREEN}BBR已成功启用${PLAIN}"
        echo -e "当前配置："
        echo -e "拥塞控制算法: ${GREEN}$current_cc${PLAIN}"
        echo -e "队列调度算法: ${GREEN}$current_qdisc${PLAIN}"
    else
        echo -e "${RED}BBR启用失败${PLAIN}"
        echo -e "当前配置："
        echo -e "拥塞控制算法: ${RED}$current_cc${PLAIN}"
        echo -e "队列调度算法: ${RED}$current_qdisc${PLAIN}"
        echo -e "${YELLOW}请尝试重启系统后再次检查${PLAIN}"
    fi
}

# 禁用BBR
disable_bbr() {
    echo -e "${BLUE}正在禁用BBR...${PLAIN}"
    
    # 删除BBR配置文件
    rm -f /etc/sysctl.d/99-zzz-bbr-custom.conf
    
    # 创建新的默认配置，使用高优先级确保最后加载
    cat > /etc/sysctl.d/99-zzz-network-default.conf << EOF
# 默认网络配置
net.core.default_qdisc=pfifo_fast
net.ipv4.tcp_congestion_control=cubic
EOF
    
    # 直接设置当前运行的参数
    sysctl -w net.core.default_qdisc=pfifo_fast >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_congestion_control=cubic >/dev/null 2>&1
    
    # 应用系统设置
    sysctl --system >/dev/null 2>&1
    
    # 从加载模块列表中移除BBR
    sed -i '/tcp_bbr/d' /etc/modules-load.d/modules.conf 2>/dev/null
    
    # 尝试卸载BBR模块
    modprobe -r tcp_bbr 2>/dev/null
    
    # 验证是否已禁用
    sleep 1
    current_cc=$(sysctl -n net.ipv4.tcp_congestion_control)
    current_qdisc=$(sysctl -n net.core.default_qdisc)
    
    if [[ "$current_cc" == "cubic" && "$current_qdisc" == "pfifo_fast" ]]; then
        echo -e "${GREEN}BBR已成功禁用${PLAIN}"
        echo -e "当前配置："
        echo -e "拥塞控制算法: ${GREEN}$current_cc${PLAIN}"
        echo -e "队列调度算法: ${GREEN}$current_qdisc${PLAIN}"
    else
        echo -e "${RED}BBR禁用失败${PLAIN}"
        echo -e "当前配置："
        echo -e "拥塞控制算法: ${RED}$current_cc${PLAIN}"
        echo -e "队列调度算法: ${RED}$current_qdisc${PLAIN}"
        echo -e "${YELLOW}请尝试重启系统后再次检查${PLAIN}"
    fi
}

# 清理所有配置
cleanup() {
    echo -e "${BLUE}正在清理BBR相关配置...${PLAIN}"
    
    # 删除所有相关配置文件
    rm -f /etc/sysctl.d/*bbr*.conf
    rm -f /etc/sysctl.d/*network*.conf
    
    # 重置到系统默认值
    sysctl --system >/dev/null 2>&1
    
    # 从模块列表中移除
    sed -i '/tcp_bbr/d' /etc/modules-load.d/modules.conf 2>/dev/null
    
    echo -e "${GREEN}清理完成${PLAIN}"
}

# 显示菜单
show_menu() {
    show_banner
    show_status
    echo -e "请选择操作："
    echo -e "${GREEN}1.${PLAIN} 启用BBR"
    echo -e "${GREEN}2.${PLAIN} 禁用BBR"
    echo -e "${GREEN}3.${PLAIN} 查看当前状态"
    echo -e "${GREEN}4.${PLAIN} 清理所有配置"
    echo -e "${GREEN}5.${PLAIN} 退出脚本"
    echo
    read -p "请输入选项 [1-5]: " choice
    
    case $choice in
        1)
            enable_bbr
            ;;
        2)
            disable_bbr
            ;;
        3)
            show_status
            ;;
        4)
            cleanup
            ;;
        5)
            echo -e "${GREEN}感谢使用！${PLAIN}"
            exit 0
            ;;
        *)
            echo -e "${RED}无效的选项${PLAIN}"
            ;;
    esac
    
    echo
    read -p "按回车键继续..."
    show_menu
}

# 主程序
main() {
    check_root
    check_system
    check_kernel
    show_menu
}

# 运行主程序
main

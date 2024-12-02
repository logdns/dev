#!/bin/bash

# 现代化的BBR优化脚本 v2.0
# 支持 Ubuntu 和 Debian 系统
# 支持最新内核安装和优化配置

# 定义颜色变量
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[36m"
PLAIN="\033[0m"
BOLD="\033[1m"

# 进度条函数
show_progress() {
    local duration=$1
    local step=$((duration/50))
    printf "${BLUE}[${PLAIN}"
    for ((i=0;i<=50;i++)); do
        printf "#"
        sleep $step
    done
    printf "${BLUE}]${PLAIN}\n"
}

# 优雅的标题显示
print_banner() {
    clear
    echo -e "${BLUE}${BOLD}"
    echo '╔══════════════════════════════════════════╗'
    echo '║      Linux 网络性能优化安装工具         ║'
    echo '║         支持 BBR/BBR Plus/BBR2/BBR3     ║'
    echo '╚══════════════════════════════════════════╝'
    echo -e "${PLAIN}"
}

# 检查系统信息
check_system_info() {
    echo -e "${YELLOW}正在检查系统信息...${PLAIN}"
    # 检查系统版本
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
    else
        echo -e "${RED}无法确定系统版本${PLAIN}"
        exit 1
    fi
    
    # 检查架构
    ARCH=$(uname -m)
    
    echo -e "${GREEN}系统信息:${PLAIN}"
    echo -e "  操作系统: $OS"
    echo -e "  版本: $VERSION"
    echo -e "  架构: $ARCH"
}

# 安装最新内核
install_latest_kernel() {
    echo -e "${YELLOW}正在安装最新内核...${PLAIN}"
    
    # 添加内核源
    echo -e "${BLUE}添加内核源...${PLAIN}"
    if [ "$OS" = "Ubuntu" ]; then
        add-apt-repository -y ppa:cappelikan/ppa
        apt update
    fi
    
    # 安装最新主线内核
    echo -e "${BLUE}安装最新版本内核...${PLAIN}"
    apt install -y linux-generic-hwe-$(lsb_release -rs)
    
    # 等待安装完成
    show_progress 3
    
    # 获取最新内核版本
    LATEST_KERNEL=$(dpkg --list | grep linux-image | grep -v grep | tail -n1 | awk '{print $2}')
    echo -e "${GREEN}已安装内核版本: ${LATEST_KERNEL}${PLAIN}"
}

# 优化系统参数
optimize_system() {
    echo -e "${YELLOW}正在优化系统参数...${PLAIN}"
    
    # 备份原配置
    cp /etc/sysctl.conf /etc/sysctl.conf.bak
    
    # 写入优化配置
    cat > /etc/sysctl.conf << EOF
# 基础网络优化
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 65536
net.core.wmem_default = 65536
net.core.netdev_max_backlog = 250000
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864

# BBR相关优化
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000

# 其他优化
net.core.somaxconn = 8192
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
EOF
    
    sysctl -p > /dev/null 2>&1
    show_progress 2
    echo -e "${GREEN}系统参数优化完成${PLAIN}"
}

# 安装BBR的具体函数
install_bbr() {
    local bbr_type=$1
    echo -e "${YELLOW}正在安装 ${bbr_type}...${PLAIN}"
    
    case $bbr_type in
        "BBR")
            configure_sysctl "bbr"
            ;;
        "BBR Plus")
            install_bbrplus
            ;;
        "BBR2")
            install_bbr2
            ;;
        "BBR3")
            install_bbr3
            ;;
    esac
}

# 显示菜单
show_menu() {
    while true; do
        print_banner
        echo -e "${GREEN}请选择操作:${PLAIN}"
        echo -e "${BLUE}1.${PLAIN} 安装最新内核并启用原版BBR"
        echo -e "${BLUE}2.${PLAIN} 安装BBR Plus"
        echo -e "${BLUE}3.${PLAIN} 安装BBR2"
        echo -e "${BLUE}4.${PLAIN} 安装BBR3"
        echo -e "${BLUE}5.${PLAIN} 查看当前网络配置"
        echo -e "${BLUE}6.${PLAIN} 优化系统参数"
        echo -e "${BLUE}0.${PLAIN} 退出脚本"
        echo
        read -p $'\e[32m请输入选项 [0-6]: \e[0m' choice
        
        case "$choice" in
            0)
                echo -e "${GREEN}感谢使用，再见！${PLAIN}"
                exit 0
                ;;
            1)
                check_system_info
                install_latest_kernel
                install_bbr "BBR"
                ;;
            2)
                check_system_info
                install_bbr "BBR Plus"
                ;;
            3)
                check_system_info
                install_bbr "BBR2"
                ;;
            4)
                check_system_info
                install_bbr "BBR3"
                ;;
            5)
                show_status
                ;;
            6)
                optimize_system
                ;;
            *)
                echo -e "${RED}无效的选项，请重新选择${PLAIN}"
                ;;
        esac
        echo
        read -p $'\e[32m按回车键继续...\e[0m'
    done
}

# 显示当前状态
show_status() {
    echo -e "${YELLOW}系统当前状态:${PLAIN}"
    echo -e "  当前内核版本: $(uname -r)"
    echo -e "  拥塞控制算法: $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')"
    echo -e "  队列算法: $(sysctl net.core.default_qdisc | awk '{print $3}')"
    echo -e "  TCP Fast Open: $(sysctl net.ipv4.tcp_fastopen | awk '{print $3}')"
    echo
    echo -e "${BLUE}网络相关参数:${PLAIN}"
    echo -e "  TCP窗口大小: $(sysctl net.ipv4.tcp_wmem | awk '{print $3}')"
    echo -e "  最大连接数: $(sysctl net.core.somaxconn | awk '{print $3}')"
}

# 安装必要的依赖
install_dependencies() {
    echo -e "${YELLOW}安装必要的依赖...${PLAIN}"
    apt-get update > /dev/null 2>&1
    apt-get install -y wget curl gnupg software-properties-common > /dev/null 2>&1
    show_progress 2
    echo -e "${GREEN}依赖安装完成${PLAIN}"
}

# 检查root权限
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}错误：请使用root用户运行此脚本${PLAIN}"
    exit 1
fi

# 主程序开始
clear
print_banner
install_dependencies
show_menu

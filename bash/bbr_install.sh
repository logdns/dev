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
    echo -e "${BLUE}       BBR 管理脚本 v1.1           ${PLAIN}"
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
    elif [[ -f /etc/ubuntu-release ]]; then
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
    echo
}

# 启用BBR
enable_bbr() {
    echo -e "${BLUE}正在启用BBR...${PLAIN}"
    
    # 加载BBR模块
    modprobe tcp_bbr
    echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
    
    # 设置网络参数
    cat > /etc/sysctl.d/99-bbr.conf << EOF
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
EOF
    
    # 应用设置
    sysctl --system
    
    # 验证BBR是否启用
    if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
        echo -e "${GREEN}BBR已成功启用${PLAIN}"
    else
        echo -e "${RED}BBR启用失败，请检查系统设置${PLAIN}"
    fi
}

# 禁用BBR
disable_bbr() {
    echo -e "${BLUE}正在禁用BBR...${PLAIN}"
    
    # 立即修改当前运行的内核参数
    echo "cubic" > /proc/sys/net/ipv4/tcp_congestion_control
    echo "pfifo_fast" > /proc/sys/net/core/default_qdisc
    
    # 删除BBR配置文件
    rm -f /etc/sysctl.d/99-bbr.conf
    
    # 创建新的配置以确保重启后使用默认设置
    cat > /etc/sysctl.d/99-network-default.conf << EOF
net.core.default_qdisc=pfifo_fast
net.ipv4.tcp_congestion_control=cubic
EOF
    
    # 应用系统设置
    sysctl --system
    
    # 从加载模块列表中移除BBR
    sed -i '/tcp_bbr/d' /etc/modules-load.d/modules.conf
    
    # 尝试卸载BBR模块（如果没有被使用）
    modprobe -r tcp_bbr 2>/dev/null
    
    # 验证是否已禁用
    current_cc=$(sysctl -n net.ipv4.tcp_congestion_control)
    if [[ "$current_cc" != "bbr" ]]; then
        echo -e "${GREEN}BBR已成功禁用，当前使用的拥塞控制算法：${current_cc}${PLAIN}"
    else
        echo -e "${RED}BBR禁用失败，请尝试重启系统${PLAIN}"
    fi
    
    echo -e "${YELLOW}注意：某些更改可能需要重启系统才能完全生效${PLAIN}"
}

# 显示菜单
show_menu() {
    show_banner
    show_status
    echo -e "请选择操作："
    echo -e "${GREEN}1.${PLAIN} 启用BBR"
    echo -e "${GREEN}2.${PLAIN} 禁用BBR"
    echo -e "${GREEN}3.${PLAIN} 查看当前状态"
    echo -e "${GREEN}4.${PLAIN} 退出脚本"
    echo
    read -p "请输入选项 [1-4]: " choice
    
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

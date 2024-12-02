#!/bin/bash

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PLAIN='\033[0m'

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
    fi
}

# 开启BBR
enable_bbr() {
    # 检查是否已加载BBR模块
    if ! lsmod | grep -q "tcp_bbr"; then
        modprobe tcp_bbr
        echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
    fi
    
    # 设置网络参数
    cat > /etc/sysctl.d/99-bbr.conf << EOF
# 开启BBR
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

# 优化网络设置
net.core.rmem_max=26214400
net.core.wmem_max=26214400
net.core.rmem_default=1048576
net.core.wmem_default=1048576
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
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

# 主程序
main() {
    check_root
    check_system
    check_kernel
    enable_bbr
    
    echo -e "${GREEN}BBR配置完成！${PLAIN}"
    echo -e "当前TCP拥塞控制算法: $(sysctl -n net.ipv4.tcp_congestion_control)"
    echo -e "当前队列调度算法: $(sysctl -n net.core.default_qdisc)"
}

# 运行主程序
main

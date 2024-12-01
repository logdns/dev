#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # 无色

# 进度条函数
show_progress() {
    local duration=$1
    local width=50
    local progress=0
    local bar_char="█"
    
    while [ $progress -lt 100 ]; do
        let progress=progress+2
        let current=$width*$progress/100
        local bar=""
        for ((i=0; i<current; i++)); do
            bar="${bar}${bar_char}"
        done
        printf "\r[%-${width}s] %d%%" "$bar" "$progress"
        sleep $duration
    done
    echo
}

# Banner显示
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════╗"
    echo "║                                               ║"
    echo "║   🚀 Debian 系统升级助手 v2.0                ║"
    echo "║   💻 支持: Debian 9/10/11/12                 ║"
    echo "║   🔧 by: xinai.de                            ║"
    echo "║                                               ║"
    echo "╚═══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 检查是否为root用户
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}错误: 请使用root权限运行此脚本${NC}"
        exit 1
    fi
}

# 内核版本映射
declare -A KERNEL_VERSIONS=(
    ["9"]="4.9.0"  # Debian 9 (Stretch)
    ["10"]="4.19.0" # Debian 10 (Buster)
    ["11"]="5.10.0" # Debian 11 (Bullseye)
    ["12"]="6.1.0"  # Debian 12 (Bookworm)
)

# 内核管理函数
manage_kernel() {
    local target_version=$1
    local kernel_version=${KERNEL_VERSIONS[$target_version]}
    
    echo -e "${YELLOW}正在配置内核版本 $kernel_version...${NC}"
    
    case $target_version in
        "9")
            apt install -y linux-image-$kernel_version-amd64 linux-headers-$kernel_version-amd64
            ;;
        "10")
            apt install -y linux-image-$kernel_version-amd64 linux-headers-$kernel_version-amd64
            ;;
        "11")
            apt install -y linux-image-$kernel_version-amd64 linux-headers-$kernel_version-amd64
            ;;
        "12")
            apt install -y linux-image-$kernel_version-amd64 linux-headers-$kernel_version-amd64
            ;;
    esac
}

# 系统检查函数
check_system() {
    echo -e "${BLUE}正在进行系统检查...${NC}"
    
    # 检查磁盘空间
    local free_space=$(df -h / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ $(echo "$free_space < 5" | bc) -eq 1 ]; then
        echo -e "${RED}警告: 系统剩余空间不足 5GB (当前: ${free_space}GB)${NC}"
        echo -e "${YELLOW}建议清理磁盘空间后再继续${NC}"
        exit 1
    fi
    
    # 检查内存
    local total_mem=$(free -m | awk '/^Mem:/{print $2}')
    if [ $total_mem -lt 1024 ]; then
        echo -e "${YELLOW}警告: 系统内存小于1GB，可能影响升级过程${NC}"
    fi
    
    echo -e "${GREEN}系统检查完成√${NC}"
}

# 备份配置
backup_configs() {
    echo -e "${BLUE}正在备份系统配置...${NC}"
    local backup_dir="/root/debian_upgrade_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # 创建备份列表
    local backup_list=(
        "/etc/apt/sources.list"
        "/etc/network"
        "/etc/fstab"
        "/etc/hostname"
        "/etc/hosts"
        "/etc/ssh/sshd_config"
    )
    
    for item in "${backup_list[@]}"; do
        if [ -e "$item" ]; then
            cp -r "$item" "$backup_dir/"
            echo -e "${GREEN}已备份: $item${NC}"
        fi
    done
    
    echo -e "${GREEN}配置备份完成，存储在: $backup_dir${NC}"
}

# 系统清理
clean_system() {
    echo -e "${BLUE}正在清理系统...${NC}"
    
    # 首先尝试修复系统
    echo -e "${YELLOW}修复包管理系统...${NC}"
    dpkg --configure -a
    apt-get install -f -y
    
    apt-get autoremove -y
    apt-get clean
    apt-get autoclean
    
    # 改进的内核清理逻辑
    echo -e "${YELLOW}清理旧内核...${NC}"
    
    # 获取当前运行的内核版本
    current_kernel=$(uname -r)
    echo -e "${BLUE}当前使用的内核版本: $current_kernel${NC}"
    
    # 获取已安装的所有内核包列表
    kernel_packages=$(dpkg -l 'linux-image*' | awk '/^ii/ {print $2}')
    
    # 计算要保留的内核包名
    current_kernel_pkg="linux-image-${current_kernel}"
    
    # 逐个检查并删除旧内核
    for pkg in $kernel_packages; do
        # 跳过当前内核和必要的内核包
        if [[ "$pkg" == *"$current_kernel"* ]] || \
           [[ "$pkg" == "linux-image-amd64" ]] || \
           [[ "$pkg" == "linux-image-generic" ]]; then
            echo -e "${GREEN}保留内核包: $pkg${NC}"
            continue
        fi
        
        echo -e "${YELLOW}正在移除旧内核包: $pkg${NC}"
        if ! apt-get remove --purge -y "$pkg"; then
            echo -e "${RED}移除 $pkg 失败，尝试强制移除...${NC}"
            if ! dpkg --force-all -P "$pkg"; then
                echo -e "${RED}强制移除 $pkg 也失败，跳过...${NC}"
            fi
        fi
    done
    
    # 清理可能存在的孤立内核头文件包
    echo -e "${YELLOW}清理孤立的内核头文件包...${NC}"
    header_packages=$(dpkg -l 'linux-headers*' | awk '/^ii/ {print $2}')
    for pkg in $header_packages; do
        if [[ "$pkg" != *"$current_kernel"* ]] && \
           [[ "$pkg" != "linux-headers-amd64" ]] && \
           [[ "$pkg" != "linux-headers-generic" ]]; then
            echo -e "${YELLOW}移除旧内核头文件包: $pkg${NC}"
            apt-get remove --purge -y "$pkg" || dpkg --force-all -P "$pkg"
        fi
    done
    
    # 最后再次运行自动清理
    apt-get autoremove -y
    apt-get clean
    
    echo -e "${GREEN}系统清理完成√${NC}"
}

# 更新软件源
update_sources() {
    local version=$1
    echo -e "${BLUE}正在更新软件源配置...${NC}"
    
    case $version in
        "10")
            cat > /etc/apt/sources.list << EOF
# Debian 10 (Buster)
deb http://deb.debian.org/debian buster main contrib non-free
deb http://deb.debian.org/debian buster-updates main contrib non-free
deb http://security.debian.org/debian-security buster/updates main contrib non-free
EOF
            ;;
        "11")
            cat > /etc/apt/sources.list << EOF
# Debian 11 (Bullseye)
deb http://deb.debian.org/debian bullseye main contrib non-free
deb http://deb.debian.org/debian bullseye-updates main contrib non-free
deb http://security.debian.org/debian-security bullseye-security main contrib non-free
EOF
            ;;
        "12")
            cat > /etc/apt/sources.list << EOF
# Debian 12 (Bookworm)
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF
            ;;
    esac
    
    echo -e "${GREEN}软件源更新完成√${NC}"
}

# 执行升级
do_upgrade() {
    echo -e "${BLUE}开始系统升级流程...${NC}"
    
    # 首先尝试修复可能被中断的dpkg
    echo -e "${YELLOW}检查并修复dpkg状态...${NC}"
    dpkg --configure -a
    
    # 修复可能的依赖关系问题
    echo -e "${YELLOW}修复可能的依赖关系问题...${NC}"
    apt-get install -f -y
    
    echo -e "${YELLOW}更新软件包信息...${NC}"
    apt-get clean
    rm -rf /var/lib/apt/lists/*
    apt-get update
    show_progress 0.1
    
    echo -e "${YELLOW}升级基础系统包...${NC}"
    apt-get install -y apt dpkg apt-utils
    show_progress 0.1
    
    # 再次检查并修复可能的问题
    dpkg --configure -a
    apt-get install -f -y
    
    echo -e "${YELLOW}执行系统升级...${NC}"
    apt-get upgrade -y
    show_progress 0.1
    
    echo -e "${YELLOW}执行完整升级...${NC}"
    apt-get full-upgrade -y
    show_progress 0.1
    
    echo -e "${YELLOW}清理无用包...${NC}"
    apt-get autoremove -y
    apt-get clean
    show_progress 0.1
    
    echo -e "${GREEN}升级完成√${NC}"
}

# 检查升级结果
check_upgrade_result() {
    echo -e "${BLUE}正在检查升级结果...${NC}"
    
    # 检查包状态
    if dpkg -l | grep -q "^..F"; then
        echo -e "${RED}警告: 发现损坏的软件包${NC}"
        echo -e "${YELLOW}尝试修复...${NC}"
        apt install -f -y
    fi
    
    # 检查服务状态
    local failed_services=$(systemctl --failed)
    if [ -n "$failed_services" ]; then
        echo -e "${RED}警告: 以下服务出现故障:${NC}"
        echo "$failed_services"
    fi
    
    echo -e "${GREEN}检查完成√${NC}"
}

# 主菜单
show_menu() {
    show_banner
    echo -e "${WHITE}当前系统版本: ${GREEN}Debian $current_version${NC}"
    echo
    echo -e "${CYAN}可用升级选项:${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}1)${NC} ${GREEN}升级到 Debian 10 (Buster)${NC}"
    echo -e "${WHITE}2)${NC} ${GREEN}升级到 Debian 11 (Bullseye)${NC}"
    echo -e "${WHITE}3)${NC} ${GREEN}升级到 Debian 12 (Bookworm)${NC}"
    echo -e "${WHITE}4)${NC} ${RED}退出${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 获取当前debian版本
current_version=$(cat /etc/debian_version | cut -d. -f1)

# 主程序
check_root
show_menu

read -p "$(echo -e ${CYAN}请输入选项 [1-4]:${NC} )" choice

case $choice in
    1)
        if [ "$current_version" -gt 10 ]; then
            echo -e "${RED}错误: 无法降级到较低版本${NC}"
            exit 1
        fi
        echo -e "${GREEN}准备升级到 Debian 10...${NC}"
        check_system
        backup_configs
        clean_system
        update_sources "10"
        manage_kernel "10"
        do_upgrade
        check_upgrade_result
        ;;
    2)
        if [ "$current_version" -gt 11 ]; then
            echo -e "${RED}错误: 无法降级到较低版本${NC}"
            exit 1
        fi
        echo -e "${GREEN}准备升级到 Debian 11...${NC}"
        check_system
        backup_configs
        clean_system
        update_sources "11"
        manage_kernel "11"
        do_upgrade
        check_upgrade_result
        ;;
    3)
        if [ "$current_version" -gt 12 ]; then
            echo -e "${RED}错误: 无法降级到较低版本${NC}"
            exit 1
        fi
        echo -e "${GREEN}准备升级到 Debian 12...${NC}"
        check_system
        backup_configs
        clean_system
        update_sources "12"
        manage_kernel "12"
        do_upgrade
        check_upgrade_result
        ;;
    4)
        echo -e "${YELLOW}退出脚本${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}无效选项${NC}"
        exit 1
        ;;
esac

echo -e "\n${GREEN}升级流程已完成!${NC}"
echo -e "${YELLOW}升级后检查事项:${NC}"
echo -e "${WHITE}1. 检查重要服务状态: ${CYAN}systemctl --failed${NC}"
echo -e "${WHITE}2. 检查系统日志: ${CYAN}tail -n 50 /var/log/syslog${NC}"
echo -e "${WHITE}3. 检查网络连接${NC}"
echo -e "${WHITE}4. 检查新内核版本: ${CYAN}uname -r${NC}"

echo -e "\n${YELLOW}是否现在重启系统? (y/n)${NC}"
read -p "> " restart

if [ "$restart" = "y" ] || [ "$restart" = "Y" ]; then
    echo -e "${GREEN}系统将在5秒后重启...${NC}"
    for i in {5..1}; do
        echo -ne "${YELLOW}$i...${NC}"
        sleep 1
    done
    echo
    reboot
fi

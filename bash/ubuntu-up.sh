#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# 进度条函数
show_progress() {
    local duration=$1
    local width=50
    local progress=0
    while [ $progress -le 100 ]; do
        local count=$(($width * $progress / 100))
        printf "\r[${GREEN}"
        printf "%-${width}s${NC}] ${progress}%%" $(printf "#%.0s" $(seq 1 $count))
        progress=$((progress + 2))
        sleep "$duration"
    done
    printf "\n"
}

# 显示标题
show_header() {
    clear
    echo -e "${BLUE}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                  Ubuntu系统升级助手                           ║"
    echo "║                     by: xinai.de                             ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 检查系统要求
check_requirements() {
    echo -e "${YELLOW}[系统检查]${NC} 正在验证系统要求..."
    
    # 检查 root 权限
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}[错误]${NC} 请使用 sudo 运行此脚本"
        exit 1
    fi

    # 检查当前系统版本
    current_version=$(lsb_release -rs)
    if [ "$current_version" != "18.04" ]; then
        echo -e "${RED}[错误]${NC} 此脚本仅支持从 Ubuntu 18.04 升级"
        exit 1
    fi

    # 检查可用磁盘空间
    available_space=$(df -h / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ $(echo "$available_space < 10" | bc) -eq 1 ]; then
        echo -e "${RED}[警告]${NC} 可用空间不足 10GB，建议清理磁盘空间后再升级"
        exit 1
    fi

    # 检查网络连接
    if ! ping -c 1 archive.ubuntu.com &> /dev/null; then
        echo -e "${RED}[错误]${NC} 无法连接到 Ubuntu 源，请检查网络连接"
        exit 1
    fi

    echo -e "${GREEN}[完成]${NC} 系统检查通过"
    sleep 2
}

# 获取推荐内核版本
get_recommended_kernel() {
    local ubuntu_version=$1
    case $ubuntu_version in
        "20.04")
            echo "5.4.0-42-generic 5.4.0-156-generic 5.15.0-92-generic"
            ;;
        "22.04")
            echo "5.15.0-30-generic 5.15.0-92-generic 5.19.0-50-generic 6.2.0-39-generic"
            ;;
        "24.04")
            echo "6.5.0-13-generic 6.6.0-13-generic 6.7.0-10-generic"
            ;;
    esac
}

# 备份系统
backup_system() {
    echo -e "${YELLOW}[备份]${NC} 开始备份系统关键文件..."
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    backup_dir="/root/ubuntu_upgrade_backup_$timestamp"
    mkdir -p "$backup_dir"

    # 备份重要配置文件
    cp /etc/apt/sources.list "$backup_dir/"
    cp -r /etc/apt/sources.list.d "$backup_dir/"
    cp /etc/fstab "$backup_dir/"
    cp /etc/default/grub "$backup_dir/"
    
    echo -e "${GREEN}[完成]${NC} 备份已保存到 $backup_dir"
    sleep 2
}

# 安装指定内核版本
install_kernel() {
    local kernel_version=$1
    echo -e "${YELLOW}[内核安装]${NC} 正在安装内核 $kernel_version..."
    
    apt-get update
    apt-get install -y linux-image-$kernel_version linux-headers-$kernel_version
    
    echo -e "${GREEN}[完成]${NC} 内核安装完成"
}

# 升级系统函数
upgrade_system() {
    local target_version=$1
    local codename=$2
    
    echo -e "${YELLOW}[升级准备]${NC} 准备升级到 Ubuntu $target_version..."
    
    # 更新软件源
    cat > /etc/apt/sources.list << EOF
deb http://archive.ubuntu.com/ubuntu/ $codename main restricted
deb http://archive.ubuntu.com/ubuntu/ $codename-updates main restricted
deb http://archive.ubuntu.com/ubuntu/ $codename universe
deb http://archive.ubuntu.com/ubuntu/ $codename-updates universe
deb http://archive.ubuntu.com/ubuntu/ $codename multiverse
deb http://archive.ubuntu.com/ubuntu/ $codename-updates multiverse
deb http://archive.ubuntu.com/ubuntu/ $codename-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ $codename-security main restricted
deb http://security.ubuntu.com/ubuntu/ $codename-security universe
deb http://security.ubuntu.com/ubuntu/ $codename-security multiverse
EOF

    echo -e "${CYAN}[进度]${NC} 更新软件包列表..."
    apt-get update
    show_progress 0.1
    
    echo -e "${CYAN}[进度]${NC} 升级现有软件包..."
    apt-get upgrade -y
    show_progress 0.1
    
    echo -e "${CYAN}[进度]${NC} 进行发行版升级..."
    apt-get dist-upgrade -y
    show_progress 0.1
    
    # 清理系统
    echo -e "${CYAN}[进度]${NC} 清理系统..."
    apt-get clean
    apt-get autoremove -y
    dpkg --configure -a
    apt-get -f install
    show_progress 0.1
}

# 显示内核选择菜单
select_kernel() {
    local target_version=$1
    local kernels=$(get_recommended_kernel "$target_version")
    
    echo -e "\n${CYAN}${BOLD}可用内核版本:${NC}"
    local i=1
    for kernel in $kernels; do
        echo -e "${YELLOW}$i)${NC} $kernel"
        i=$((i+1))
    done
    
    echo -e "${YELLOW}0)${NC} 使用默认内核"
    
    read -p "请选择要安装的内核版本 [0-$((i-1))]: " kernel_choice
    
    if [ "$kernel_choice" != "0" ]; then
        local selected_kernel=$(echo $kernels | cut -d' ' -f$kernel_choice)
        install_kernel "$selected_kernel"
    fi
}

# 主菜单
main_menu() {
    while true; do
        show_header
        echo -e "${CYAN}当前系统版本:${NC} Ubuntu $current_version"
        echo -e "${CYAN}可用磁盘空间:${NC} ${GREEN}$available_space${NC} GB"
        echo
        echo -e "${YELLOW}请选择目标版本:${NC}"
        echo -e "${BOLD}1)${NC} Ubuntu 20.04 LTS (Focal Fossa)"
        echo -e "${BOLD}2)${NC} Ubuntu 22.04 LTS (Jammy Jellyfish)"
        echo -e "${BOLD}3)${NC} Ubuntu 24.04 LTS (Noble Numbat)"
        echo -e "${BOLD}4)${NC} 退出"
        echo
        read -p "请输入选择 [1-4]: " choice

        case $choice in
            1)
                check_requirements
                backup_system
                upgrade_system "20.04" "focal"
                select_kernel "20.04"
                ;;
            2)
                check_requirements
                backup_system
                upgrade_system "22.04" "jammy"
                select_kernel "22.04"
                ;;
            3)
                check_requirements
                backup_system
                upgrade_system "24.04" "noble"
                select_kernel "24.04"
                ;;
            4)
                echo -e "${GREEN}感谢使用！再见！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}无效选择，请重试${NC}"
                sleep 2
                ;;
        esac

        if [ $? -eq 0 ]; then
            echo -e "\n${GREEN}${BOLD}升级完成!${NC}"
            echo -e "${YELLOW}建议重启系统以应用更改。是否现在重启? (y/n)${NC}"
            read -r answer
            if [ "$answer" = "y" ]; then
                reboot
            fi
        fi
    done
}

# 启动脚本
main_menu

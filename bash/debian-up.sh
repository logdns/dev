#!/bin/bash
# By xinai.de
# Debian System Upgrade Script with Enhanced UI

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Logo显示
show_logo() {
    clear
    echo -e "${CYAN}"
    echo "▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄"
    echo "█ Debian System Upgrade Tool                █"
    echo "█ Created by xinai.de                      █"
    echo "█ Version: 1.1.0                          █"
    echo "▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀"
    echo -e "${NC}"
}

# 显示进度条
show_progress() {
    local duration=$1
    local prefix=$2
    local width=50
    local fill="█"
    local empty="░"
    
    echo -ne "\n"
    for i in $(seq 1 $width); do
        echo -ne "\r${prefix} [" 
        for j in $(seq 1 $i); do
            echo -ne "${CYAN}${fill}${NC}"
        done
        for j in $(seq $i $width); do
            echo -ne "${empty}"
        done
        echo -ne "] $((i*100/width))%"
        sleep $(bc <<< "scale=3; $duration/$width")
    done
    echo -ne "\n"
}

# 系统清理函数
clean_system() {
    echo -e "\n${BLUE}开始系统清理...${NC}"
    echo -e "${YELLOW}注意: 清理过程将移除不必要的文件和软件包${NC}\n"
    
    echo -e "${CYAN}Step 1/8: 清理APT缓存${NC}"
    apt-get clean
    show_progress 1 "清理APT缓存"
    
    echo -e "\n${CYAN}Step 2/8: 清理旧的软件包${NC}"
    apt-get autoremove -y
    show_progress 1 "清理旧包"
    
    echo -e "\n${CYAN}Step 3/8: 清理孤立的软件包${NC}"
    deborphan | xargs apt-get -y remove --purge
    show_progress 1 "清理孤立包"
    
    echo -e "\n${CYAN}Step 4/8: 清理临时文件${NC}"
    rm -rf /tmp/*
    rm -rf /var/tmp/*
    show_progress 1 "清理临时文件"
    
    echo -e "\n${CYAN}Step 5/8: 清理日志文件${NC}"
    find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;
    find /var/log -type f -name "*.gz" -delete
    show_progress 1 "清理日志"
    
    echo -e "\n${CYAN}Step 6/8: 清理缩略图缓存${NC}"
    find /home -type f -name "*.thumbnail" -delete
    find /home -type f -name "Thumbs.db" -delete
    show_progress 1 "清理缩略图"
    
    echo -e "\n${CYAN}Step 7/8: 清理Firefox缓存${NC}"
    find /home -type d -name ".mozilla" -exec rm -rf {}/firefox/*.default/cache \;
    show_progress 1 "清理浏览器缓存"
    
    echo -e "\n${CYAN}Step 8/8: 清理系统缓存${NC}"
    sync && echo 3 > /proc/sys/vm/drop_caches
    show_progress 1 "清理系统缓存"
    
    # 显示清理结果
    echo -e "\n${GREEN}系统清理完成！${NC}"
    echo -e "清理前磁盘使用情况:"
    echo -e "${YELLOW}$disk_space_before${NC}"
    disk_space_after=$(df -h / | awk 'NR==2 {print $4}')
    echo -e "清理后磁盘使用情况:"
    echo -e "${GREEN}$disk_space_after${NC}"
}

# 检查是否以root权限运行
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}${BOLD}错误: 请以root权限运行此脚本${NC}"
        echo -e "使用命令: ${YELLOW}sudo $0${NC}"
        exit 1
    fi
}

# 系统信息检查
check_system_info() {
    echo -e "${BLUE}正在检查系统信息...${NC}"
    show_progress 2 "系统检查"
    
    # 获取系统信息
    current_version=$(cat /etc/debian_version)
    total_memory=$(free -h | awk '/^Mem:/{print $2}')
    available_memory=$(free -h | awk '/^Mem:/{print $7}')
    disk_space=$(df -h / | awk 'NR==2 {print $4}')
    disk_space_before=$disk_space
    
    echo -e "\n${BOLD}系统信息:${NC}"
    echo -e "${CYAN}▸ 当前Debian版本:${NC} $current_version"
    echo -e "${CYAN}▸ 总内存:${NC} $total_memory"
    echo -e "${CYAN}▸ 可用内存:${NC} $available_memory"
    echo -e "${CYAN}▸ 根分区可用空间:${NC} $disk_space"
    echo -e "\n${YELLOW}注意: 升级需要至少2GB可用内存和5GB磁盘空间${NC}\n"
}

# 备份sources.list
backup_sources() {
    local backup_file="/etc/apt/sources.list.backup.$(date +%Y%m%d)"
    echo -e "${BLUE}正在备份sources.list...${NC}"
    cp /etc/apt/sources.list $backup_file
    show_progress 1 "备份进行中"
    echo -e "${GREEN}已备份到: $backup_file${NC}"
}

# 更新系统
update_system() {
    echo -e "\n${BLUE}开始系统更新...${NC}"
    echo -e "${YELLOW}注意: 更新过程可能需要较长时间，请保持网络连接${NC}\n"
    
    echo -e "${CYAN}Step 1/4: 更新软件源${NC}"
    apt update
    
    echo -e "\n${CYAN}Step 2/4: 升级已安装的包${NC}"
    apt upgrade -y
    
    echo -e "\n${CYAN}Step 3/4: 进行完整升级${NC}"
    apt full-upgrade -y
    
    echo -e "\n${CYAN}Step 4/4: 清理无用包${NC}"
    apt autoremove -y
    apt clean
}

# 升级到Debian 11
upgrade_to_bullseye() {
    echo -e "\n${PURPLE}准备升级到 Debian 11 (Bullseye)...${NC}"
    backup_sources
    
    echo -e "\n${BLUE}更新软件源配置...${NC}"
    cat > /etc/apt/sources.list << EOF
deb http://deb.debian.org/debian bullseye main contrib non-free
deb http://deb.debian.org/debian bullseye-updates main contrib non-free
deb http://security.debian.org/debian-security bullseye-security main contrib non-free
EOF
    
    update_system
    echo -e "\n${GREEN}${BOLD}系统已成功升级到 Debian 11${NC}"
}

# 升级到Debian 12
upgrade_to_bookworm() {
    echo -e "\n${PURPLE}准备升级到 Debian 12 (Bookworm)...${NC}"
    backup_sources
    
    echo -e "\n${BLUE}更新软件源配置...${NC}"
    cat > /etc/apt/sources.list << EOF
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF
    
    update_system
    echo -e "\n${GREEN}${BOLD}系统已成功升级到 Debian 12${NC}"
}

# 主菜单
main_menu() {
    while true; do
        show_logo
        echo -e "${BOLD}请选择操作:${NC}"
        echo -e "${CYAN}1)${NC} 升级到 Debian 11 (Bullseye)"
        echo -e "${CYAN}2)${NC} 升级到 Debian 12 (Bookworm)"
        echo -e "${CYAN}3)${NC} 清理系统垃圾"
        echo -e "${CYAN}4)${NC} 退出"
        echo -e "\n${YELLOW}提示: 升级前请确保已备份重要数据${NC}"
        
        read -p $'\033[0;36m请输入选项 (1-4): \033[0m' choice
        
        case $choice in
            1)
                upgrade_to_bullseye
                break
                ;;
            2)
                upgrade_to_bookworm
                break
                ;;
            3)
                clean_system
                read -p $'\033[0;36m按回车键返回主菜单\033[0m'
                ;;
            4)
                echo -e "\n${GREEN}感谢使用，再见！${NC}"
                exit 0
                ;;
            *)
                echo -e "\n${RED}无效选项，请重新选择${NC}"
                sleep 2
                ;;
        esac
    done
}

# 脚本主体
check_root
check_system_info
main_menu

echo -e "\n${YELLOW}${BOLD}升级完成后建议重启系统以应用所有更改${NC}"
read -p $'\033[0;36m是否现在重启? (y/n): \033[0m' reboot_choice

if [ "$reboot_choice" = "y" ] || [ "$reboot_choice" = "Y" ]; then
    echo -e "\n${GREEN}系统将在5秒后重启...${NC}"
    sleep 5
    reboot
else
    echo -e "\n${GREEN}请记得稍后手动重启系统${NC}"
fi

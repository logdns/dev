#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志文件
LOG_FILE="/var/log/ubuntu_server_upgrade.log"

# 日志函数
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[$timestamp] $1" | tee -a "$LOG_FILE"
}

# 获取系统信息
get_system_info() {
    current_version=$(lsb_release -rs 2>/dev/null || echo "未知")
    available_space=$(df -B1G / | awk 'NR==2 {printf "%.2f", $4}' 2>/dev/null || echo "未知")
    total_space=$(df -B1G / | awk 'NR==2 {printf "%.2f", $2}' 2>/dev/null || echo "未知")
    system_arch=$(uname -m)
}

# 显示系统信息
show_system_info() {
    clear
    echo -e "${BLUE}=== Ubuntu Server 升级工具 ===${NC}"
    echo -e "${YELLOW}系统信息:${NC}"
    echo -e "当前系统版本: Ubuntu ${current_version}"
    echo -e "系统架构: ${system_arch}"
    echo -e "系统总空间: ${total_space} GB"
    echo -e "可用磁盘空间: ${available_space} GB"
    echo
}

# 系统检查
check_requirements() {
    log "开始系统检查..."

    # 检查 root 权限
    if [ "$EUID" -ne 0 ]; then 
        log "${RED}错误: 请使用 root 权限运行此脚本${NC}"
        exit 1
    fi

    # 检查系统版本
    if [ "$current_version" = "未知" ]; then
        log "${RED}错误: 无法获取系统版本信息${NC}"
        exit 1
    fi

    # 检查网络连接
    if ! ping -c 1 archive.ubuntu.com &>/dev/null; then
        log "${RED}错误: 无法连接到 Ubuntu 存储库${NC}"
        exit 1
    fi

    log "${GREEN}系统检查完成${NC}"
}

# 备份系统
backup_system() {
    local backup_dir="/root/ubuntu_backup_$(date +%Y%m%d_%H%M%S)"
    log "开始系统备份到 $backup_dir..."

    mkdir -p "$backup_dir"
    
    # 备份重要配置文件
    cp -r /etc/apt "$backup_dir/"
    cp /etc/fstab "$backup_dir/"
    cp -r /etc/ssh "$backup_dir/"
    
    # 备份服务配置
    if [ -d "/etc/nginx" ]; then cp -r /etc/nginx "$backup_dir/"; fi
    if [ -d "/etc/apache2" ]; then cp -r /etc/apache2 "$backup_dir/"; fi
    if [ -d "/etc/mysql" ]; then cp -r /etc/mysql "$backup_dir/"; fi
    if [ -d "/etc/php" ]; then cp -r /etc/php "$backup_dir/"; fi
    
    # 备份服务状态
    systemctl list-unit-files --state=enabled > "$backup_dir/enabled_services.txt"
    
    # 备份防火墙规则
    if command -v iptables &>/dev/null; then
        iptables-save > "$backup_dir/iptables_backup"
    fi
    
    # 备份用户列表
    cp /etc/passwd "$backup_dir/"
    cp /etc/group "$backup_dir/"
    cp /etc/shadow "$backup_dir/"
    
    log "${GREEN}系统备份完成: $backup_dir${NC}"
    BACKUP_DIR=$backup_dir
}

# 准备升级
prepare_upgrade() {
    local target_version=$1
    local codename=$2
    
    log "准备升级到 Ubuntu $target_version..."
    
    # 停止不必要的服务
    log "停止非关键服务..."
    systemctl stop apache2 2>/dev/null
    systemctl stop nginx 2>/dev/null
    systemctl stop mysql 2>/dev/null
    
    # 更新当前系统
    log "更新当前系统包..."
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
    
    # 清理系统
    log "清理系统..."
    apt-get -y autoremove
    apt-get clean
    
    # 更新软件源
    log "更新软件源为 $codename..."
    cat > /etc/apt/sources.list << EOF
deb http://archive.ubuntu.com/ubuntu/ $codename main restricted
deb http://archive.ubuntu.com/ubuntu/ $codename-updates main restricted
deb http://archive.ubuntu.com/ubuntu/ $codename-security main restricted
deb http://archive.ubuntu.com/ubuntu/ $codename universe
deb http://archive.ubuntu.com/ubuntu/ $codename-updates universe
deb http://archive.ubuntu.com/ubuntu/ $codename multiverse
deb http://archive.ubuntu.com/ubuntu/ $codename-updates multiverse
deb http://archive.ubuntu.com/ubuntu/ $codename-backports main restricted universe multiverse
EOF
}

# 执行升级
do_upgrade() {
    local target_version=$1
    
    log "开始系统升级..."
    
    # 更新包信息
    apt-get update
    
    # 升级系统
    DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade
    
    # 安装新内核
    log "安装服务器内核..."
    apt-get install -y linux-image-server linux-headers-server
    
    # 清理旧包
    apt-get -y autoremove
    apt-get clean
    
    log "${GREEN}系统升级完成${NC}"
}

# 升级后检查
post_upgrade_check() {
    log "执行升级后检查..."
    
    # 检查系统版本
    local new_version=$(lsb_release -rs)
    log "新系统版本: Ubuntu $new_version"
    
    # 检查服务状态
    log "检查关键服务状态..."
    local services=("ssh" "nginx" "apache2" "mysql")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet $service; then
            log "$service: ${GREEN}运行中${NC}"
        else
            log "$service: ${RED}未运行${NC}"
        fi
    done
    
    # 检查网络连接
    if ping -c 1 archive.ubuntu.com &>/dev/null; then
        log "网络连接: ${GREEN}正常${NC}"
    else
        log "网络连接: ${RED}异常${NC}"
    fi
}

# 主升级流程
perform_upgrade() {
    local target_version=$1
    local codename=$2
    
    # 显示升级计划
    echo -e "\n${YELLOW}升级计划:${NC}"
    echo "1. 系统备份"
    echo "2. 停止非必要服务"
    echo "3. 更新系统包"
    echo "4. 执行版本升级"
    echo "5. 安装新内核"
    echo "6. 系统检查"
    echo
    read -p "是否继续升级? (y/n): " confirm
    if [ "$confirm" != "y" ]; then
        log "用户取消升级"
        exit 0
    fi
    
    # 执行升级流程
    backup_system
    prepare_upgrade "$target_version" "$codename"
    do_upgrade "$target_version"
    post_upgrade_check
    
    # 提示重启
    echo -e "\n${GREEN}升级完成!${NC}"
    echo -e "备份目录: $BACKUP_DIR"
    echo -e "${YELLOW}建议重启系统以完成升级${NC}"
    read -p "是否现在重启? (y/n): " reboot_choice
    if [ "$reboot_choice" = "y" ]; then
        log "系统重启..."
        reboot
    fi
}

# 主菜单
main_menu() {
    get_system_info
    show_system_info
    
    echo "请选择目标版本:"
    echo "1) Ubuntu 20.04 LTS (Focal Fossa)"
    echo "2) Ubuntu 22.04 LTS (Jammy Jellyfish)"
    echo "3) Ubuntu 24.04 LTS (Noble Numbat)"
    echo "4) 退出"
    echo
    read -p "请输入选择 [1-4]: " choice
    
    case $choice in
        1)
            check_requirements
            perform_upgrade "20.04" "focal"
            ;;
        2)
            check_requirements
            perform_upgrade "22.04" "jammy"
            ;;
        3)
            check_requirements
            perform_upgrade "24.04" "noble"
            ;;
        4)
            echo -e "${YELLOW}退出脚本${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            exit 1
            ;;
    esac
}

# 脚本入口
main_menu

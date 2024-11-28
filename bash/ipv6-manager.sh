#!/bin/bash

# 检查是否以root权限运行
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "请以root权限运行此脚本"
        exit 1
    fi
}

# 检查系统类型
check_system() {
    if [ -f /etc/debian_version ]; then
        return 0
    else
        echo "此脚本仅支持Debian/Ubuntu系统"
        exit 1
    fi
}

# 获取当前IPv6状态
get_ipv6_status() {
    if [ "$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6)" -eq 0 ]; then
        echo "当前IPv6状态: 启用"
    else
        echo "当前IPv6状态: 禁用"
    fi
}

# 启用IPv6
enable_ipv6() {
    # 删除禁用配置
    sed -i '/net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.conf
    sed -i '/net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.conf
    sed -i '/net.ipv6.conf.lo.disable_ipv6/d' /etc/sysctl.conf

    # 添加启用配置
    echo "net.ipv6.conf.all.disable_ipv6 = 0" >> /etc/sysctl.conf
    echo "net.ipv6.conf.default.disable_ipv6 = 0" >> /etc/sysctl.conf
    echo "net.ipv6.conf.lo.disable_ipv6 = 0" >> /etc/sysctl.conf

    # 应用配置
    sysctl -p

    echo "IPv6已启用"
}

# 禁用IPv6
disable_ipv6() {
    # 删除现有配置
    sed -i '/net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.conf
    sed -i '/net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.conf
    sed -i '/net.ipv6.conf.lo.disable_ipv6/d' /etc/sysctl.conf

    # 添加禁用配置
    echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf

    # 应用配置
    sysctl -p

    echo "IPv6已禁用"
}

# 主菜单
show_menu() {
    clear
    echo "==================================="
    echo "     IPv6 配置管理工具"
    echo "==================================="
    echo "1. 查看当前IPv6状态"
    echo "2. 启用IPv6"
    echo "3. 禁用IPv6"
    echo "4. 退出"
    echo "==================================="
    echo "请输入选项 [1-4]: "
}

# 主程序
main() {
    check_root
    check_system

    while true; do
        show_menu
        read -r choice

        case $choice in
            1)
                get_ipv6_status
                echo -e "\n按回车键继续..."
                read -r
                ;;
            2)
                enable_ipv6
                echo -e "\n按回车键继续..."
                read -r
                ;;
            3)
                disable_ipv6
                echo -e "\n按回车键继续..."
                read -r
                ;;
            4)
                echo "感谢使用！"
                exit 0
                ;;
            *)
                echo "无效选项，请重新选择"
                sleep 2
                ;;
        esac
    done
}

# 运行主程序
main

#!/bin/bash

# 修改 root 密码
echo "root:123123" | chpasswd

# 屏蔽 Include 行
sed -i 's/^Include \/etc\/ssh\/ssh_config.d\/\*.conf/#Include \/etc\/ssh\/ssh_config.d\/\*.conf/g' /etc/ssh/sshd_config

# 设置 PermitRootLogin 和 PasswordAuthentication
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config

# 设置 iptables 规则
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -F

# 重启 SSH 服务
systemctl restart sshd

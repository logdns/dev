#!/bin/bash

# 修改 root 密码
echo "root:123123" | sudo chpasswd

# 屏蔽 Include 行
sudo sed -i 's/^Include \/etc\/ssh\/ssh_config.d\/\*.conf/#Include \/etc\/ssh\/ssh_config.d\/\*.conf/g' /etc/ssh/sshd_config

# 设置 PermitRootLogin 和 PasswordAuthentication
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config

# 设置 iptables 规则
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo iptables -F

# 重启 SSH 服务
sudo systemctl restart sshd

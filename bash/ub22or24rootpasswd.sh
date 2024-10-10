#!/bin/bash
# 修改 root 密码
echo "root:123123" | chpasswd

# 设置 PermitRootLogin 和 PasswordAuthentication
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config.d/*; sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config.d/*

# 重启 SSH 服务
systemctl restart ssh sshd

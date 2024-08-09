#!/bin/bash

# 检查是否具有root权限
if [ "$EUID" -ne 0 ]; then
    echo "请使用root用户权限运行此脚本。"
    exit 1
fi

# 1. 备份当前的 SSH 配置文件
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# 2. 修改 sshd 配置文件，禁用PublicKeyAuthentication
sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication no/' /etc/ssh/sshd_config

# 3. 重新启动 SSH 服务以应用更改
systemctl restart sshd

# 4. 删除已配置的所有SSH keys (可选步骤)
# 请注意，这会删除当前用户的所有已配置的SSH keys，如果你想保留某些用户的 key，可以调整以下路径或用for循环处理用户列表
rm -rf /root/.ssh/authorized_keys
# 如果需要，逐个用户删除 .ssh 目录内的 authorized_keys 文件，以下为示例：
# for user in $(ls /home); do rm -rf /home/$user/.ssh/authorized_keys; done

# 5. 设置 root 密码
echo 'root:qq123456789' | chpasswd

echo "SSH key 登录已禁用，root 密码已设置为 'qq123456789'"

# 一定要提示用户之前配置 SSH 登录方式已经改变
echo "请注意，SSH key 登录已经被禁用，请确保你能通过密码登录！"

#!/bin/bash
echo "passwd" | passwd --stdin root > /dev/null;sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config*;sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config*;service sshd restart

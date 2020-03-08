#!/bin/bash
echo "passwd" | passwd --stdin root > /dev/null;sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_c*;sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_c*;service sshd restart

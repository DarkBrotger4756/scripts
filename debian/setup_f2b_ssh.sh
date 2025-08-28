#!/bin/bash
set -e

# Установка fail2ban
apt update
apt install -y fail2ban

# Создание jail.local
cat >/etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1 194.32.141.205/32 77.37.97.27/32
bantime  = 10m
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port    = ssh
logpath = /var/log/auth.log
backend = systemd
EOF

# Включение и запуск fail2ban
systemctl enable fail2ban
systemctl restart fail2ban

echo "✅ Fail2Ban установлен и настроен."
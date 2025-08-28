#!/bin/bash

set -e

# Запрос IP для исключения
read -p "Введите список IP-адресов через пробел, которые нужно добавить в ignoreip: " IGNORE_IPS

# Установка fail2ban, если не установлен
if ! command -v fail2ban-server >/dev/null 2>&1; then
    apt update && apt install -y fail2ban
fi

JAIL_FILE="/etc/fail2ban/jail.local"

# Если файла нет — создаём
if [ ! -f "$JAIL_FILE" ]; then
    cat > "$JAIL_FILE" <<EOF
[DEFAULT]
ignoreip = 127.0.0.1/8
bantime  = 10m
findtime = 10m
maxretry = 5
EOF
fi

# Обновляем ignoreip
sed -i "s|^\(ignoreip\s*=\s*\)|\1$IGNORE_IPS |" "$JAIL_FILE"

# Добавляем секцию для mysqld-auth, если её нет
if ! grep -q "^\[mysqld-auth\]" "$JAIL_FILE"; then
    cat >> "$JAIL_FILE" <<EOF

[mysqld-auth]
enabled  = true
port     = 3306
filter   = mysqld-auth
logpath  = /var/log/mysql/error.log
maxretry = 5
EOF
fi

systemctl restart fail2ban
echo "Fail2ban настроен для MySQL."

sleep 3
fail2ban-client status mysqld-auth
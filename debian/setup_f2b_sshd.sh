#!/bin/bash

set -e

# Проверка и установка fail2ban
if ! command -v fail2ban-server >/dev/null 2>&1; then
    echo "Устанавливаю fail2ban..."
    apt update && apt install -y fail2ban
else
    echo "Fail2ban уже установлен."
fi

# Запрос IP-адресов для исключения
read -p "Введите IP-адреса через пробел, которые нужно исключить (ignoreip): " IGNORE_IPS

JAIL_FILE="/etc/fail2ban/jail.local"

# Создание или обновление jail.local
if [ ! -f "$JAIL_FILE" ]; then
    echo "Создаю $JAIL_FILE..."
    cat <<EOF > "$JAIL_FILE"
[sshd]
enabled = true
port    = ssh
filter  = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime  = 3600
ignoreip = 127.0.0.1/8 $IGNORE_IPS
EOF
else
    echo "Обновляю jail.local для sshd..."
    if grep -q "^\[sshd\]" "$JAIL_FILE"; then
        sed -i "/^\[sshd\]/,/^\[.*\]/ s/^ignoreip.*/ignoreip = 127.0.0.1\/8 $IGNORE_IPS/" "$JAIL_FILE"
    else
        cat <<EOF >> "$JAIL_FILE"

[sshd]
enabled = true
port    = ssh
filter  = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime  = 3600
ignoreip = 127.0.0.1/8 $IGNORE_IPS
EOF
    fi
fi

systemctl restart fail2ban
echo "Fail2ban для SSH настроен и перезапущен."
fail2ban-client status sshd
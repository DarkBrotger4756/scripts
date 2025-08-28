#!/bin/bash
set -e

JAIL_LOCAL="/etc/fail2ban/jail.local"

# 1. Установка fail2ban
if ! command -v fail2ban-client &>/dev/null; then
    echo "[INFO] Устанавливаю fail2ban..."
    if [ -f /etc/debian_version ]; then
        apt-get update && apt-get install -y fail2ban
    elif [ -f /etc/redhat-release ]; then
        yum install -y epel-release && yum install -y fail2ban
    else
        echo "[ERROR] Неизвестная ОС, установите fail2ban вручную."
        exit 1
    fi
else
    echo "[INFO] fail2ban уже установлен."
fi

# 2. Создание/обновление jail.local
mkdir -p /etc/fail2ban

if [ ! -f "$JAIL_LOCAL" ]; then
    echo "[INFO] Создаю $JAIL_LOCAL"
    cat > "$JAIL_LOCAL" <<EOF
[DEFAULT]
ignoreip = 127.0.0.1/8
bantime  = 10m
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port    = ssh
logpath = /var/log/auth.log
backend = systemd
EOF
else
    echo "[INFO] Обновляю $JAIL_LOCAL"
    # гарантируем, что секция [DEFAULT] есть
    grep -q "^\[DEFAULT\]" "$JAIL_LOCAL" || cat >> "$JAIL_LOCAL" <<EOF

[DEFAULT]
ignoreip = 127.0.0.1/8
bantime  = 10m
findtime = 10m
maxretry = 5
EOF

    # гарантируем, что секция [sshd] есть
    grep -q "^\[sshd\]" "$JAIL_LOCAL" || cat >> "$JAIL_LOCAL" <<EOF

[sshd]
enabled = true
port    = ssh
logpath = /var/log/auth.log
backend = systemd
EOF
fi

# 3. Проверка синтаксиса
echo "[INFO] Проверяю конфигурацию..."
fail2ban-client -d >/dev/null

# 4. Перезапуск
echo "[INFO] Перезапускаю fail2ban..."
systemctl enable --now fail2ban
systemctl restart fail2ban

echo "[INFO] Настройка sshd jail завершена!"

sleep 2
fail2ban-client status sshd
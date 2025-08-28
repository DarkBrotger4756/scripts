#!/bin/bash
set -e

JAIL_LOCAL="/etc/fail2ban/jail.local"
FILTER_FILE="/etc/fail2ban/filter.d/mysqld-auth.conf"

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

# 2. Фильтр для MySQL (если нет)
if [ ! -f "$FILTER_FILE" ]; then
    echo "[INFO] Создаю фильтр $FILTER_FILE"
    cat > "$FILTER_FILE" <<'EOF'
[Definition]
failregex = ^.*Access denied for user .* from <HOST>.*$
ignoreregex =
EOF
fi

# 3. Создание/обновление jail.local
mkdir -p /etc/fail2ban

if [ ! -f "$JAIL_LOCAL" ]; then
    echo "[INFO] Создаю $JAIL_LOCAL"
    cat > "$JAIL_LOCAL" <<EOF
[DEFAULT]
ignoreip = 127.0.0.1/8
bantime  = 10m
findtime = 10m
maxretry = 5

[mysqld-auth]
enabled  = true
filter   = mysqld-auth
port     = 3306
logpath  = /var/log/mysql/error.log
EOF
else
    echo "[INFO] Обновляю $JAIL_LOCAL"
    grep -q "^\[DEFAULT\]" "$JAIL_LOCAL" || cat >> "$JAIL_LOCAL" <<EOF

[DEFAULT]
ignoreip = 127.0.0.1/8
bantime  = 10m
findtime = 10m
maxretry = 5
EOF

    grep -q "^\[mysqld-auth\]" "$JAIL_LOCAL" || cat >> "$JAIL_LOCAL" <<EOF

[mysqld-auth]
enabled  = true
filter   = mysqld-auth
port     = 3306
logpath  = /var/log/mysql/error.log
EOF
fi

# 4. Проверка синтаксиса
echo "[INFO] Проверяю конфигурацию..."
fail2ban-client -d >/dev/null

# 5. Перезапуск
echo "[INFO] Перезапускаю fail2ban..."
systemctl enable --now fail2ban
systemctl restart fail2ban

echo "[INFO] Настройка mysqld-auth jail завершена!"

sleep 2
fail2ban-client status mysqld-auth
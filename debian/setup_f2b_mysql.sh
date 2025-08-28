#!/bin/bash

# Скрипт установки и настройки Fail2Ban для MySQL
# Работает на Debian/Ubuntu

JAIL_CONF="/etc/fail2ban/jail.local"

echo "=== Установка Fail2Ban для защиты MySQL ==="

# Проверка, установлен ли fail2ban
if ! command -v fail2ban-server >/dev/null 2>&1; then
    echo "[INFO] Устанавливаю fail2ban..."
    apt update && apt install -y fail2ban
else
    echo "[INFO] Fail2Ban уже установлен."
fi

# Запрос IP-адресов для исключений
read -p "Введите IP-адреса (через пробел), которые нужно внести в исключения: " IGNORE_IPS

# Создание/обновление jail.local
echo "[INFO] Настраиваю jail.local..."

cat > "$JAIL_CONF" <<EOF
[DEFAULT]
# IP-адреса, которые никогда не будут блокироваться
ignoreip = 127.0.0.1/8 ::1 $IGNORE_IPS

# Общие параметры
bantime  = 3600
findtime = 600
maxretry = 5
backend = systemd

[mysqld-auth]
enabled  = true
port     = 3306
filter   = mysqld-auth
logpath  = /var/log/mysql/error.log
maxretry = 5
EOF

# Проверим наличие фильтра mysqld-auth
FILTER_FILE="/etc/fail2ban/filter.d/mysqld-auth.conf"
if [ ! -f "$FILTER_FILE" ]; then
    echo "[INFO] Создаю фильтр mysqld-auth..."
    cat > "$FILTER_FILE" <<'EOF'
[Definition]
failregex = Access denied for user .* from <HOST>
ignoreregex =
EOF
fi

# Перезапуск Fail2Ban
echo "[INFO] Перезапускаю fail2ban..."
systemctl enable fail2ban
systemctl restart fail2ban

echo "=== Установка и настройка завершена ==="
fail2ban-client status mysqld-auth

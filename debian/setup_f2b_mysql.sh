#!/bin/bash
set -e

IGNORE_IPS="127.0.0.1/8 ::1 89.218.6.32/29 77.37.97.27/32 194.32.141.205/32"

# Установка fail2ban если его нет
if ! command -v fail2ban-server &>/dev/null; then
    echo "[INFO] Fail2Ban not found, installing..."
    apt update && apt install -y fail2ban
fi

JAIL_LOCAL="/etc/fail2ban/jail.local"

# Создаём или обновляем jail.local
if [ ! -f "$JAIL_LOCAL" ]; then
    cat > "$JAIL_LOCAL" <<EOF
[DEFAULT]
ignoreip = $IGNORE_IPS
bantime  = 10m
findtime = 10m
maxretry = 5

[mysqld-auth]
enabled = true
logpath = /var/log/mysql/error.log
backend = auto
EOF
else
    # Обновляем DEFAULT
    sed -i "/^\[DEFAULT\]/,/^\[/ s|^ignoreip.*|ignoreip = $IGNORE_IPS|" "$JAIL_LOCAL" || true
    sed -i "/^\[DEFAULT\]/,/^\[/ s|^bantime.*|bantime  = 10m|" "$JAIL_LOCAL" || true
    sed -i "/^\[DEFAULT\]/,/^\[/ s|^findtime.*|findtime = 10m|" "$JAIL_LOCAL" || true
    sed -i "/^\[DEFAULT\]/,/^\[/ s|^maxretry.*|maxretry = 5|" "$JAIL_LOCAL" || true

    # Добавляем или правим jail mysqld-auth
    if ! grep -q "^\[mysqld-auth\]" "$JAIL_LOCAL"; then
        cat >> "$JAIL_LOCAL" <<EOF

[mysqld-auth]
enabled = true
logpath = /var/log/mysql/error.log
backend = auto
EOF
    else
        sed -i "/^\[mysqld-auth\]/,/^\[/ s|^enabled.*|enabled = true|" "$JAIL_LOCAL" || true
        sed -i "/^\[mysqld-auth\]/,/^\[/ s|^logpath.*|logpath = /var/log/mysql/error.log|" "$JAIL_LOCAL" || true
        sed -i "/^\[mysqld-auth\]/,/^\[/ s|^backend.*|backend = auto|" "$JAIL_LOCAL" || true
    fi
fi

echo "[INFO] Checking config..."
fail2ban-server -t

systemctl enable --now fail2ban
systemctl restart fail2ban

echo "[OK] Fail2Ban configured for mysqld-auth"
sleep 2
fail2ban-client status mysqld-auth
#!/bin/bash
set -e

# URL пакета
MYSQL_DEB_URL="https://repo.mysql.com//mysql-apt-config_0.8.34-1_all.deb"
DEB_FILE="mysql-apt-config_0.8.34-1_all.deb"

# Проверка доступности пакета
echo "[*] Проверка доступности $MYSQL_DEB_URL ..."
if curl -s --head --fail "$MYSQL_DEB_URL" > /dev/null; then
    echo "[+] Файл доступен."
else
    echo "[-] Файл недоступен. Проверьте URL."
    exit 1
fi

# Скачивание пакета если его нет локально
if [ ! -f "$DEB_FILE" ]; then
    echo "[*] Скачиваю $DEB_FILE ..."
    curl -O "$MYSQL_DEB_URL"
else
    echo "[*] Файл $DEB_FILE уже существует, пропускаю скачивание."
fi

# Установка зависимостей
echo "[*] Устанавливаю зависимости ..."
sudo apt-get update
sudo apt-get install -y lsb-release gnupg wget curl

# Установка mysql-apt-config
echo "[*] Устанавливаю mysql-apt-config ..."
sudo dpkg -i "$DEB_FILE"

# Обновление списка пакетов
echo "[*] Обновление apt ..."
sudo apt-get update

# Установка MySQL 8.0
echo "[*] Установка MySQL 8.0 ..."
sudo apt-get install -y mysql-server

# Проверка статуса
echo "[*] Проверка статуса MySQL ..."
systemctl status mysql --no-pager

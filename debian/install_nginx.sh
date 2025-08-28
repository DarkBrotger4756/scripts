#!/bin/bash
set -e

echo "=== Устанавливаем зависимости ==="
sudo apt update
sudo apt install -y curl gnupg2 ca-certificates lsb-release debian-archive-keyring

echo "=== Импортируем ключ nginx ==="
curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

echo "=== Проверяем отпечаток ключа ==="
gpg --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg \
    | grep "573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62" || {
        echo "❌ Ошибка: ключ не совпадает!"
        exit 1
    }

echo "=== Добавляем репозиторий Nginx (stable) ==="
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/debian $(lsb_release -cs) nginx" \
    | sudo tee /etc/apt/sources.list.d/nginx.list

# Если хочешь mainline вместо stable, раскомментируй:
# echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
# http://nginx.org/packages/mainline/debian $(lsb_release -cs) nginx" \
#     | sudo tee /etc/apt/sources.list.d/nginx.list

echo "=== Настраиваем приоритет пакетов nginx.org ==="
echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" \
    | sudo tee /etc/apt/preferences.d/99nginx

echo "=== Устанавливаем Nginx ==="
sudo apt update
sudo apt install -y nginx

echo "✅ Nginx установлен успешно!"
nginx -v

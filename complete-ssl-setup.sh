#!/bin/bash

echo "🔧 Завершаем установку SSL сертификатов..."

# Проверка наличия сертификатов
echo "1. Проверяем сертификаты..."
if [ -f "/etc/letsencrypt/live/soulsynergy.ru/fullchain.pem" ]; then
    echo "✅ Сертификаты найдены"
    ls -la /etc/letsencrypt/live/soulsynergy.ru/
else
    echo "❌ Сертификаты не найдены"
    exit 1
fi

# Установка сертификатов в nginx
echo "2. Устанавливаем сертификаты в nginx..."
certbot install --cert-name soulsynergy.ru

if [ $? -eq 0 ]; then
    echo "✅ Сертификаты установлены успешно"
else
    echo "❌ Не удалось установить сертификаты автоматически"
    echo "💡 Попробуем настроить вручную..."

    # Ручная настройка nginx
    echo "3. Настраиваем nginx вручную..."

    # Создание новой конфигурации
    sudo tee /etc/nginx/sites-available/ruplatform << 'EOF'
# HTTP сервер - перенаправление на HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name soulsynergy.ru www.soulsynergy.ru;

    # Обработка запросов Let's Encrypt для обновления сертификатов
    location ^~ /.well-known/acme-challenge/ {
        alias /var/www/html/.well-known/acme-challenge/;
        try_files $uri =404;
    }

    # Перенаправление на HTTPS
    return 301 https://$server_name$request_uri;
}

# HTTPS сервер с SSL сертификатами
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name soulsynergy.ru www.soulsynergy.ru;

    # SSL сертификаты от Let's Encrypt
    ssl_certificate /etc/letsencrypt/live/soulsynergy.ru/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/soulsynergy.ru/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;

    # Максимальный размер загружаемых файлов
    client_max_body_size 10M;

    # Логи
    access_log /var/log/nginx/ruplatform_access.log;
    error_log /var/log/nginx/ruplatform_error.log;

    # Статические файлы React приложения
    location / {
        root /home/node/ruplatform/client/dist;
        try_files $uri $uri/ /index.html;

        # Заголовки безопасности
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header Referrer-Policy "no-referrer-when-downgrade" always;
        add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

        # Кэш для статических ресурсов
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            access_log off;
        }
    }

    # API маршруты
    location /api/ {
        proxy_pass http://localhost:3000/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;

        # Таймауты
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }

    # Socket.IO для чатов
    location /socket.io/ {
        proxy_pass http://localhost:3000/socket.io/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Защита от доступа к системным файлам
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    location ~ \.(env|log)$ {
        deny all;
        access_log off;
        log_not_found off;
    }
}

# Перенаправление с www на без www (HTTP)
server {
    listen 80;
    listen [::]:80;
    server_name www.soulsynergy.ru;

    # Обработка запросов Let's Encrypt
    location ^~ /.well-known/acme-challenge/ {
        alias /var/www/html/.well-known/acme-challenge/;
        try_files $uri =404;
    }

    # Перенаправление на основной домен
    return 301 http://soulsynergy.ru$request_uri;
}
EOF

    # Включаем новую конфигурацию
    sudo ln -sf /etc/nginx/sites-available/ruplatform /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
fi

# Тестирование конфигурации
echo "4. Тестируем конфигурацию nginx..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Конфигурация nginx корректна"
    sudo systemctl reload nginx

    # Проверка работы HTTPS
    echo "5. Проверяем работу HTTPS..."
    sleep 3

    if curl -I https://soulsynergy.ru 2>/dev/null | grep -q "200\|301"; then
        echo "✅ HTTPS работает корректно!"
        echo "🌐 Сайт доступен по адресу: https://soulsynergy.ru"
    else
        echo "⚠️ HTTPS может не работать сразу, подождите 1-2 минуты"
        echo "💡 Проверьте: curl -I https://soulsynergy.ru"
    fi

    # Настройка автоматического обновления
    echo "6. Настраиваем автоматическое обновление сертификатов..."
    sudo systemctl enable certbot.timer 2>/dev/null || echo "Timer уже включен"

    echo "7. Тестируем обновление сертификатов..."
    sudo certbot renew --dry-run

    if [ $? -eq 0 ]; then
        echo "✅ Автоматическое обновление настроено"
    else
        echo "⚠️ Проверьте настройку автоматического обновления"
    fi
else
    echo "❌ Ошибка в конфигурации nginx"
    echo "💡 Проверьте логи: sudo tail -f /var/log/nginx/error.log"
fi

echo "🔧 Настройка SSL завершена!"

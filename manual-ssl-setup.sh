#!/bin/bash

echo "🔧 Альтернативная настройка SSL без certbot..."

# Функция для создания самоподписанного сертификата
create_self_signed_cert() {
    echo "📝 Создаем самоподписанный SSL сертификат..."

    # Создание приватного ключа
    sudo openssl genrsa -out /etc/ssl/private/soulsynergy.ru.key 2048

    # Создание запроса на подпись сертификата
    sudo openssl req -new -key /etc/ssl/private/soulsynergy.ru.key \
        -out /etc/ssl/certs/soulsynergy.ru.csr \
        -subj "/C=RU/ST=Moscow/L=Moscow/O=SoulSynergy/CN=soulsynergy.ru"

    # Создание самоподписанного сертификата (на 365 дней)
    sudo openssl x509 -req -days 365 -in /etc/ssl/certs/soulsynergy.ru.csr \
        -signkey /etc/ssl/private/soulsynergy.ru.key \
        -out /etc/ssl/certs/soulsynergy.ru.crt

    # Установка правильных прав доступа
    sudo chmod 600 /etc/ssl/private/soulsynergy.ru.key
    sudo chmod 644 /etc/ssl/certs/soulsynergy.ru.crt

    echo "✅ Самоподписанный сертификат создан"
}

# Функция для использования standalone режима certbot
try_standalone_certbot() {
    echo "🌐 Пробуем получить сертификат через standalone режим..."

    # Остановка nginx
    sudo systemctl stop nginx

    # Получение сертификата в standalone режиме
    sudo certbot certonly --standalone --agree-tos --no-eff-email \
        -d soulsynergy.ru -d www.soulsynergy.ru

    if [ $? -eq 0 ]; then
        echo "✅ Сертификат получен в standalone режиме"

        # Создание символических ссылок для nginx
        sudo ln -sf /etc/letsencrypt/live/soulsynergy.ru/cert.pem /etc/ssl/certs/soulsynergy.ru.crt
        sudo ln -sf /etc/letsencrypt/live/soulsynergy.ru/privkey.pem /etc/ssl/private/soulsynergy.ru.key

        # Запуск nginx
        sudo systemctl start nginx
        return 0
    else
        echo "❌ Standalone режим не сработал"
        sudo systemctl start nginx
        return 1
    fi
}

# Функция для настройки nginx с полученными сертификатами
configure_nginx_ssl() {
    echo "⚙️ Настраиваем nginx для работы с SSL..."

    # Создание конфигурации с полученными сертификатами
    sudo tee /etc/nginx/sites-available/ruplatform-ssl << 'EOF'
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

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name soulsynergy.ru www.soulsynergy.ru;

    ssl_certificate /etc/ssl/certs/soulsynergy.ru.crt;
    ssl_certificate_key /etc/ssl/private/soulsynergy.ru.key;
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

        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header Referrer-Policy "no-referrer-when-downgrade" always;
        add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

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
EOF

    # Включаем новый конфиг
    sudo ln -sf /etc/nginx/sites-available/ruplatform-ssl /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/ruplatform
    sudo rm -f /etc/nginx/sites-enabled/default

    # Тестируем конфигурацию
    sudo nginx -t && sudo systemctl reload nginx
}

# Основная логика
echo "1. Создаем самоподписанный сертификат..."
create_self_signed_cert

echo "2. Пробуем получить настоящий сертификат через standalone..."
if try_standalone_certbot; then
    echo "✅ Получен настоящий сертификат от Let's Encrypt"
else
    echo "⚠️ Используем самоподписанный сертификат"
    echo "   (пользователи увидят предупреждение о безопасности)"
fi

echo "3. Настраиваем nginx..."
configure_nginx_ssl

echo "4. Проверяем результат..."
if sudo nginx -t; then
    echo "✅ nginx настроен корректно"
    sudo systemctl reload nginx
    echo "🌐 Сайт доступен по HTTPS (с предупреждением или без, в зависимости от типа сертификата)"
    echo "🔄 Сертификаты можно будет обновить позже через: sudo certbot --nginx -d soulsynergy.ru -d www.soulsynergy.ru"
else
    echo "❌ Ошибка в конфигурации nginx"
fi

echo "🔧 Настройка завершена!"

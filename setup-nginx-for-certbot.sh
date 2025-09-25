#!/bin/bash

echo "🔧 Настраиваем nginx для автоматической работы с certbot..."

# Остановка nginx
echo "1. Останавливаем nginx..."
sudo systemctl stop nginx

# Бэкап текущей конфигурации
echo "2. Создаем бэкап текущей конфигурации..."
sudo cp /etc/nginx/sites-available/ruplatform /etc/nginx/sites-available/ruplatform.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Создание новой конфигурации для certbot
echo "3. Создаем новую конфигурацию nginx..."
sudo tee /etc/nginx/sites-available/ruplatform << 'EOF'
# HTTP сервер для получения SSL сертификатов
server {
    listen 80;
    listen [::]:80;
    server_name soulsynergy.ru www.soulsynergy.ru;

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

    # Перенаправление на основной домен
    return 301 http://soulsynergy.ru$request_uri;
}
EOF

# Включаем новую конфигурацию
echo "4. Включаем новую конфигурацию..."
sudo ln -sf /etc/nginx/sites-available/ruplatform /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Тестируем конфигурацию
echo "5. Тестируем конфигурацию nginx..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Конфигурация nginx корректна"
    sudo systemctl start nginx

    # Проверяем, что HTTP работает
    echo "6. Проверяем HTTP..."
    sleep 2
    if curl -s -I http://soulsynergy.ru | head -1 | grep -q "200"; then
        echo "✅ HTTP работает корректно"
    else
        echo "⚠️ HTTP может не работать сразу, подождите 1-2 минуты"
    fi

    # Теперь устанавливаем сертификаты с помощью certbot
    echo "7. Устанавливаем SSL сертификаты..."
    sudo certbot --nginx -d soulsynergy.ru -d www.soulsynergy.ru --agree-tos --no-eff-email --redirect

    if [ $? -eq 0 ]; then
        echo "✅ SSL сертификаты установлены успешно!"
        echo "🌐 Сайт доступен по HTTPS: https://soulsynergy.ru"

        # Проверяем HTTPS
        echo "8. Проверяем HTTPS..."
        sleep 3
        if curl -s -I https://soulsynergy.ru | head -1 | grep -q "200"; then
            echo "✅ HTTPS работает корректно!"
        else
            echo "⚠️ HTTPS может не работать сразу, подождите 1-2 минуты"
        fi

        # Проверяем перенаправление HTTP->HTTPS
        echo "9. Проверяем перенаправление HTTP->HTTPS..."
        if curl -s -I http://soulsynergy.ru | head -1 | grep -q "301"; then
            echo "✅ HTTP->HTTPS перенаправление работает"
        else
            echo "⚠️ Проверьте перенаправление: curl -I http://soulsynergy.ru"
        fi

        # Настройка автоматического обновления
        echo "10. Настраиваем автоматическое обновление сертификатов..."
        sudo systemctl enable certbot.timer 2>/dev/null || echo "Timer уже включен"

        echo "11. Тестируем обновление сертификатов..."
        sudo certbot renew --dry-run

        if [ $? -eq 0 ]; then
            echo "✅ Автоматическое обновление настроено"
        else
            echo "⚠️ Проверьте настройку автоматического обновления"
        fi

    else
        echo "❌ Не удалось установить сертификаты"
        echo "💡 Попробуйте: sudo certbot --nginx -d soulsynergy.ru -d www.soulsynergy.ru --agree-tos --no-eff-email"
    fi

else
    echo "❌ Ошибка в конфигурации nginx"
    echo "💡 Проверьте синтаксис: sudo nginx -t"
    echo "💡 Логи ошибок: sudo tail -f /var/log/nginx/error.log"
    exit 1
fi

echo "🔧 Настройка завершена!"

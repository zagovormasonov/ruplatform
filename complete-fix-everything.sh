#!/bin/bash

echo "🔥 ПОЛНОЕ ВОССТАНОВЛЕНИЕ СИСТЕМЫ ПОСЛЕ SSL..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для полной диагностики
diagnose_everything() {
    echo -e "${BLUE}📊 ПОЛНАЯ ДИАГНОСТИКА ВСЕХ ПРОБЛЕМ...${NC}"

    echo -e "${YELLOW}1. Проверяем SSL сертификаты...${NC}"
    if [ -f "/etc/letsencrypt/live/soulsynergy.ru/fullchain.pem" ]; then
        echo -e "   ${GREEN}✅ SSL сертификаты установлены${NC}"
    else
        echo -e "   ${RED}❌ SSL сертификаты НЕ установлены${NC}"
    fi

    echo -e "${YELLOW}2. Проверяем nginx конфигурацию...${NC}"
    if sudo nginx -t 2>/dev/null; then
        echo -e "   ${GREEN}✅ nginx конфигурация корректна${NC}"
    else
        echo -e "   ${RED}❌ nginx конфигурация НЕКОРРЕКТНА${NC}"
        sudo nginx -t
    fi

    echo -e "${YELLOW}3. Проверяем backend файлы...${NC}"
    if [ -f "/home/node/ruplatform/server/dist/index.js" ]; then
        echo -e "   ${GREEN}✅ Backend файл найден${NC}"
    else
        echo -e "   ${RED}❌ Backend файл НЕ найден${NC}"
    fi

    if [ -f "/home/node/ruplatform/server/ecosystem.config.js" ]; then
        echo -e "   ${GREEN}✅ Ecosystem config найден${NC}"
    else
        echo -e "   ${YELLOW}⚠️ Ecosystem config НЕ найден${NC}"
    fi

    echo -e "${YELLOW}4. Проверяем frontend файлы...${NC}"
    if [ -f "/home/node/ruplatform/client/.env.production" ]; then
        echo -e "   📄 .env.production:"
        cat /home/node/ruplatform/client/.env.production
    else
        echo -e "   ${RED}❌ .env.production НЕ найден${NC}"
    fi

    if [ -d "/home/node/ruplatform/client/dist" ]; then
        echo -e "   ${GREEN}✅ Frontend dist директория существует${NC}"
    else
        echo -e "   ${RED}❌ Frontend dist НЕ существует${NC}"
    fi

    echo -e "${YELLOW}5. Проверяем процессы...${NC}"
    local pm2_status=$(pm2 status 2>/dev/null | grep -c "online" || echo "0")
    echo -e "   📊 PM2 онлайн процессов: $pm2_status"

    local port_3000=$(netstat -tlnp 2>/dev/null | grep -c ":3000 " || echo "0")
    echo -e "   📊 Порт 3000 открыт: $port_3000"

    local node_processes=$(ps aux | grep -E "node.*ruplatform|node.*3000" | grep -v grep | wc -l)
    echo -e "   📊 Node.js процессов: $node_processes"
}

# Функция для полной переустановки backend
reinstall_backend() {
    echo -e "${BLUE}🔄 ПЕРЕУСТАНАВЛИВАЕМ BACKEND...${NC}"

    # Останавливаем все
    echo -e "   🔄 Останавливаем все процессы..."
    pm2 stop all 2>/dev/null || true
    pm2 delete all 2>/dev/null || true
    pkill -f "node.*ruplatform" 2>/dev/null || true
    pkill -f "node.*3000" 2>/dev/null || true
    sleep 3

    # Убеждаемся что все остановлено
    if netstat -tlnp 2>/dev/null | grep -q ":3000 "; then
        echo -e "   ${RED}❌ Порт 3000 все еще занят, убиваем принудительно${NC}"
        fuser -k 3000/tcp 2>/dev/null || true
        sleep 2
    fi

    # Переустанавливаем зависимости
    echo -e "   📦 Переустанавливаем зависимости backend..."
    cd /home/node/ruplatform/server
    npm install --production

    # Пересобираем backend
    echo -e "   🔨 Пересобираем backend..."
    npm run build

    if [ ! -f "dist/index.js" ]; then
        echo -e "   ${RED}❌ Сборка backend НЕ УДАЛАСЬ${NC}"
        return 1
    fi

    echo -e "   ${GREEN}✅ Backend пересобран${NC}"
    return 0
}

# Функция для полной переустановки frontend
reinstall_frontend() {
    echo -e "${BLUE}🔄 ПЕРЕУСТАНАВЛИВАЕМ FRONTEND...${NC}"

    # Устанавливаем правильную переменную окружения
    echo -e "   🔧 Устанавливаем VITE_API_URL..."
    echo "VITE_API_URL=https://soulsynergy.ru/api" > /home/node/ruplatform/client/.env.production

    # Переустанавливаем зависимости
    echo -e "   📦 Переустанавливаем зависимости frontend..."
    cd /home/node/ruplatform/client
    npm install

    # Пересобираем frontend
    echo -e "   🔨 Пересобираем frontend..."
    npm run build

    if [ ! -d "dist" ]; then
        echo -e "   ${RED}❌ Сборка frontend НЕ УДАЛАСЬ${NC}"
        return 1
    fi

    echo -e "   ${GREEN}✅ Frontend пересобран${NC}"
    return 0
}

# Функция для правильной настройки nginx
setup_nginx_properly() {
    echo -e "${BLUE}🔧 НАСТРАИВАЕМ NGINX ПРАВИЛЬНО...${NC}"

    # Создаем правильную конфигурацию
    sudo tee /etc/nginx/sites-available/ruplatform << 'EOF'
# HTTP сервер - для получения SSL сертификатов
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

# HTTPS сервер с SSL сертификатами
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name soulsynergy.ru www.soulsynergy.ru;

    # SSL сертификаты
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

    # Перенаправление на основной домен
    return 301 http://soulsynergy.ru$request_uri;
}

# Перенаправление с www на без www (HTTPS)
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name www.soulsynergy.ru;

    ssl_certificate /etc/letsencrypt/live/soulsynergy.ru/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/soulsynergy.ru/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;

    # Перенаправление на основной домен
    return 301 https://soulsynergy.ru$request_uri;
}
EOF

    # Включаем конфигурацию
    sudo ln -sf /etc/nginx/sites-available/ruplatform /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default

    # Тестируем конфигурацию
    if sudo nginx -t; then
        echo -e "   ${GREEN}✅ nginx конфигурация корректна${NC}"
        sudo systemctl reload nginx
        return 0
    else
        echo -e "   ${RED}❌ nginx конфигурация НЕКОРРЕКТНА${NC}"
        return 1
    fi
}

# Функция для запуска backend через PM2
start_backend_with_pm2() {
    echo -e "${BLUE}🚀 ЗАПУСКАЕМ BACKEND ЧЕРЕЗ PM2...${NC}"

    # Проверяем что файл существует
    if [ ! -f "/home/node/ruplatform/server/dist/index.js" ]; then
        echo -e "   ${RED}❌ Backend файл не найден${NC}"
        return 1
    fi

    # Запускаем через PM2
    cd /home/node/ruplatform/server
    pm2 start dist/index.js --name "ruplatform-backend"

    # Ждем запуска
    sleep 5

    # Проверяем что запустилось
    if pm2 status 2>/dev/null | grep -q "online"; then
        echo -e "   ${GREEN}✅ Backend запущен через PM2${NC}"
        return 0
    else
        echo -e "   ${RED}❌ Backend не запустился${NC}"
        pm2 logs --lines 10
        return 1
    fi
}

# Функция для финального тестирования
final_test_everything() {
    echo -e "${YELLOW}🧪 ФИНАЛЬНОЕ ТЕСТИРОВАНИЕ...${NC}"

    # Тестируем backend напрямую
    echo -e "   🔧 Тестируем backend (localhost:3000):"
    local backend_response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:3000/api/articles" 2>/dev/null)
    if [ "$backend_response" = "200" ]; then
        echo -e "   ${GREEN}✅ Backend отвечает: $backend_response${NC}"
    else
        echo -e "   ${RED}❌ Backend не отвечает: $backend_response${NC}"
    fi

    # Тестируем через nginx
    echo -e "   🌐 Тестируем через nginx (HTTPS):"
    local nginx_response=$(curl -s -w "%{http_code}" -o /dev/null "https://soulsynergy.ru/api/articles" 2>/dev/null)
    if [ "$nginx_response" = "200" ]; then
        echo -e "   ${GREEN}✅ nginx проксирует: $nginx_response${NC}"
    else
        echo -e "   ${RED}❌ nginx не проксирует: $nginx_response${NC}"
    fi

    # Тестируем frontend
    echo -e "   🌐 Тестируем frontend (HTTPS):"
    local frontend_response=$(curl -s -w "%{http_code}" -o /dev/null "https://soulsynergy.ru/" 2>/dev/null)
    if [ "$frontend_response" = "200" ]; then
        echo -e "   ${GREEN}✅ Frontend доступен: $frontend_response${NC}"
    else
        echo -e "   ${RED}❌ Frontend недоступен: $frontend_response${NC}"
    fi

    # Тестируем несколько API эндпоинтов
    echo -e "   🔍 Тестируем API эндпоинты:"
    local endpoints=("/api/articles" "/api/experts/search" "/api/users/cities")
    for endpoint in "${endpoints[@]}"; do
        local response=$(curl -s -w "%{http_code}" -o /dev/null "https://soulsynergy.ru$endpoint" 2>/dev/null)
        if [ "$response" = "200" ]; then
            echo -e "   ${GREEN}✅ $endpoint: $response${NC}"
        else
            echo -e "   ${RED}❌ $endpoint: $response${NC}"
        fi
    done
}

# Основная логика
echo -e "${GREEN}🚀 НАЧИНАЕМ ПОЛНОЕ ВОССТАНОВЛЕНИЕ СИСТЕМЫ${NC}"
echo ""

# Диагностируем все
diagnose_everything

echo ""
echo -e "${BLUE}🔄 НАЧИНАЕМ ИСПРАВЛЕНИЕ...${NC}"

# Переустанавливаем backend
if reinstall_backend; then
    echo ""
    echo -e "${BLUE}✅ BACKEND ПЕРЕУСТАНОВЛЕН${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ ПЕРЕУСТАНОВИТЬ BACKEND${NC}"
    exit 1
fi

# Переустанавливаем frontend
if reinstall_frontend; then
    echo ""
    echo -e "${BLUE}✅ FRONTEND ПЕРЕУСТАНОВЛЕН${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ ПЕРЕУСТАНОВИТЬ FRONTEND${NC}"
    exit 1
fi

# Настраиваем nginx
if setup_nginx_properly; then
    echo ""
    echo -e "${BLUE}✅ NGINX НАСТРОЕН${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ НАСТРОИТЬ NGINX${NC}"
    exit 1
fi

# Запускаем backend через PM2
if start_backend_with_pm2; then
    echo ""
    echo -e "${BLUE}✅ BACKEND ЗАПУЩЕН ЧЕРЕЗ PM2${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ ЗАПУСТИТЬ BACKEND${NC}"
    exit 1
fi

# Финальное тестирование
echo ""
final_test_everything

echo ""
echo -e "${GREEN}🎉 ПОЛНОЕ ВОССТАНОВЛЕНИЕ ЗАВЕРШЕНО!${NC}"
echo ""
echo -e "${YELLOW}🔄 Теперь выполните:${NC}"
echo "   1. Перезагрузите страницу в браузере: Ctrl+Shift+R"
echo ""
echo -e "${YELLOW}🧪 Проверьте:${NC}"
echo "   - Нет синтаксических ошибок JavaScript"
echo "   - API запросы возвращают 200 OK"
echo "   - Авторизация работает"
echo "   - Все функции работают"
echo "   - Нет ошибок Mixed Content или 502"

echo ""
echo -e "${GREEN}🔥 ВСЕ ДОЛЖНО РАБОТАТЬ ТЕПЕРЬ!${NC}"

#!/bin/bash

echo "🔧 ИСПРАВЛЕНИЕ КОНФЛИКТА ПОРТОВ (3001 vs 3000)..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для диагностики проблемы с портами
diagnose_port_conflict() {
    echo -e "${BLUE}📊 ДИАГНОСТИКА ПРОБЛЕМЫ С ПОРТАМИ...${NC}"

    echo -e "${YELLOW}1. Проверяем какие порты заняты...${NC}"
    echo -e "   🔍 Порт 3000:"
    if netstat -tlnp 2>/dev/null | grep -q ":3000 "; then
        echo -e "      ${RED}❌ ЗАНЯТ${NC}"
        netstat -tlnp | grep ":3000"
    else
        echo -e "      ${GREEN}✅ Свободен${NC}"
    fi

    echo -e "   🔍 Порт 3001:"
    if netstat -tlnp 2>/dev/null | grep -q ":3001 "; then
        echo -e "      ${RED}❌ ЗАНЯТ${NC}"
        netstat -tlnp | grep ":3001"
    else
        echo -e "      ${GREEN}✅ Свободен${NC}"
    fi

    echo -e "${YELLOW}2. Проверяем Node.js процессы...${NC}"
    local node_processes=$(ps aux | grep -E "node.*300[01]" | grep -v grep | wc -l)
    if [ "$node_processes" -gt 0 ]; then
        echo -e "   📊 Найдено $node_processes Node.js процессов:"
        ps aux | grep -E "node.*300[01]" | grep -v grep
    else
        echo -e "   ${GREEN}✅ Нет Node.js процессов на портах 3000/3001${NC}"
    fi

    echo -e "${YELLOW}3. Проверяем конфигурацию backend...${NC}"
    if [ -f "/home/node/ruplatform/server/.env" ]; then
        echo -e "   📄 Конфигурация backend (.env):"
        grep -E "PORT|port" /home/node/ruplatform/server/.env 2>/dev/null || echo -e "      ${YELLOW}⚠️ PORT не найден в .env${NC}"
    fi

    if [ -f "/home/node/ruplatform/server/dist/index.js" ]; then
        echo -e "   📄 Backend файл найден"
    else
        echo -e "   ${RED}❌ Backend файл НЕ найден${NC}"
    fi

    echo -e "${YELLOW}4. Проверяем nginx конфигурацию...${NC}"
    echo -e "   📄 nginx проксирует на порт:"
    sudo grep -A 2 "proxy_pass" /etc/nginx/sites-available/ruplatform 2>/dev/null | grep -E "300[01]" || echo -e "      ${YELLOW}⚠️ nginx конфигурация не найдена${NC}"
}

# Функция для исправления конфигурации
fix_port_configuration() {
    echo -e "${BLUE}🔧 ИСПРАВЛЯЕМ КОНФИГУРАЦИЮ ПОРТОВ...${NC}"

    # Определяем на какой порт должен работать backend
    local backend_port=3000  # nginx ожидает порт 3000

    echo -e "   🔧 Backend будет работать на порту $backend_port"

    # Останавливаем все существующие процессы
    echo -e "   🔄 Останавливаем все Node.js процессы..."
    pm2 stop all 2>/dev/null || true
    pm2 delete all 2>/dev/null || true
    pkill -f "node.*ruplatform" 2>/dev/null || true
    pkill -f "node.*300[01]" 2>/dev/null || true
    sleep 3

    # Убеждаемся что порты свободны
    if netstat -tlnp 2>/dev/null | grep -q ":$backend_port "; then
        echo -e "   ${RED}❌ Порт $backend_port все еще занят${NC}"
        fuser -k "$backend_port"/tcp 2>/dev/null || true
        sleep 2
    fi

    # Проверяем backend файл
    if [ ! -f "/home/node/ruplatform/server/dist/index.js" ]; then
        echo -e "   ${RED}❌ Backend файл не найден, пересобираем...${NC}"
        cd /home/node/ruplatform/server
        npm install --production
        npm run build
    fi

    # Запускаем backend на правильном порту
    echo -e "   🚀 Запускаем backend на порту $backend_port..."
    cd /home/node/ruplatform/server
    pm2 start dist/index.js --name "ruplatform-backend" -- --port $backend_port

    # Ждем запуска
    sleep 5

    # Проверяем что запустилось
    if pm2 status 2>/dev/null | grep -q "online"; then
        echo -e "   ${GREEN}✅ Backend запущен через PM2${NC}"
        pm2 status | grep ruplatform
    else
        echo -e "   ${RED}❌ Backend не запустился${NC}"
        pm2 logs --lines 10
        return 1
    fi

    return 0
}

# Функция для исправления nginx конфигурации
fix_nginx_port_config() {
    echo -e "${BLUE}🔧 ИСПРАВЛЯЕМ NGINX КОНФИГУРАЦИЮ...${NC}"

    # Порт на который должен проксировать nginx
    local nginx_proxy_port=3000

    echo -e "   🔧 nginx будет проксировать на порт $nginx_proxy_port"

    # Создаем правильную конфигурацию nginx
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

    # API маршруты - проксируем на порт 3000
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

    # API маршруты - проксируем на порт 3000
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
        sudo nginx -t
        return 1
    fi
}

# Функция для тестирования соединения
test_port_connection() {
    echo -e "${YELLOW}🧪 ТЕСТИРУЕМ СОЕДИНЕНИЕ ПОРТОВ...${NC}"

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
echo -e "${GREEN}🚀 ИСПРАВЛЯЕМ КОНФЛИКТ ПОРТОВ 3001 vs 3000${NC}"
echo ""

# Диагностируем проблему
diagnose_port_conflict

echo ""
echo -e "${BLUE}🔧 НАЧИНАЕМ ИСПРАВЛЕНИЕ...${NC}"

# Исправляем конфигурацию
if fix_nginx_port_config; then
    echo ""
    echo -e "${BLUE}✅ NGINX НАСТРОЕН НА ПОРТ 3000${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ НАСТРОИТЬ NGINX${NC}"
    exit 1
fi

# Запускаем backend на правильном порту
if fix_port_configuration; then
    echo ""
    echo -e "${BLUE}✅ BACKEND ЗАПУЩЕН НА ПОРТУ 3000${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ ЗАПУСТИТЬ BACKEND${NC}"
    exit 1
fi

# Тестируем соединение
echo ""
test_port_connection

echo ""
echo -e "${GREEN}🎉 КОНФЛИКТ ПОРТОВ ИСПРАВЛЕН!${NC}"
echo ""
echo -e "${YELLOW}🔄 Теперь выполните:${NC}"
echo "   1. Перезагрузите страницу в браузере: Ctrl+Shift+R"
echo ""
echo -e "${YELLOW}🧪 Проверьте в DevTools > Network:${NC}"
echo "   - API запросы должны возвращать 200 OK"
echo "   - Нет ошибок 502 Bad Gateway"
echo "   - Нет ошибок EADDRINUSE"
echo "   - Авторизация работает"

echo ""
echo -e "${GREEN}🔧 ИСПРАВЛЕНИЕ ЗАВЕРШЕНО${NC}"

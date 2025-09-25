#!/bin/bash

echo "🚨 ЭКСТРЕННОЕ ИСПРАВЛЕНИЕ ПОРТА 3001 -> 3000"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для принудительной остановки ВСЕГО
force_stop_all() {
    echo -e "${RED}🔥 ПРИНУДИТЕЛЬНО ОСТАНАВЛИВАЕМ ВСЕ...${NC}"

    # Останавливаем PM2
    echo -e "   🔄 Останавливаем PM2..."
    pm2 stop all 2>/dev/null || true
    pm2 delete all 2>/dev/null || true
    pm2 kill 2>/dev/null || true

    # Убиваем все Node.js процессы
    echo -e "   💀 Убиваем все Node.js процессы..."
    pkill -9 node 2>/dev/null || true
    pkill -9 -f "ruplatform" 2>/dev/null || true
    pkill -9 -f "300[01]" 2>/dev/null || true
    pkill -9 -f "dist/index.js" 2>/dev/null || true

    # Ожидаем
    sleep 3

    # Проверяем что все остановлено
    local remaining_processes=$(ps aux | grep -E "node.*300[01]|node.*ruplatform" | grep -v grep | wc -l)
    if [ "$remaining_processes" -gt 0 ]; then
        echo -e "   ${YELLOW}⚠️  Все еще есть $remaining_processes процессов, убиваем жестко...${NC}"
        ps aux | grep -E "node.*300[01]|node.*ruplatform" | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null || true
        sleep 2
    fi

    echo -e "   ${GREEN}✅ Все процессы остановлены${NC}"
}

# Функция для освобождения портов
free_ports() {
    echo -e "${BLUE}🔓 ОСВОБОЖДАЕМ ПОРТЫ 3000 И 3001...${NC}"

    # Порт 3000
    if netstat -tlnp 2>/dev/null | grep -q ":3000 "; then
        echo -e "   🔓 Освобождаем порт 3000..."
        fuser -k 3000/tcp 2>/dev/null || true
        lsof -ti:3000 | xargs kill -9 2>/dev/null || true
    fi

    # Порт 3001
    if netstat -tlnp 2>/dev/null | grep -q ":3001 "; then
        echo -e "   🔓 Освобождаем порт 3001..."
        fuser -k 3001/tcp 2>/dev/null || true
        lsof -ti:3001 | xargs kill -9 2>/dev/null || true
    fi

    sleep 2

    # Проверяем что порты свободны
    local port_3000=$(netstat -tlnp 2>/dev/null | grep -c ":3000 " || echo "0")
    local port_3001=$(netstat -tlnp 2>/dev/null | grep -c ":3001 " || echo "0")

    echo -e "   📊 Порт 3000 свободен: $([ "$port_3000" -eq 0 ] && echo '✅' || echo '❌')"
    echo -e "   📊 Порт 3001 свободен: $([ "$port_3001" -eq 0 ] && echo '✅' || echo '❌')"
}

# Функция для исправления конфигурации backend
fix_backend_config() {
    echo -e "${BLUE}🔧 ИСПРАВЛЯЕМ КОНФИГУРАЦИЮ BACKEND...${NC}"

    cd /home/node/ruplatform/server

    # Убеждаемся что .env файл есть и содержит правильный порт
    if [ ! -f ".env" ]; then
        echo -e "   📄 Создаем .env файл..."
        echo "PORT=3000" > .env
    else
        echo -e "   📝 Обновляем .env файл..."
        sed -i 's/PORT=[0-9]*/PORT=3000/g' .env
    fi

    echo -e "   📄 Содержимое .env:"
    cat .env

    # Пересобираем backend
    echo -e "   🔨 Пересобираем backend..."
    npm install --production 2>/dev/null
    npm run build 2>/dev/null

    if [ -f "dist/index.js" ]; then
        echo -e "   ${GREEN}✅ Backend пересобран${NC}"
    else
        echo -e "   ${RED}❌ Сборка backend НЕ УДАЛАСЬ${NC}"
        return 1
    fi

    return 0
}

# Функция для исправления nginx конфигурации
fix_nginx_config() {
    echo -e "${BLUE}🔧 ИСПРАВЛЯЕМ NGINX КОНФИГУРАЦИЮ...${NC}"

    sudo tee /etc/nginx/sites-available/ruplatform << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name soulsynergy.ru www.soulsynergy.ru;

    client_max_body_size 10M;
    access_log /var/log/nginx/ruplatform_access.log;
    error_log /var/log/nginx/ruplatform_error.log;

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

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name soulsynergy.ru www.soulsynergy.ru;

    ssl_certificate /etc/letsencrypt/live/soulsynergy.ru/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/soulsynergy.ru/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;

    client_max_body_size 10M;
    access_log /var/log/nginx/ruplatform_access.log;
    error_log /var/log/nginx/ruplatform_error.log;

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

server {
    listen 80;
    listen [::]:80;
    server_name www.soulsynergy.ru;
    return 301 http://soulsynergy.ru$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name www.soulsynergy.ru;
    ssl_certificate /etc/letsencrypt/live/soulsynergy.ru/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/soulsynergy.ru/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    return 301 https://soulsynergy.ru$request_uri;
}
EOF

    # Включаем конфигурацию
    sudo ln -sf /etc/nginx/sites-available/ruplatform /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default

    # Тестируем и перезагружаем
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

# Функция для запуска backend на правильном порту
start_backend_correctly() {
    echo -e "${BLUE}🚀 ЗАПУСКАЕМ BACKEND НА ПОРТУ 3000...${NC}"

    cd /home/node/ruplatform/server

    # Запускаем с явным указанием порта 3000
    echo -e "   📡 Запускаем: pm2 start dist/index.js --name 'ruplatform-backend' -- --port 3000"

    pm2 start dist/index.js --name "ruplatform-backend" -- --port 3000

    # Ждем
    sleep 5

    # Проверяем статус
    pm2 status

    # Проверяем что порт 3000 слушается
    local port_3000=$(netstat -tlnp 2>/dev/null | grep -c ":3000 " || echo "0")
    if [ "$port_3000" -gt 0 ]; then
        echo -e "   ${GREEN}✅ Порт 3000 открыт${NC}"
    else
        echo -e "   ${RED}❌ Порт 3000 НЕ открыт${NC}"
        return 1
    fi

    # Проверяем логи
    echo -e "   📄 Последние логи PM2:"
    pm2 logs --lines 5

    return 0
}

# Функция для финального тестирования
test_everything() {
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

    echo -e "   📊 Порт 3000: $(netstat -tlnp 2>/dev/null | grep -c ":3000 " || echo "0") процессов"
    echo -e "   📊 PM2: $(pm2 status 2>/dev/null | grep -c "online" || echo "0") онлайн процессов"
}

# ОСНОВНАЯ ЛОГИКА
echo -e "${GREEN}🚀 НАЧИНАЕМ ЭКСТРЕННОЕ ИСПРАВЛЕНИЕ ПОРТОВ${NC}"
echo ""

# Шаг 1: Останавливаем все
force_stop_all
echo ""

# Шаг 2: Освобождаем порты
free_ports
echo ""

# Шаг 3: Исправляем конфигурацию backend
if fix_backend_config; then
    echo ""
    echo -e "${BLUE}✅ BACKEND КОНФИГУРАЦИЯ ИСПРАВЛЕНА${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ ИСПРАВИТЬ BACKEND КОНФИГУРАЦИЮ${NC}"
    exit 1
fi

# Шаг 4: Исправляем nginx
if fix_nginx_config; then
    echo ""
    echo -e "${BLUE}✅ NGINX КОНФИГУРАЦИЯ ИСПРАВЛЕНА${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ ИСПРАВИТЬ NGINX КОНФИГУРАЦИЮ${NC}"
    exit 1
fi

# Шаг 5: Запускаем backend на правильном порту
if start_backend_correctly; then
    echo ""
    echo -e "${BLUE}✅ BACKEND ЗАПУЩЕН НА ПОРТУ 3000${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ ЗАПУСТИТЬ BACKEND${NC}"
    exit 1
fi

# Шаг 6: Тестируем
echo ""
test_everything

echo ""
echo -e "${GREEN}🎉 ИСПРАВЛЕНИЕ ЗАВЕРШЕНО!${NC}"
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
echo -e "${GREEN}🔥 ДОЛЖНО РАБОТАТЬ ТЕПЕРЬ!${NC}"

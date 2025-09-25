#!/bin/bash

echo "🔧 ИСПРАВЛЕНИЕ ОШИБКИ 502 BAD GATEWAY..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для диагностики backend сервера
diagnose_backend() {
    echo -e "${YELLOW}1. Диагностируем backend сервер...${NC}"

    # Проверяем статус PM2
    echo -e "   🔍 Статус PM2 процессов:"
    pm2 status 2>/dev/null || echo -e "   ${RED}❌ PM2 не запущен${NC}"
    pm2 jlist 2>/dev/null | jq -r '.[] | "\(.name): \(.pm2_env.status)"' 2>/dev/null || echo -e "   ${YELLOW}⚠️ PM2 не установлен или нет процессов${NC}"

    # Проверяем порт backend
    echo -e "   🔍 Проверяем порт 3000:"
    if netstat -tlnp 2>/dev/null | grep -q ":3000 "; then
        echo -e "   ${GREEN}✅ Порт 3000 открыт${NC}"
        netstat -tlnp | grep ":3000 "
    else
        echo -e "   ${RED}❌ Порт 3000 не открыт${NC}"
    fi

    # Проверяем процессы Node.js
    echo -e "   🔍 Процессы Node.js:"
    local node_processes=$(ps aux | grep -E "node.*3000|node.*server" | grep -v grep | wc -l)
    if [ "$node_processes" -gt 0 ]; then
        echo -e "   ${GREEN}✅ Найдено $node_processes Node.js процессов${NC}"
        ps aux | grep -E "node.*3000|node.*server" | grep -v grep
    else
        echo -e "   ${RED}❌ Node.js backend не запущен${NC}"
    fi

    # Проверяем логи PM2
    echo -e "   🔍 Последние логи PM2:"
    pm2 logs --lines 5 2>/dev/null || echo -e "   ${YELLOW}⚠️ Не могу получить логи PM2${NC}"
}

# Функция для проверки nginx конфигурации
check_nginx_config() {
    echo -e "${YELLOW}2. Проверяем конфигурацию nginx...${NC}"

    # Проверяем синтаксис
    echo -e "   🔍 Проверяем синтаксис nginx:"
    if sudo nginx -t 2>/dev/null; then
        echo -e "   ${GREEN}✅ Синтаксис nginx корректен${NC}"
    else
        echo -e "   ${RED}❌ Ошибка синтаксиса nginx${NC}"
        sudo nginx -t
        return 1
    fi

    # Проверяем что nginx слушает порты
    echo -e "   🔍 Проверяем слушающие порты:"
    sudo netstat -tlnp | grep -E "(80|443|3000)"

    # Проверяем статус nginx
    echo -e "   🔍 Статус nginx:"
    sudo systemctl status nginx --no-pager -l 2>/dev/null | head -5 || echo -e "   ${YELLOW}⚠️ Не могу получить статус nginx${NC}"
}

# Функция для исправления backend сервера
fix_backend_server() {
    echo -e "${BLUE}3. Исправляем backend сервер...${NC}"

    # Останавливаем все PM2 процессы
    echo -e "   🔄 Останавливаем PM2..."
    pm2 stop all 2>/dev/null || echo -e "   ${YELLOW}⚠️ PM2 не запущен${NC}"

    # Проверяем что backend файлы существуют
    echo -e "   🔍 Проверяем backend файлы..."
    if [ -f "/home/node/ruplatform/server/dist/index.js" ]; then
        echo -e "   ${GREEN}✅ Backend файл найден${NC}"
    else
        echo -e "   ${RED}❌ Backend файл НЕ найден${NC}"
        echo -e "   ${YELLOW}💡 Нужно пересобрать backend${NC}"
        return 1
    fi

    # Запускаем backend сервер
    echo -e "   🚀 Запускаем backend сервер..."
    cd /home/node/ruplatform/server
    pm2 start dist/index.js --name "ruplatform-backend" 2>/dev/null || echo -e "   ${RED}❌ Не могу запустить backend${NC}"

    # Ждем немного
    echo -e "   ⏳ Ждем запуска сервера..."
    sleep 3

    # Проверяем что сервер запустился
    if pm2 status | grep -q "online"; then
        echo -e "   ${GREEN}✅ Backend сервер запущен${NC}"
        pm2 status | grep ruplatform-backend
    else
        echo -e "   ${RED}❌ Backend сервер не запустился${NC}"
        return 1
    fi

    return 0
}

# Функция для проверки API соединения
test_api_connection() {
    echo -e "${YELLOW}4. Тестируем API соединение...${NC}"

    # Тестируем через nginx (HTTPS)
    echo -e "   🌐 Тестируем через nginx (HTTPS):"
    local nginx_response=$(curl -s -w "%{http_code}" -o /dev/null https://soulsynergy.ru/api/articles 2>/dev/null)
    if [ "$nginx_response" = "200" ]; then
        echo -e "   ${GREEN}✅ nginx отвечает: $nginx_response${NC}"
    else
        echo -e "   ${RED}❌ nginx не отвечает: $nginx_response${NC}"
    fi

    # Тестируем напрямую к backend (HTTP)
    echo -e "   🔧 Тестируем напрямую к backend:"
    local backend_response=$(curl -s -w "%{http_code}" -o /dev/null http://localhost:3000/api/articles 2>/dev/null)
    if [ "$backend_response" = "200" ]; then
        echo -e "   ${GREEN}✅ backend отвечает: $backend_response${NC}"
    else
        echo -e "   ${RED}❌ backend не отвечает: $backend_response${NC}"
    fi

    # Тестируем несколько эндпоинтов
    echo -e "   🔍 Тестируем различные эндпоинты:"
    local endpoints=("/api/articles" "/api/experts/search" "/api/users/cities")
    for endpoint in "${endpoints[@]}"; do
        local response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:3000$endpoint" 2>/dev/null)
        if [ "$response" = "200" ]; then
            echo -e "   ${GREEN}✅ $endpoint: $response${NC}"
        else
            echo -e "   ${RED}❌ $endpoint: $response${NC}"
        fi
    done
}

# Функция для перезапуска всех сервисов
restart_all_services() {
    echo -e "${BLUE}5. Перезапускаем все сервисы...${NC}"

    # Перезапускаем PM2
    echo -e "   🔄 Перезапускаем PM2..."
    pm2 restart all 2>/dev/null || echo -e "   ${YELLOW}⚠️ PM2 не может перезапуститься${NC}"

    # Перезагружаем nginx
    echo -e "   🔄 Перезагружаем nginx..."
    sudo systemctl reload nginx

    # Ждем немного
    echo -e "   ⏳ Ждем запуска сервисов..."
    sleep 5

    # Проверяем статус
    echo -e "   🔍 Статус после перезапуска:"
    pm2 status 2>/dev/null | grep -E "(online|offline|errored)" || echo -e "   ${YELLOW}⚠️ Нет статуса PM2${NC}"
    sudo systemctl status nginx --no-pager -l 2>/dev/null | grep -E "(Active|Loaded)" || echo -e "   ${YELLOW}⚠️ Нет статуса nginx${NC}"
}

# Основная логика
echo -e "${GREEN}🚀 НАЧИНАЕМ ДИАГНОСТИКУ И ИСПРАВЛЕНИЕ 502 ОШИБКИ${NC}"
echo ""

# Диагностируем backend
diagnose_backend

echo ""
echo -e "${BLUE}📊 РЕЗУЛЬТАТ ДИАГНОСТИКИ:${NC}"
echo "   Если backend не запущен - запускаем его"
echo "   Если nginx не настроен - исправляем конфигурацию"
echo ""

# Проверяем nginx конфигурацию
if check_nginx_config; then
    echo ""
    echo -e "${BLUE}✅ NGINX КОНФИГУРАЦИЯ КОРРЕКТНА${NC}"
else
    echo ""
    echo -e "${RED}❌ ПРОБЛЕМЫ С NGINX КОНФИГУРАЦИЕЙ${NC}"
    exit 1
fi

# Исправляем backend сервер
if fix_backend_server; then
    echo ""
    echo -e "${BLUE}✅ BACKEND СЕРВЕР ЗАПУЩЕН${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ ЗАПУСТИТЬ BACKEND СЕРВЕР${NC}"
    echo -e "${YELLOW}💡 Попробуйте пересобрать backend:${NC}"
    echo "   cd /home/node/ruplatform/server"
    echo "   npm run build"
    echo "   pm2 restart all"
    exit 1
fi

# Тестируем API соединение
echo ""
test_api_connection

echo ""
echo -e "${BLUE}🔄 ПЕРЕЗАПУСКАЕМ СЕРВИСЫ ДЛЯ ПРИМЕНЕНИЯ ИЗМЕНЕНИЙ...${NC}"

# Перезапускаем все сервисы
restart_all_services

echo ""
echo -e "${GREEN}🎉 ИСПРАВЛЕНИЕ 502 ОШИБКИ ЗАВЕРШЕНО!${NC}"
echo ""
echo -e "${YELLOW}🔄 Теперь выполните:${NC}"
echo "   1. Перезагрузите страницу в браузере: Ctrl+Shift+R"
echo ""
echo -e "${YELLOW}🧪 Проверьте:${NC}"
echo "   - API запросы должны возвращать 200 OK"
echo "   - Нет ошибок 502 Bad Gateway"
echo "   - Авторизация работает"
echo "   - Все функции работают"

echo ""
echo -e "${GREEN}🔧 ДИАГНОСТИКА ЗАВЕРШЕНА${NC}"

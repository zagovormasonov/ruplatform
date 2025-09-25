#!/bin/bash

echo "🔍 ДИАГНОСТИКА 404 NOT FOUND ОШИБКИ..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для диагностики системы
diagnose_system() {
    echo -e "${BLUE}🔍 ДИАГНОСТИКА СИСТЕМЫ...${NC}"

    # Проверяем PM2 статус
    echo -e "${YELLOW}1. Проверяем PM2 процессы...${NC}"
    pm2 status 2>/dev/null || echo "   ❌ PM2 не запущен или нет процессов"

    # Проверяем порт 3001
    echo -e "${YELLOW}2. Проверяем порт 3001...${NC}"
    local port_3001=$(netstat -tlnp 2>/dev/null | grep -c ":3001 ")
    echo -e "   📊 Процессов на порту 3001: $port_3001"

    if [ "$port_3001" -gt 0 ]; then
        echo -e "   📋 Процессы на порту 3001:"
        netstat -tlnp 2>/dev/null | grep ":3001 "
    else
        echo -e "   ${RED}❌ Порт 3001 не открыт${NC}"
    fi

    # Проверяем Node.js процессы
    echo -e "${YELLOW}3. Проверяем Node.js процессы...${NC}"
    ps aux | grep -E "node.*300[01]" | grep -v grep || echo "   ❌ Нет Node.js процессов на портах 3001/3001"

    # Проверяем nginx конфигурацию
    echo -e "${YELLOW}4. Проверяем nginx конфигурацию...${NC}"
    sudo nginx -t 2>/dev/null && echo "   ${GREEN}✅ nginx конфигурация корректна${NC}" || echo "   ${RED}❌ nginx конфигурация содержит ошибки${NC}"

    # Проверяем статус nginx
    sudo systemctl is-active nginx 2>/dev/null && echo "   ${GREEN}✅ nginx активен${NC}" || echo "   ${RED}❌ nginx не активен${NC}"
}

# Функция для тестирования API
test_api() {
    echo -e "${BLUE}🔍 ТЕСТИРОВАНИЕ API...${NC}"

    # Тестируем напрямую localhost:3001
    echo -e "${YELLOW}1. Тестируем backend напрямую...${NC}"
    local direct_response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:3001/api/experts/1" 2>/dev/null)
    echo -e "   📊 Прямой запрос к backend: $direct_response"

    if [ "$direct_response" = "200" ]; then
        echo -e "   ${GREEN}✅ Backend отвечает напрямую${NC}"
    else
        echo -e "   ${RED}❌ Backend не отвечает напрямую${NC}"
    fi

    # Тестируем через nginx
    echo -e "${YELLOW}2. Тестируем через nginx (HTTP)...${NC}"
    local nginx_response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost/api/experts/1" 2>/dev/null)
    echo -e "   📊 HTTP запрос через nginx: $nginx_response"

    # Тестируем через nginx HTTPS
    echo -e "${YELLOW}3. Тестируем через nginx (HTTPS)...${NC}"
    local nginx_https_response=$(curl -s -w "%{http_code}" -o /dev/null "https://soulsynergy.ru/api/experts/1" 2>/dev/null)
    echo -e "   📊 HTTPS запрос через nginx: $nginx_https_response"

    if [ "$nginx_https_response" = "200" ]; then
        echo -e "   ${GREEN}✅ nginx проксирует HTTPS запросы${NC}"
    else
        echo -e "   ${RED}❌ nginx НЕ проксирует HTTPS запросы${NC}"
        echo -e "   📋 Детали ответа:"
        curl -s -I "https://soulsynergy.ru/api/experts/1" 2>/dev/null | head -10
    fi
}

# Функция для исправления проблем
fix_issues() {
    echo -e "${BLUE}🔧 ИСПРАВЛЯЕМ ПРОБЛЕМЫ...${NC}"

    # Освобождаем порт 3001
    echo -e "${YELLOW}1. Освобождаем порт 3001...${NC}"
    pm2 stop all 2>/dev/null || true
    pm2 delete all 2>/dev/null || true
    pm2 kill 2>/dev/null || true
    pkill -9 node 2>/dev/null || true
    pkill -9 -f "ruplatform" 2>/dev/null || true
    sleep 3

    # Пересобираем backend
    echo -e "${YELLOW}2. Пересобираем backend...${NC}"
    cd /home/node/ruplatform/server
    npm run build

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Backend собран успешно${NC}"
    else
        echo -e "   ${RED}❌ Сборка backend не удалась${NC}"
        return 1
    fi

    # Запускаем backend
    echo -e "${YELLOW}3. Запускаем backend...${NC}"
    pm2 start dist/index.js --name "ruplatform-backend" -- --port 3001

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Backend запущен${NC}"
    else
        echo -e "   ${RED}❌ Не удалось запустить backend${NC}"
        return 1
    fi

    # Перезагружаем nginx
    echo -e "${YELLOW}4. Перезагружаем nginx...${NC}"
    sudo systemctl reload nginx

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ nginx перезагружен${NC}"
    else
        echo -e "   ${RED}❌ Не удалось перезагрузить nginx${NC}"
        return 1
    fi

    return 0
}

# Основная логика
echo -e "${GREEN}🚀 НАЧИНАЕМ ДИАГНОСТИКУ 404 ОШИБКИ${NC}"
echo ""

# Диагностируем проблему
diagnose_system
echo ""

# Тестируем API
test_api
echo ""

# Исправляем проблемы
if fix_issues; then
    echo ""
    echo -e "${BLUE}✅ ПРОБЛЕМЫ ИСПРАВЛЕНЫ${NC}"
    echo ""
    echo -e "${YELLOW}🔄 Финальное тестирование...${NC}"

    # Ждем запуска backend
    sleep 5

    # Тестируем API
    local final_response=$(curl -s -w "%{http_code}" -o /dev/null "https://soulsynergy.ru/api/experts/1" 2>/dev/null)
    if [ "$final_response" = "200" ]; then
        echo -e "   ${GREEN}✅ API работает: $final_response${NC}"
        echo -e "${GREEN}🎉 404 ОШИБКА ИСПРАВЛЕНА!${NC}"
    else
        echo -e "   ${RED}❌ API все еще не отвечает: $final_response${NC}"
        echo -e "${RED}❌ ПРОБЛЕМЫ ОСТАЛИСЬ${NC}"
        exit 1
    fi
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ ИСПРАВИТЬ ПРОБЛЕМЫ${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}🔄 Теперь протестируйте в браузере:${NC}"
echo "   1. Откройте https://soulsynergy.ru/experts/1"
echo "   2. Проверьте что имя эксперта отображается"
echo "   3. Нажмите 'Связаться с экспертом'"
echo "   4. Должно работать без ошибок"
echo ""
echo -e "${GREEN}🔥 API ДОЛЖЕН РАБОТАТЬ ТЕПЕРЬ!${NC}"

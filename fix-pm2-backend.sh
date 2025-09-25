#!/bin/bash

echo "🔧 ИСПРАВЛЕНИЕ PM2 И BACKEND СЕРВЕРА..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для остановки всех процессов
stop_all_processes() {
    echo -e "${YELLOW}1. Останавливаем все Node.js процессы...${NC}"

    # Останавливаем PM2
    echo -e "   🔄 Останавливаем PM2..."
    pm2 stop all 2>/dev/null || echo -e "   ${YELLOW}⚠️ PM2 не запущен${NC}"
    pm2 delete all 2>/dev/null || echo -e "   ${YELLOW}⚠️ PM2 не может удалить процессы${NC}"

    # Убиваем все Node.js процессы связанные с нашим приложением
    echo -e "   🔄 Убиваем Node.js процессы..."
    pkill -f "node.*ruplatform" 2>/dev/null || echo -e "   ${YELLOW}⚠️ Нет процессов для убийства${NC}"
    pkill -f "node.*3000" 2>/dev/null || echo -e "   ${YELLOW}⚠️ Нет процессов на порту 3000${NC}"

    # Ждем немного
    sleep 2

    echo -e "   ${GREEN}✅ Все процессы остановлены${NC}"
}

# Функция для проверки что ничего не запущено
verify_cleanup() {
    echo -e "${YELLOW}2. Проверяем что все остановлено...${NC}"

    # Проверяем PM2
    if pm2 status 2>/dev/null | grep -q "online\|stopped"; then
        echo -e "   ${RED}❌ PM2 все еще имеет процессы${NC}"
        pm2 status
        return 1
    else
        echo -e "   ${GREEN}✅ PM2 чист${NC}"
    fi

    # Проверяем порт 3000
    if netstat -tlnp 2>/dev/null | grep -q ":3000 "; then
        echo -e "   ${RED}❌ Порт 3000 все еще занят${NC}"
        netstat -tlnp | grep ":3000"
        return 1
    else
        echo -e "   ${GREEN}✅ Порт 3000 свободен${NC}"
    fi

    # Проверяем Node.js процессы
    local node_processes=$(ps aux | grep -E "node.*ruplatform|node.*3000" | grep -v grep | wc -l)
    if [ "$node_processes" -gt 0 ]; then
        echo -e "   ${RED}❌ Найдено $node_processes Node.js процессов${NC}"
        ps aux | grep -E "node.*ruplatform|node.*3000" | grep -v grep
        return 1
    else
        echo -e "   ${GREEN}✅ Нет Node.js процессов${NC}"
    fi

    return 0
}

# Функция для запуска backend через PM2
start_backend_with_pm2() {
    echo -e "${BLUE}3. Запускаем backend через PM2...${NC}"

    # Проверяем что файл существует
    if [ ! -f "/home/node/ruplatform/server/dist/index.js" ]; then
        echo -e "   ${RED}❌ Backend файл не найден: /home/node/ruplatform/server/dist/index.js${NC}"
        echo -e "   ${YELLOW}💡 Нужно пересобрать backend${NC}"
        return 1
    fi

    # Проверяем ecosystem.config.js
    if [ -f "/home/node/ruplatform/server/ecosystem.config.js" ]; then
        echo -e "   📄 Найден ecosystem.config.js, используем его..."
        cd /home/node/ruplatform/server
        pm2 start ecosystem.config.js
    else
        echo -e "   📄 ecosystem.config.js не найден, запускаем напрямую..."
        cd /home/node/ruplatform/server
        pm2 start dist/index.js --name "ruplatform-backend"
    fi

    # Ждем запуска
    echo -e "   ⏳ Ждем запуска сервера..."
    sleep 5

    # Проверяем что PM2 запустил процесс
    if pm2 status 2>/dev/null | grep -q "online"; then
        echo -e "   ${GREEN}✅ Backend запущен через PM2${NC}"
        pm2 status | grep ruplatform
        return 0
    else
        echo -e "   ${RED}❌ Backend не запустился через PM2${NC}"
        pm2 logs --lines 10
        return 1
    fi
}

# Функция для проверки конфигурации
verify_configuration() {
    echo -e "${YELLOW}4. Проверяем конфигурацию...${NC}"

    # Проверяем PM2 статус
    echo -e "   🔍 PM2 статус:"
    pm2 status 2>/dev/null || echo -e "   ${RED}❌ PM2 не работает${NC}"

    # Проверяем порт 3000
    echo -e "   🔍 Порт 3000:"
    if netstat -tlnp 2>/dev/null | grep -q ":3000 "; then
        echo -e "   ${GREEN}✅ Порт 3000 открыт${NC}"
        netstat -tlnp | grep ":3000"
    else
        echo -e "   ${RED}❌ Порт 3000 не открыт${NC}"
        return 1
    fi

    # Проверяем nginx
    echo -e "   🔍 nginx конфигурация:"
    if sudo nginx -t 2>/dev/null; then
        echo -e "   ${GREEN}✅ nginx конфигурация корректна${NC}"
    else
        echo -e "   ${RED}❌ nginx конфигурация неправильная${NC}"
        sudo nginx -t
        return 1
    fi

    return 0
}

# Функция для тестирования API
test_api_endpoints() {
    echo -e "${YELLOW}5. Тестируем API эндпоинты...${NC}"

    # Тестируем напрямую к backend
    echo -e "   🔧 Тестируем напрямую к backend (localhost:3000):"
    local endpoints=("/api/articles" "/api/experts/search" "/api/users/cities" "/api/auth/verify")
    for endpoint in "${endpoints[@]}"; do
        local response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:3000$endpoint" 2>/dev/null)
        if [ "$response" = "200" ]; then
            echo -e "   ${GREEN}✅ $endpoint: $response${NC}"
        else
            echo -e "   ${RED}❌ $endpoint: $response${NC}"
        fi
    done

    # Тестируем через nginx
    echo -e "   🌐 Тестируем через nginx (HTTPS):"
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
echo -e "${GREEN}🚀 НАЧИНАЕМ ИСПРАВЛЕНИЕ PM2 И BACKEND СЕРВЕРА${NC}"
echo ""

# Останавливаем все процессы
stop_all_processes

echo ""
echo -e "${BLUE}📊 ПРОВЕРЯЕМ ЧТО ВСЕ ОСТАНОВЛЕНО...${NC}"

# Проверяем что все остановлено
if verify_cleanup; then
    echo ""
    echo -e "${BLUE}✅ ВСЕ ПРОЦЕССЫ ОСТАНОВЛЕНЫ${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ ОСТАНОВИТЬ ВСЕ ПРОЦЕССЫ${NC}"
    echo -e "${YELLOW}💡 Убейте процессы вручную:${NC}"
    echo "   pkill -f 'node.*ruplatform'"
    echo "   pkill -f 'node.*3000'"
    exit 1
fi

# Запускаем backend через PM2
if start_backend_with_pm2; then
    echo ""
    echo -e "${BLUE}✅ BACKEND ЗАПУЩЕН ЧЕРЕЗ PM2${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ ЗАПУСТИТЬ BACKEND ЧЕРЕЗ PM2${NC}"
    echo -e "${YELLOW}💡 Проверьте backend файл и попробуйте пересобрать${NC}"
    exit 1
fi

# Проверяем конфигурацию
if verify_configuration; then
    echo ""
    echo -e "${BLUE}✅ КОНФИГУРАЦИЯ КОРРЕКТНА${NC}"
else
    echo ""
    echo -e "${RED}❌ ПРОБЛЕМЫ С КОНФИГУРАЦИЕЙ${NC}"
    exit 1
fi

# Тестируем API
echo ""
test_api_endpoints

echo ""
echo -e "${GREEN}🎉 ИСПРАВЛЕНИЕ PM2 И BACKEND ЗАВЕРШЕНО!${NC}"
echo ""
echo -e "${YELLOW}🔄 Теперь выполните:${NC}"
echo "   1. Перезагрузите страницу в браузере: Ctrl+Shift+R"
echo ""
echo -e "${YELLOW}🧪 Проверьте в DevTools > Network:${NC}"
echo "   - API запросы должны возвращать 200 OK"
echo "   - Нет ошибок 502 Bad Gateway"
echo "   - Авторизация работает"
echo "   - Все функции работают"

echo ""
echo -e "${GREEN}🔧 ИСПРАВЛЕНИЕ ЗАВЕРШЕНО${NC}"

#!/bin/bash

echo "🔧 ИСПРАВЛЕНИЕ КОНФЛИКТА ПОРТА 3001..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для диагностики порта 3001
diagnose_port() {
    echo -e "${BLUE}🔍 ДИАГНОСТИКА ПОРТА 3001...${NC}"

    # Проверяем что занимает порт 3001
    echo -e "${YELLOW}1. Проверяем процессы на порту 3001...${NC}"
    local port_3001=$(netstat -tlnp 2>/dev/null | grep ":3001 " | wc -l)
    echo -e "   📊 Процессов на порту 3001: $port_3001"

    if [ "$port_3001" -gt 0 ]; then
        echo -e "   📋 Список процессов на порту 3001:"
        netstat -tlnp 2>/dev/null | grep ":3001 "
    fi

    # Проверяем PM2 процессы
    echo -e "${YELLOW}2. Проверяем PM2 процессы...${NC}"
    pm2 status 2>/dev/null | head -10

    # Проверяем Node.js процессы
    echo -e "${YELLOW}3. Проверяем Node.js процессы...${NC}"
    ps aux | grep -E "node.*300[01]" | grep -v grep
}

# Функция для освобождения порта 3001
free_port() {
    echo -e "${BLUE}🔄 ОСВОБОЖДАЕМ ПОРТ 3001...${NC}"

    # Останавливаем PM2 процессы
    echo -e "   🔄 Останавливаем PM2..."
    pm2 stop all 2>/dev/null || true
    pm2 delete all 2>/dev/null || true
    pm2 kill 2>/dev/null || true

    # Убиваем Node.js процессы на портах 3001 и 3001
    echo -e "   💀 Убиваем Node.js процессы на портах 3001/3001..."
    pkill -9 -f "node.*3001" 2>/dev/null || true
    pkill -9 -f "node.*3001" 2>/dev/null || true
    pkill -9 -f "ruplatform" 2>/dev/null || true
    pkill -9 -f "dist/index.js" 2>/dev/null || true

    # Ждем освобождения порта
    echo -e "   ⏳ Ждем освобождения порта..."
    sleep 3

    # Проверяем что порт свободен
    local port_check=$(netstat -tlnp 2>/dev/null | grep -c ":3001 ")
    if [ "$port_check" -eq 0 ]; then
        echo -e "   ${GREEN}✅ Порт 3001 освобожден${NC}"
        return 0
    else
        echo -e "   ${RED}❌ Порт 3001 все еще занят${NC}"
        netstat -tlnp 2>/dev/null | grep ":3001 "
        return 1
    fi
}

# Функция для сборки backend
build_backend() {
    echo -e "${BLUE}🔨 СБОРКА BACKEND...${NC}"

    cd /home/node/ruplatform/server

    # Собираем
    echo -e "   🔨 Запускаем сборку..."
    npm run build

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Backend собран успешно${NC}"

        # Проверяем что файлы созданы
        if [ -f "dist/index.js" ]; then
            echo -e "   ${GREEN}✅ dist/index.js создан${NC}"
            return 0
        else
            echo -e "   ${RED}❌ dist/index.js НЕ создан${NC}"
            return 1
        fi
    else
        echo -e "   ${RED}❌ Сборка backend не удалась${NC}"
        return 1
    fi
}

# Функция для запуска backend
start_backend() {
    echo -e "${BLUE}🚀 ЗАПУСК BACKEND...${NC}"

    cd /home/node/ruplatform/server

    # Запускаем через PM2
    echo -e "   📡 Запускаем через PM2..."
    pm2 start dist/index.js --name "ruplatform-backend" -- --port 3001

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Backend запущен через PM2${NC}"
        echo -e "   📊 Статус PM2:"
        pm2 status
        return 0
    else
        echo -e "   ${RED}❌ Не удалось запустить backend${NC}"
        return 1
    fi
}

# Функция для тестирования
test_port() {
    echo -e "${YELLOW}🧪 ТЕСТИРОВАНИЕ ПОРТА 3001...${NC}"

    # Тестируем API
    echo -e "   🔍 Тестируем API..."
    local response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:3001/api/experts/1" 2>/dev/null)

    if [ "$response" = "200" ]; then
        echo -e "   ${GREEN}✅ API работает: $response${NC}"
        return 0
    else
        echo -e "   ${RED}❌ API не отвечает: $response${NC}"
        return 1
    fi
}

# Основная логика
echo -e "${GREEN}🚀 НАЧИНАЕМ ИСПРАВЛЕНИЕ КОНФЛИКТА ПОРТА 3001${NC}"
echo ""

# Диагностируем проблему
diagnose_port
echo ""

# Освобождаем порт
if free_port; then
    echo ""
    echo -e "${BLUE}✅ ПОРТ 3001 ОСВОБОЖДЕН${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ ОСВОБОДИТЬ ПОРТ 3001${NC}"
    echo -e "${YELLOW}⚠️ Попробуйте вручную:${NC}"
    echo "   pkill -9 node"
    echo "   pkill -9 -f '3001'"
    echo "   pkill -9 -f 'ruplatform'"
    exit 1
fi

# Собираем backend
if build_backend; then
    echo ""
    echo -e "${BLUE}✅ BACKEND СОБРАН${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ СОБРАТЬ BACKEND${NC}"
    exit 1
fi

# Запускаем backend
if start_backend; then
    echo ""
    echo -e "${BLUE}✅ BACKEND ЗАПУЩЕН${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ ЗАПУСТИТЬ BACKEND${NC}"
    exit 1
fi

# Тестируем
echo ""
if test_port; then
    echo ""
    echo -e "${GREEN}🎉 КОНФЛИКТ ПОРТА 3001 ИСПРАВЛЕН!${NC}"
    echo ""
    echo -e "${YELLOW}🔄 Теперь протестируйте в браузере:${NC}"
    echo "   1. Откройте https://soulsynergy.ru/experts/1"
    echo "   2. Проверьте что имя эксперта отображается"
    echo "   3. Нажмите 'Связаться с экспертом'"
    echo "   4. Должно работать без ошибок"
    echo ""
    echo -e "${GREEN}🔥 ПОРТ 3001 ОСВОБОЖДЕН И ПРИЛОЖЕНИЕ РАБОТАЕТ!${NC}"
else
    echo ""
    echo -e "${RED}❌ ПРОБЛЕМЫ ОСТАЛИСЬ${NC}"
    exit 1
fi

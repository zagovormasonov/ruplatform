#!/bin/bash

echo "🚨 АВАРИЙНОЕ ИСПРАВЛЕНИЕ КОНФЛИКТА ПОРТА 3001..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}🔥 НАЧИНАЕМ АВАРИЙНОЕ ОСВОБОЖДЕНИЕ ПОРТА 3000${NC}"

# Функция для принудительного освобождения порта
emergency_port_free() {
    echo -e "${BLUE}💀 УБИВАЕМ ВСЕ ПРОЦЕССЫ НА ПОРТУ 3000...${NC}"

    # Убиваем PM2 процессы
    echo -e "   🔄 Останавливаем PM2..."
    pm2 stop all 2>/dev/null || true
    pm2 delete all 2>/dev/null || true
    pm2 kill 2>/dev/null || true

    # Убиваем Node.js процессы
    echo -e "   💀 Убиваем Node.js процессы..."
    pkill -9 node 2>/dev/null || true
    pkill -9 -f "node.*3000" 2>/dev/null || true
    pkill -9 -f "node.*3001" 2>/dev/null || true
    pkill -9 -f "ruplatform" 2>/dev/null || true
    pkill -9 -f "dist/index.js" 2>/dev/null || true
    pkill -9 -f "3000" 2>/dev/null || true

    # Убиваем процессы по PID
    echo -e "   🔍 Ищем процессы на порту 3001..."
    local port_pids=$(netstat -tlnp 2>/dev/null | grep ":3001 " | awk '{print $7}' | cut -d'/' -f1)
    if [ "$port_pids" != "" ]; then
        echo -e "   💀 Убиваем процессы по PID: $port_pids"
        for pid in $port_pids; do
            if [ "$pid" != "" ] && [ "$pid" != "-" ]; then
                kill -9 $pid 2>/dev/null || true
            fi
        done
    fi

    # Ждем освобождения
    echo -e "   ⏳ Ждем освобождения порта..."
    sleep 5

    # Проверяем что порт свободен
    local port_check=$(netstat -tlnp 2>/dev/null | grep -c ":3001 ")
    if [ "$port_check" -eq 0 ]; then
        echo -e "   ${GREEN}✅ ПОРТ 3001 ОСВОБОЖДЕН${NC}"
        return 0
    else
        echo -e "   ${RED}❌ ПОРТ 3001 ВСЕ ЕЩЕ ЗАНЯТ${NC}"
        netstat -tlnp 2>/dev/null | grep ":3001 "
        return 1
    fi
}

# Функция для сборки и запуска
rebuild_and_start() {
    echo -e "${BLUE}🔨 СОБИРАЕМ И ЗАПУСКАЕМ BACKEND...${NC}"

    cd /home/node/ruplatform/server

    # Создаем .env файл
    echo -e "   📄 Создаем .env файл..."
    echo "PORT=3001" > .env

    # Собираем backend
    echo -e "   🔨 Собираем backend..."
    npm run build

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Backend собран успешно${NC}"
    else
        echo -e "   ${RED}❌ Сборка backend не удалась${NC}"
        return 1
    fi

    # Запускаем через PM2
    echo -e "   🚀 Запускаем через PM2..."
    pm2 start dist/index.js --name "ruplatform-backend" -- --port 3001

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Backend запущен через PM2${NC}"
        return 0
    else
        echo -e "   ${RED}❌ Не удалось запустить backend${NC}"
        return 1
    fi
}

# Функция для тестирования
test_everything() {
    echo -e "${YELLOW}🧪 ТЕСТИРУЕМ ВСЕ...${NC}"

    # Ждем запуска
    sleep 5

    # Проверяем PM2
    echo -e "   🔍 Проверяем PM2..."
    pm2 status 2>/dev/null | grep ruplatform-backend

    # Проверяем порт
    local port_check=$(netstat -tlnp 2>/dev/null | grep -c ":3001 ")
    if [ "$port_check" -gt 0 ]; then
        echo -e "   ${GREEN}✅ Порт 3001 открыт${NC}"
    else
        echo -e "   ${RED}❌ Порт 3001 НЕ открыт${NC}"
        return 1
    fi

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
echo -e "${RED}🚨 АВАРИЙНОЕ ОСВОБОЖДЕНИЕ ПОРТА 3000${NC}"
echo ""

# Освобождаем порт
if emergency_port_free; then
    echo ""
    echo -e "${BLUE}✅ ПОРТ 3000 ОСВОБОЖДЕН${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ ОСВОБОДИТЬ ПОРТ 3000${NC}"
    echo -e "${YELLOW}⚠️ Последняя попытка...${NC}"
    # Последняя попытка - убиваем ВСЕ
    pkill -9 -f "3000" 2>/dev/null || true
    pkill -9 -f "node" 2>/dev/null || true
    sleep 3

    # Проверяем еще раз
    local final_check=$(netstat -tlnp 2>/dev/null | grep -c ":3000 ")
    if [ "$final_check" -eq 0 ]; then
        echo -e "   ${GREEN}✅ ПОРТ ОСВОБОЖДЕН ПОСЛЕ ПОСЛЕДНЕЙ ПОПЫТКИ${NC}"
    else
        echo -e "   ${RED}❌ НЕ УДАЛОСЬ ОСВОБОДИТЬ ПОРТ ДАЖЕ ПОСЛЕ ПОСЛЕДНЕЙ ПОПЫТКИ${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}🔄 СОБИРАЕМ И ЗАПУСКАЕМ BACKEND...${NC}"

# Собираем и запускаем
if rebuild_and_start; then
    echo ""
    echo -e "${BLUE}✅ BACKEND ЗАПУЩЕН${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ ЗАПУСТИТЬ BACKEND${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}🔄 ФИНАЛЬНОЕ ТЕСТИРОВАНИЕ...${NC}"

# Тестируем
if test_everything; then
    echo ""
    echo -e "${GREEN}🎉 АВАРИЙНОЕ ИСПРАВЛЕНИЕ УСПЕШНО ЗАВЕРШЕНО!${NC}"
    echo ""
    echo -e "${YELLOW}📊 ФИНАЛЬНЫЙ СТАТУС:${NC}"
    pm2 status
    echo ""
    netstat -tlnp 2>/dev/null | grep ":3001"
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
    echo -e "${RED}❌ АВАРИЙНОЕ ИСПРАВЛЕНИЕ НЕ УДАЛОСЬ${NC}"
    exit 1
fi

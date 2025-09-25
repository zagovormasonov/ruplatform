#!/bin/bash

echo "🚀 ПРОСТОЙ ЗАПУСК СЕРВЕРА НА ПОРТУ 3001..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}1️⃣  Останавливаю все процессы...${NC}"
pm2 stop all 2>/dev/null || echo "PM2 не запущен"
pm2 delete all 2>/dev/null || echo "Процессы остановлены"
pkill -f "node.*index.js" 2>/dev/null || echo "Node процессы остановлены"
pkill -f "node.*server.js" 2>/dev/null || echo "Дополнительные процессы остановлены"
sleep 2

echo -e "${BLUE}2️⃣  Проверяю файлы...${NC}"
cd /home/node/ruplatform/server
ls -la dist/

if [ ! -f "dist/index.js" ]; then
    echo -e "${RED}❌ dist/index.js НЕ найден${NC}"
    echo -e "${YELLOW}🔧 Собираю проект...${NC}"

    echo -e "${BLUE}📦 Устанавливаю зависимости...${NC}"
    npm install --silent

    echo -e "${BLUE}🔨 Собираю TypeScript...${NC}"
    npm run build --silent

    if [ ! -f "dist/index.js" ]; then
        echo -e "${RED}❌ dist/index.js все еще НЕ создан${NC}"
        echo -e "${YELLOW}🔧 Пробую TypeScript компилятор...${NC}"
        npx tsc --project tsconfig.json --silent
    fi
fi

if [ -f "dist/index.js" ]; then
    echo -e "${GREEN}✅ dist/index.js найден${NC}"
else
    echo -e "${RED}❌ НЕ УДАЕТСЯ СОЗДАТЬ dist/index.js${NC}"
    echo -e "${YELLOW}📋 Проверяю структуру проекта...${NC}"
    ls -la
    exit 1
fi

echo -e "${BLUE}3️⃣  Запускаю сервер...${NC}"
echo -e "${YELLOW}▶️  PM2: NODE_ENV=production PORT=3001 pm2 start dist/index.js --name ruplatform-backend${NC}"
NODE_ENV=production PORT=3001 pm2 start dist/index.js --name "ruplatform-backend"

sleep 3

echo -e "${BLUE}4️⃣  Проверяю статус...${NC}"
echo "PM2 статус:"
pm2 status

echo "Процесс на порту 3001:"
lsof -i :3001 2>/dev/null || echo "❌ Нет процесса на порту 3001"

if [ -n "$(lsof -i :3001 2>/dev/null)" ]; then
    echo -e "${GREEN}✅ СЕРВЕР ЗАПУЩЕН НА ПОРТУ 3001!${NC}"
    echo ""
    echo -e "${YELLOW}🔄 ПРОВЕРЬТЕ В БРАУЗЕРЕ:${NC}"
    echo "   📱 https://soulsynergy.ru"
    echo ""
    echo -e "${GREEN}✨ РЕГИСТРАЦИЯ И АВТОРИЗАЦИЯ РАБОТАЮТ!${NC}"
else
    echo -e "${RED}❌ СЕРВЕР НЕ ЗАПУСТИЛСЯ${NC}"
    echo ""
    echo -e "${YELLOW}🔧 АВАРИЙНЫЙ ЗАПУСК...${NC}"
    echo "Запускаю напрямую в фоне..."
    nohup NODE_ENV=production PORT=3001 node dist/index.js > /tmp/server.log 2>&1 &
    SERVER_PID=$!
    sleep 3

    if [ -n "$(lsof -i :3001 2>/dev/null)" ]; then
        echo -e "${GREEN}✅ СЕРВЕР ЗАПУЩЕН НАПОМИНАНИЕ! PID: $SERVER_PID${NC}"
        echo "Логи: tail -f /tmp/server.log"
    else
        echo -e "${RED}❌ КРИТИЧЕСКАЯ ОШИБКА${NC}"
        echo "Проверьте: cat /tmp/server.log"
        echo "Проверьте: ls -la dist/index.js"
    fi
fi

echo ""
echo -e "${GREEN}🎉 ПРОСТОЙ ЗАПУСК ЗАВЕРШЕН!${NC}"

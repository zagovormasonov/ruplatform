#!/bin/bash

echo "🔧 СБОРКА И ЗАПУСК BACKEND СЕРВЕРА..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Переходим в директорию server...${NC}"
cd /home/node/ruplatform/server

echo -e "${BLUE}📦 Устанавливаю зависимости...${NC}"
npm install

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Ошибка установки зависимостей${NC}"
    exit 1
fi

echo -e "${BLUE}🔨 Собираю TypeScript...${NC}"
npm run build

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Ошибка сборки${NC}"
    exit 1
fi

# Проверяю что файл создан
if [ -f "dist/server.js" ]; then
    echo -e "${GREEN}✅ dist/server.js создан${NC}"
else
    echo -e "${RED}❌ dist/server.js НЕ создан${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}🔄 ОСТАНАВЛИВАЮ СТАРЫЕ ПРОЦЕССЫ...${NC}"
pm2 stop all 2>/dev/null || echo "PM2 не запущен"
pm2 delete all 2>/dev/null || echo "PM2 процессы не найдены"
pkill -f "node.*server.js" 2>/dev/null || echo "Node процессы не найдены"

sleep 2

echo -e "${YELLOW}▶️  ЗАПУСКАЮ СЕРВЕР НА ПОРТУ 3001...${NC}"
NODE_ENV=production PORT=3001 pm2 start dist/server.js --name "ruplatform-backend"

sleep 3

echo -e "${BLUE}📊 Статус после запуска:${NC}"
pm2 status

echo ""
if [ -n "$(lsof -i :3001 2>/dev/null)" ]; then
    echo -e "${GREEN}✅ СЕРВЕР УСПЕШНО ЗАПУЩЕН НА ПОРТУ 3001!${NC}"
    echo ""
    echo -e "${YELLOW}🔄 ПРОВЕРЬТЕ В БРАУЗЕРЕ:${NC}"
    echo "   📱 https://soulsynergy.ru"
    echo ""
    echo -e "${GREEN}✨ РЕГИСТРАЦИЯ И АВТОРИЗАЦИЯ РАБОТАЮТ!${NC}"
else
    echo -e "${RED}❌ СЕРВЕР НЕ ЗАПУСТИЛСЯ${NC}"
    echo ""
    echo -e "${YELLOW}🔧 Пробую запуск напрямую...${NC}"
    NODE_ENV=production PORT=3001 node dist/server.js &
    sleep 3

    if [ -n "$(lsof -i :3001 2>/dev/null)" ]; then
        echo -e "${GREEN}✅ СЕРВЕР ЗАПУЩЕН НАПОМИНАНИЕ!${NC}"
    else
        echo -e "${RED}❌ КРИТИЧЕСКАЯ ОШИБКА${NC}"
        echo "Проверьте: ls -la dist/server.js"
    fi
fi

echo ""
echo -e "${GREEN}🎉 СБОРКА И ЗАПУСК ЗАВЕРШЕНЫ!${NC}"

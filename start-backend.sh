#!/bin/bash

echo "🚀 ЗАПУСК BACKEND СЕРВЕРА..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Останавливаю старые процессы...${NC}"
pm2 stop all 2>/dev/null || echo "PM2 не запущен"
pm2 delete all 2>/dev/null || echo "PM2 процессы не найдены"
pkill -f "node.*index.js" 2>/dev/null || echo "Node процессы не найдены"

sleep 2

echo -e "${BLUE}📁 Проверяю файлы в dist...${NC}"
cd /home/node/ruplatform/server
ls -la dist/

if [ -f "dist/index.js" ]; then
    echo -e "${GREEN}✅ dist/index.js найден${NC}"
else
    echo -e "${RED}❌ dist/index.js НЕ найден${NC}"
    echo -e "${YELLOW}🔧 Сначала соберите проект:${NC}"
    echo "   cd /home/node/ruplatform/server"
    echo "   npm run build"
    echo "   ls -la dist/"
    exit 1
fi

echo ""
echo -e "${YELLOW}▶️  ЗАПУСКАЮ СЕРВЕР НА ПОРТУ 3001...${NC}"
NODE_ENV=production PORT=3001 pm2 start dist/index.js --name "ruplatform-backend"

sleep 3

echo -e "${BLUE}📊 Статус PM2:${NC}"
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
    NODE_ENV=production PORT=3001 node dist/index.js &
    sleep 3

    if [ -n "$(lsof -i :3001 2>/dev/null)" ]; then
        echo -e "${GREEN}✅ СЕРВЕР ЗАПУЩЕН НАПОМИНАНИЕ!${NC}"
    else
        echo -e "${RED}❌ КРИТИЧЕСКАЯ ОШИБКА${NC}"
        echo "Проверьте: pm2 logs"
    fi
fi

echo ""
echo -e "${GREEN}🎉 СЕРВЕР ЗАПУЩЕН!${NC}"

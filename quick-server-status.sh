#!/bin/bash

echo "🔍 ПРОВЕРКА СТАТУСА СЕРВЕРА НА ПОРТУ 3001..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📊 Проверяю PM2 процессы...${NC}"
pm2 status

echo ""
echo -e "${BLUE}📡 Проверяю процессы на портах...${NC}"
echo "Порт 3000:"
lsof -i :3000 2>/dev/null || echo "  Свободен"
echo "Порт 3001:"
lsof -i :3001 2>/dev/null || echo "  Свободен"

echo ""
echo -e "${BLUE}🔍 Проверяю nginx конфигурацию...${NC}"
echo "Текущая конфигурация:"
grep -n "proxy_pass.*localhost" /etc/nginx/sites-available/default 2>/dev/null || echo "  default конфигурация не найдена"
grep -n "proxy_pass.*localhost" /etc/nginx/nginx.conf 2>/dev/null || echo "  nginx.conf не содержит proxy_pass"
grep -n "proxy_pass.*localhost" /home/node/ruplatform/nginx.conf 2>/dev/null || echo "  nginx.conf в проекте не содержит proxy_pass"

echo ""
echo -e "${YELLOW}🔄 ПЕРЕЗАПУСКАЮ СЕРВЕР НА ПОРТУ 3001...${NC}"

# Останавливаю все
pm2 stop all 2>/dev/null || echo "PM2 не запущен"
pm2 delete all 2>/dev/null || echo "PM2 процессы не найдены"
pkill -f "node.*server.js" 2>/dev/null || echo "Node процессы не найдены"

sleep 2

# Запускаю на 3001
echo -e "${BLUE}▶️  Запускаю backend на порту 3001...${NC}"
cd /home/node/ruplatform/server
NODE_ENV=production PORT=3001 pm2 start dist/server.js --name "ruplatform-backend"

sleep 3

echo -e "${BLUE}📊 Статус после перезапуска:${NC}"
pm2 status

echo ""
if [ -n "$(lsof -i :3001 2>/dev/null)" ]; then
    echo -e "${GREEN}✅ СЕРВЕР УСПЕШНО ЗАПУЩЕН НА ПОРТУ 3001!${NC}"
    echo ""
    echo -e "${YELLOW}🔄 ПРОВЕРЬТЕ В БРАУЗЕРЕ:${NC}"
    echo "   📱 https://soulsynergy.ru"
    echo ""
    echo -e "${GREEN}✨ РЕГИСТРАЦИЯ И АВТОРИЗАЦИЯ ДОЛЖНЫ РАБОТАТЬ!${NC}"
else
    echo -e "${RED}❌ СЕРВЕР НЕ ЗАПУСТИЛСЯ${NC}"
    echo ""
    echo -e "${YELLOW}🔧 Пробую запуск напрямую...${NC}"
    cd /home/node/ruplatform/server
    NODE_ENV=production PORT=3001 node dist/server.js &
    sleep 3

    if [ -n "$(lsof -i :3001 2>/dev/null)" ]; then
        echo -e "${GREEN}✅ СЕРВЕР ЗАПУЩЕН НАПОМИНАНИЕ!${NC}"
    else
        echo -e "${RED}❌ КРИТИЧЕСКАЯ ОШИБКА - СЕРВЕР НЕ ЗАПУСКАЕТСЯ${NC}"
        echo "Проверьте логи: pm2 logs"
    fi
fi

echo ""
echo -e "${GREEN}🎉 ПРОВЕРКА ЗАВЕРШЕНА!${NC}"

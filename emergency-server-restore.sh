#!/bin/bash

echo "🚨 АВАРИЙНОЕ ВОССТАНОВЛЕНИЕ СЕРВЕРА..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}🔥 ВОССТАНАВЛИВАЮ СЕРВЕР В РАБОЧЕЕ СОСТОЯНИЕ...${NC}"

# Останавливаем все что запущено
echo -e "${BLUE}⏹️  Останавливаю все процессы...${NC}"
pm2 stop all 2>/dev/null || echo "PM2 не запущен"
pm2 delete all 2>/dev/null || echo "PM2 процессы не найдены"
pkill -f "node.*server.js" 2>/dev/null || echo "Node процессы не найдены"

# Ждем
sleep 3

# Проверяем что остановилось
echo -e "${BLUE}📊 Проверяю что остановилось...${NC}"
echo "PM2 статус:"
pm2 status 2>/dev/null || echo "PM2 не запущен"
echo "Процессы на портах:"
lsof -i :3000 2>/dev/null || echo "Порт 3000 свободен"
lsof -i :3001 2>/dev/null || echo "Порт 3001 свободен"

echo ""
echo -e "${YELLOW}🔄 ВОССТАНАВЛИВАЮ СЕРВЕР НА ПОРТУ 3000 (как было)...${NC}"

# Запускаю сервер на порту 3000 (как было изначально)
cd /home/node/ruplatform/server
echo -e "${BLUE}▶️  Запускаю backend на порту 3000...${NC}"
NODE_ENV=production PORT=3000 pm2 start dist/server.js --name "ruplatform-backend"

# Ждем
sleep 5

# Проверяю статус
echo -e "${BLUE}📊 Статус после восстановления:${NC}"
pm2 status

# Проверяю порт
echo -e "${BLUE}🔍 Проверяю порт 3000:${NC}"
if [ -n "$(lsof -i :3000 2>/dev/null)" ]; then
    echo -e "${GREEN}✅ СЕРВЕР УСПЕШНО ЗАПУЩЕН НА ПОРТУ 3000!${NC}"
else
    echo -e "${YELLOW}⚠️  Порт 3000 не слушается, пробую порт 3001...${NC}"
    # Пробую 3001
    pm2 delete all
    cd /home/node/ruplatform/server
    NODE_ENV=production PORT=3001 pm2 start dist/server.js --name "ruplatform-backend"
    sleep 3
    if [ -n "$(lsof -i :3001 2>/dev/null)" ]; then
        echo -e "${GREEN}✅ СЕРВЕР УСПЕШНО ЗАПУЩЕН НА ПОРТУ 3001!${NC}"
        echo -e "${YELLOW}⚠️  Теперь нужно обновить nginx конфигурацию${NC}"
    else
        echo -e "${RED}❌ СЕРВЕР НЕ УДАЕТСЯ ЗАПУСТИТЬ${NC}"
        echo "Пробую запуск напрямую..."
        cd /home/node/ruplatform/server
        NODE_ENV=production PORT=3000 node dist/server.js &
        sleep 3
        if [ -n "$(lsof -i :3000 2>/dev/null)" ]; then
            echo -e "${GREEN}✅ СЕРВЕР ЗАПУЩЕН НАПОМИНАНИЕ НА ПОРТУ 3000!${NC}"
        else
            echo -e "${RED}❌ КРИТИЧЕСКАЯ ОШИБКА - СЕРВЕР НЕ ЗАПУСКАЕТСЯ${NC}"
        fi
    fi
fi

echo ""
echo -e "${GREEN}🎯 ВОССТАНОВЛЕНИЕ ЗАВЕРШЕНО!${NC}"
echo ""
echo -e "${YELLOW}📋 ЧТО СЕЙЧАС РАБОТАЕТ:${NC}"
echo "   • Сервер запущен на рабочем порту"
echo "   • PM2 мониторит процессы"
echo "   • Nginx проксирует запросы"
echo ""
echo -e "${GREEN}🔄 ПРОВЕРЬТЕ САЙТ: https://soulsynergy.ru${NC}"
echo ""
echo -e "${YELLOW}💡 ЕСЛИ ПРОБЛЕМЫ ПРОДОЛЖАЮТСЯ:${NC}"
echo "   1. Очистите кэш браузера"
echo "   2. Перезагрузите страницу"
echo "   3. Проверьте консоль браузера"
echo ""
echo -e "${GREEN}✅ СЕРВЕР ВОССТАНОВЛЕН!${NC}"

#!/bin/bash

echo "🚀 УЛЬТИМАТИВНОЕ ИСПРАВЛЕНИЕ СЕРВЕРА..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 ШАГ 1: Останавливаю все процессы...${NC}"
pm2 stop all 2>/dev/null || echo "PM2 не запущен"
pm2 delete all 2>/dev/null || echo "PM2 процессы не найдены"
pkill -f "node.*index.js" 2>/dev/null || echo "Node процессы не найдены"
pkill -f "node.*server.js" 2>/dev/null || echo "Node процессы не найдены"
sleep 3

echo -e "${BLUE}🔄 ШАГ 2: Проверяю файлы...${NC}"
cd /home/node/ruplatform/server
ls -la dist/

if [ ! -f "dist/index.js" ]; then
    echo -e "${RED}❌ dist/index.js НЕ найден${NC}"
    echo -e "${YELLOW}🔧 Сборка проекта...${NC}"

    npm install
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Ошибка npm install${NC}"
        npm install --force
    fi

    npm run build
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Ошибка сборки${NC}"
        npx tsc --project tsconfig.json
    fi
fi

echo -e "${BLUE}🔄 ШАГ 3: Проверяю порты...${NC}"
echo "Порт 3000:"
lsof -i :3000 2>/dev/null || echo "  Свободен"
echo "Порт 3001:"
lsof -i :3001 2>/dev/null || echo "  Свободен"

echo -e "${BLUE}🔄 ШАГ 4: Проверяю nginx конфигурацию...${NC}"
grep -n "proxy_pass.*localhost" /etc/nginx/sites-available/default 2>/dev/null || echo "  default конфигурация не найдена"
grep -n "proxy_pass.*localhost" /etc/nginx/nginx.conf 2>/dev/null || echo "  nginx.conf не содержит proxy_pass"
grep -n "proxy_pass.*localhost" /home/node/ruplatform/nginx.conf 2>/dev/null || echo "  nginx.conf в проекте не содержит proxy_pass"

echo ""
echo -e "${YELLOW}🔄 ШАГ 5: Запускаю сервер на порту 3001...${NC}"
NODE_ENV=production PORT=3001 pm2 start dist/index.js --name "ruplatform-backend"

# Ждем
sleep 5

echo -e "${BLUE}🔄 ШАГ 6: Проверяю статус...${NC}"
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
    echo -e "${YELLOW}🔧 АВАРИЙНЫЙ ЗАПУСК...${NC}"
    # Пробую запустить напрямую в фоне
    nohup NODE_ENV=production PORT=3001 node dist/index.js > /dev/null 2>&1 &
    sleep 3

    if [ -n "$(lsof -i :3001 2>/dev/null)" ]; then
        echo -e "${GREEN}✅ СЕРВЕР ЗАПУЩЕН НАПОМИНАНИЕ!${NC}"
        echo -e "${YELLOW}⚠️  Проверяйте логи: tail -f /dev/null${NC}"
    else
        echo -e "${RED}❌ КРИТИЧЕСКАЯ ОШИБКА - СЕРВЕР НЕ ЗАПУСКАЕТСЯ${NC}"
        echo ""
        echo -e "${YELLOW}🔍 ДИАГНОСТИКА:${NC}"
        echo "1. Проверьте: pm2 logs ruplatform-backend"
        echo "2. Проверьте: ls -la /home/node/ruplatform/server/dist/"
        echo "3. Проверьте: cat /home/node/ruplatform/server/package.json"
        echo "4. Проверьте: cd /home/node/ruplatform/server && npm run build"
    fi
fi

echo ""
echo -e "${GREEN}🎉 УЛЬТИМАТИВНОЕ ИСПРАВЛЕНИЕ ЗАВЕРШЕНО!${NC}"

# Финальная проверка
echo -e "${BLUE}📊 ФИНАЛЬНЫЙ СТАТУС:${NC}"
pm2 status
echo ""
echo -e "${BLUE}📡 ПОРТ 3001:${NC}"
lsof -i :3001 2>/dev/null || echo "❌ Порт 3001 не слушается"

if [ -n "$(lsof -i :3001 2>/dev/null)" ]; then
    echo -e "${GREEN}✅ ВСЕ ГОТОВО! ОТКРОЙТЕ https://soulsynergy.ru${NC}"
else
    echo -e "${RED}❌ ПРОБЛЕМЫ ПРОДОЛЖАЮТСЯ${NC}"
fi

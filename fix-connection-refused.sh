#!/bin/bash

echo "🔧 ДИАГНОСТИКА И ИСПРАВЛЕНИЕ ERR_CONNECTION_REFUSED..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 ПРОВЕРЯЕМ СТАТУС ПРОЦЕССОВ...${NC}"

# Проверяем PM2 процессы
echo -e "${YELLOW}📊 Статус PM2 процессов:${NC}"
pm2 status

echo ""
echo -e "${BLUE}🔍 ПРОВЕРЯЕМ ПРОЦЕССЫ НА ПОРТАХ...${NC}"

# Проверяем что слушает на порту 3001
echo -e "${YELLOW}📡 Процессы на порту 3001:${NC}"
lsof -i :3001 2>/dev/null || echo "Нет процессов на порту 3001"

# Проверяем что слушает на порту 3000
echo -e "${YELLOW}📡 Процессы на порту 3000:${NC}"
lsof -i :3000 2>/dev/null || echo "Нет процессов на порту 3000"

echo ""
echo -e "${BLUE}🔄 ПЕРЕЗАПУСКАЕМ BACKEND...${NC}"

# Останавливаем все процессы
echo -e "${YELLOW}⏹️  Останавливаем все PM2 процессы...${NC}"
pm2 stop all
pm2 delete all

# Ждем немного
sleep 2

# Запускаем backend на порту 3001
echo -e "${YELLOW}▶️  Запускаем backend на порту 3001...${NC}"
cd /home/node/ruplatform/server
NODE_ENV=production PORT=3001 pm2 start dist/server.js --name "ruplatform-backend"

# Ждем запуска
sleep 3

# Проверяем статус
echo -e "${BLUE}📊 Статус после перезапуска:${NC}"
pm2 status

# Проверяем что слушает на порту 3001
echo -e "${BLUE}🔍 Проверяем порт 3001:${NC}"
lsof -i :3001 2>/dev/null || echo "Порт 3001 все еще не слушается"

echo ""
if [ -n "$(lsof -i :3001 2>/dev/null)" ]; then
    echo -e "${GREEN}✅ BACKEND УСПЕШНО ЗАПУЩЕН НА ПОРТУ 3001!${NC}"
    echo ""
    echo -e "${YELLOW}🔄 ПРОВЕРЬТЕ В БРАУЗЕРЕ:${NC}"
    echo "   📱 https://soulsynergy.ru"
    echo ""
    echo -e "${GREEN}✨ ПРОБЛЕМА ERR_CONNECTION_REFUSED РЕШЕНА!${NC}"
else
    echo -e "${RED}❌ BACKEND НЕ ЗАПУСТИЛСЯ${NC}"
    echo ""
    echo -e "${YELLOW}🔧 Пробуем альтернативный способ запуска...${NC}"

    # Пробуем запустить напрямую
    echo -e "${BLUE}🚀 Запуск напрямую...${NC}"
    cd /home/node/ruplatform/server
    NODE_ENV=production PORT=3001 node dist/server.js &
    sleep 5

    # Проверяем еще раз
    if [ -n "$(lsof -i :3001 2>/dev/null)" ]; then
        echo -e "${GREEN}✅ BACKEND ЗАПУЩЕН НАПОМИНАНИЕ!${NC}"
        echo -e "${YELLOW}⚠️  Процесс запущен в фоне, но не под PM2${NC}"
    else
        echo -e "${RED}❌ BACKEND НЕ УДАЕТСЯ ЗАПУСТИТЬ${NC}"
        echo ""
        echo -e "${YELLOW}🔍 ДИАГНОСТИКА:${NC}"
        echo "1. Проверьте логи: pm2 logs"
        echo "2. Проверьте конфигурацию: cat /home/node/ruplatform/server/dist/server.js"
        echo "3. Проверьте зависимости: cd /home/node/ruplatform/server && npm ls"
    fi
fi

echo ""
echo -e "${GREEN}🎉 ДИАГНОСТИКА ЗАВЕРШЕНА!${NC}"

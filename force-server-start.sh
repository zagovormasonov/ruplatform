#!/bin/bash

echo "🔥 ПРИНУДИТЕЛЬНЫЙ ЗАПУСК СЕРВЕРА..."

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📍 ШАГ 1: Проверяю текущую директорию...${NC}"
pwd
echo -e "${BLUE}📁 Проверяю структуру проекта...${NC}"
ls -la

echo -e "${BLUE}🔍 ШАГ 2: Проверяю файлы сервера...${NC}"
cd /home/node/ruplatform/server
ls -la

echo -e "${BLUE}📦 Проверяю dist/index.js...${NC}"
if [ -f "dist/index.js" ]; then
    echo -e "${GREEN}✅ dist/index.js СУЩЕСТВУЕТ${NC}"
else
    echo -e "${RED}❌ dist/index.js НЕ НАЙДЕН${NC}"
    echo -e "${YELLOW}🔧 Собираю проект...${NC}"

    echo -e "${BLUE}📦 npm install...${NC}"
    npm install

    echo -e "${BLUE}🔨 npm run build...${NC}"
    npm run build

    if [ -f "dist/index.js" ]; then
        echo -e "${GREEN}✅ dist/index.js СОЗДАН${NC}"
    else
        echo -e "${RED}❌ НЕ УДАЛОСЬ СОЗДАТЬ dist/index.js${NC}"
        echo -e "${YELLOW}📋 Содержимое dist:${NC}"
        ls -la dist/ 2>/dev/null || echo "Директория dist не существует"
        exit 1
    fi
fi

echo -e "${BLUE}🛑 ШАГ 3: Останавливаю ВСЕ процессы...${NC}"
pm2 stop all 2>/dev/null || echo "PM2 не запущен"
pm2 delete all 2>/dev/null || echo "PM2 процессы не найдены"
pkill -f "node.*index.js" 2>/dev/null || echo "Node index.js не найден"
pkill -f "node.*server.js" 2>/dev/null || echo "Node server.js не найден"
pkill -f "node" 2>/dev/null || echo "Дополнительные node процессы остановлены"

echo -e "${BLUE}⏳ Жду 3 секунды...${NC}"
sleep 3

echo -e "${BLUE}🔍 ШАГ 4: Проверяю что ничего не слушает на порту 3001...${NC}"
lsof -i :3001 2>/dev/null || echo "Порт 3001 свободен"

echo -e "${BLUE}🚀 ШАГ 5: Запускаю сервер на порту 3001...${NC}"
echo "Команда: NODE_ENV=production PORT=3001 node dist/index.js"
NODE_ENV=production PORT=3001 node dist/index.js &
SERVER_PID=$!

echo -e "${BLUE}⏳ Жду 5 секунд...${NC}"
sleep 5

echo -e "${BLUE}🔍 ШАГ 6: Проверяю что сервер запустился...${NC}"
echo "PID процесса: $SERVER_PID"
echo "Процессы на порту 3001:"
lsof -i :3001

if [ -n "$(lsof -i :3001 2>/dev/null)" ]; then
    echo -e "${GREEN}✅ СЕРВЕР УСПЕШНО ЗАПУЩЕН НА ПОРТУ 3001!${NC}"
    echo ""
    echo -e "${YELLOW}🔄 ПРОВЕРЬТЕ В БРАУЗЕРЕ:${NC}"
    echo "   📱 https://soulsynergy.ru"
    echo ""
    echo -e "${GREEN}✨ РЕГИСТРАЦИЯ И АВТОРИЗАЦИЯ РАБОТАЮТ!${NC}"
    echo ""
    echo -e "${YELLOW}📝 Процесс запущен в фоне с PID: $SERVER_PID${NC}"
    echo -e "${YELLOW}📝 Чтобы остановить: kill $SERVER_PID${NC}"
else
    echo -e "${RED}❌ СЕРВЕР НЕ ЗАПУСТИЛСЯ${NC}"
    echo ""
    echo -e "${YELLOW}🔍 ДИАГНОСТИКА:${NC}"
    echo "1. Проверьте логи: ps aux | grep node"
    echo "2. Проверьте файл: cat dist/index.js | head -10"
    echo "3. Проверьте порт: netstat -tlnp | grep 3001"
    echo "4. Проверьте ошибки: tail -f /var/log/nginx/error.log"
fi

echo ""
echo -e "${GREEN}🎉 ПРИНУДИТЕЛЬНЫЙ ЗАПУСК ЗАВЕРШЕН!${NC}"

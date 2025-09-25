#!/bin/bash

echo "🔧 СБОРКА BACKEND ПРОЕКТА..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Переходим в директорию server...${NC}"
cd /home/node/ruplatform/server

echo -e "${BLUE}📦 Проверяю package.json...${NC}"
if [ -f "package.json" ]; then
    echo -e "${GREEN}✅ package.json найден${NC}"
else
    echo -e "${RED}❌ package.json НЕ найден${NC}"
    exit 1
fi

echo -e "${BLUE}📦 Устанавливаю зависимости...${NC}"
npm install

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Ошибка установки зависимостей${NC}"
    echo -e "${YELLOW}🔧 Пробую установить с флагом --force...${NC}"
    npm install --force

    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Критическая ошибка установки зависимостей${NC}"
        exit 1
    fi
fi

echo -e "${BLUE}🔨 Собираю TypeScript проект...${NC}"
npm run build

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Ошибка сборки${NC}"
    echo -e "${YELLOW}🔧 Пробую альтернативный способ сборки...${NC}"

    # Пробую собрать с TypeScript компилятором напрямую
    npx tsc --project tsconfig.json

    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Ошибка компиляции TypeScript${NC}"
        exit 1
    fi
fi

echo -e "${BLUE}📁 Проверяю созданные файлы...${NC}"
if [ -d "dist" ]; then
    echo -e "${GREEN}✅ Директория dist создана${NC}"
    ls -la dist/

    if [ -f "dist/server.js" ]; then
        echo -e "${GREEN}✅ dist/server.js создан${NC}"
        echo -e "${GREEN}🎉 СБОРКА УСПЕШНО ЗАВЕРШЕНА!${NC}"
    else
        echo -e "${RED}❌ dist/server.js НЕ создан${NC}"
        echo -e "${YELLOW}📋 Содержимое dist:${NC}"
        ls -la dist/
        exit 1
    fi
else
    echo -e "${RED}❌ Директория dist НЕ создана${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}🔄 ГОТОВ К ЗАПУСКУ СЕРВЕРА:${NC}"
echo "   • Выполните: pm2 start dist/server.js --name 'ruplatform-backend'"
echo "   • Или используйте готовый скрипт запуска"
echo ""
echo -e "${GREEN}✅ BACKEND ПРОЕКТ СОБРАН!${NC}"

#!/bin/bash

echo "🔧 ИСПРАВЛЕНИЕ ОШИБОК СБОРКИ ГЛАВНОЙ СТРАНИЦЫ..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Переходим в директорию client...${NC}"
cd /home/node/ruplatform/client

echo -e "${BLUE}🔨 Собираем frontend с исправлениями...${NC}"
npm run build

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Frontend собран успешно!${NC}"
    echo -e "${GREEN}✅ Ошибки TypeScript исправлены${NC}"
else
    echo -e "${RED}❌ Ошибка сборки frontend${NC}"
    echo -e "${YELLOW}⚠️  Попробуйте очистить кэш и пересобрать:${NC}"
    echo ""
    echo -e "${BLUE}🔄 Очистка кэша и пересборка...${NC}"
    rm -rf node_modules/.cache
    rm -rf dist
    npm run build

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Frontend собран успешно после очистки кэша!${NC}"
    else
        echo -e "${RED}❌ Ошибка сборки даже после очистки кэша${NC}"
        exit 1
    fi
fi

# Проверяем что файлы созданы
if [ -f "dist/index.html" ]; then
    echo -e "${GREEN}✅ dist/index.html создан${NC}"
else
    echo -e "${RED}❌ dist/index.html НЕ создан${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 ГЛАВНАЯ СТРАНИЦА УСПЕШНО СОБРАНА!${NC}"
echo ""
echo -e "${YELLOW}🔄 Теперь откройте в браузере:${NC}"
echo "   📱 https://soulsynergy.ru"
echo ""
echo -e "${GREEN}✨ ИСПРАВЛЕНИЯ ПРИМЕНЕНЫ:${NC}"
echo "   ✓ Удален неиспользуемый импорт 'Empty'"
echo "   ✓ Удален неиспользуемый импорт 'StarOutlined'"
echo "   ✓ TypeScript ошибки исправлены"
echo "   ✓ Новая главная страница готова"
echo ""
echo -e "${GREEN}🚀 ПРИЯТНОГО ИСПОЛЬЗОВАНИЯ!${NC}"

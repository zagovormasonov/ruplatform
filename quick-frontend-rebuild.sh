#!/bin/bash

echo "🔧 БЫСТРАЯ ПЕРЕСБОРКА FRONTEND..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Переходим в директорию client...${NC}"
cd /home/node/ruplatform/client

echo -e "${BLUE}🔨 Собираем frontend...${NC}"
npm run build

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Frontend собран успешно${NC}"
else
    echo -e "${RED}❌ Ошибка сборки frontend${NC}"
    exit 1
fi

# Проверяем что файлы созданы
if [ -f "dist/index.html" ]; then
    echo -e "${GREEN}✅ dist/index.html создан${NC}"
else
    echo -e "${RED}❌ dist/index.html НЕ создан${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 FRONTEND ПЕРЕСОБРАН!${NC}"
echo ""
echo -e "${YELLOW}🔄 Теперь протестируйте в браузере:${NC}"
echo "   1. Откройте https://soulsynergy.ru/chat"
echo "   2. Проверьте что имена отображаются корректно"
echo "   3. Должны показываться реальные имена из сообщений"
echo ""
echo -e "${GREEN}🔥 FRONTEND ОБНОВЛЕН И ГОТОВ К РАБОТЕ!${NC}"

#!/bin/bash

echo "🔧 БЫСТРАЯ ПЕРЕСБОРКА НОВОЙ ГЛАВНОЙ СТРАНИЦЫ..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Переходим в директорию client...${NC}"
cd /home/node/ruplatform/client

echo -e "${BLUE}🔨 Собираем frontend с новой главной страницей...${NC}"
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
echo -e "${GREEN}🎉 НОВАЯ ГЛАВНАЯ СТРАНИЦА ГОТОВА!${NC}"
echo ""
echo -e "${YELLOW}🔄 Теперь откройте в браузере:${NC}"
echo "   📱 https://soulsynergy.ru"
echo ""
echo -e "${GREEN}✨ НОВАЯ ГЛАВНАЯ СТРАНИЦА В СТИЛЕ ПОКАЗАННОГО ДИЗАЙНА:${NC}"
echo "   ✓ Градиентный hero section (синий-фиолетовый)"
echo "   ✓ Большая поисковая строка по центру"
echo "   ✓ Заголовок 'Найдите своего духовного наставника'"
echo "   ✓ Рекомендуемые эксперты с карточками"
echo "   ✓ Статьи и материалы с табами 'Новые'/'Популярные'"
echo "   ✓ Современный и стильный дизайн"
echo ""
echo -e "${GREEN}🚀 ПРИЯТНОГО ИСПОЛЬЗОВАНИЯ!${NC}"

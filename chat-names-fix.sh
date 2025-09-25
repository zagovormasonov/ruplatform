#!/bin/bash

echo "🔧 ИСПРАВЛЕНИЕ ОТОБРАЖЕНИЯ ИМЕН В ЧАТЕ..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Обновляем frontend для корректного отображения имен...${NC}"

# Переходим в директорию клиента
cd /home/node/ruplatform/client

# Проверяем что директория существует
if [ ! -d "." ]; then
    echo -e "${RED}❌ Директория client не найдена${NC}"
    exit 1
fi

# Собираем frontend
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
echo -e "${GREEN}🎉 ИСПРАВЛЕНИЯ В ЧАТЕ ПРИМЕНЕНЫ!${NC}"
echo ""
echo -e "${YELLOW}🔄 Теперь в чате будут отображаться:${NC}"
echo "   ✅ Корректные имена собеседников в сайдбаре"
echo "   ✅ Полные имена в заголовке чата"
echo "   ✅ Имена отправителей в сообщениях"
echo "   ✅ Fallback имена если данные отсутствуют"
echo ""
echo -e "${YELLOW}🔧 Что исправлено:${NC}"
echo "   1. Добавлен fallback для пустых имен: '👤 Пользователь ID'"
echo "   2. Улучшена обработка Socket.IO уведомлений"
echo "   3. Исправлено отображение ролей пользователей"
echo "   4. Добавлены проверки на null/undefined значения"
echo ""
echo -e "${GREEN}🚀 Frontend обновлен и готов к работе!${NC}"

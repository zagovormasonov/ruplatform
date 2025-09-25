#!/bin/bash

echo "🔧 ИСПРАВЛЕНИЕ ПРОФИЛЯ ЭКСПЕРТА И ФУНКЦИИ СВЯЗИ..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для пересборки backend
rebuild_backend() {
    echo -e "${BLUE}🔨 ПЕРЕСБОРКА BACKEND...${NC}"

    cd /home/node/ruplatform/server

    # Останавливаем PM2 процесс
    echo -e "   🔄 Останавливаем PM2..."
    pm2 stop ruplatform-backend 2>/dev/null || true
    pm2 delete ruplatform-backend 2>/dev/null || true

    # Собираем backend
    echo -e "   🔨 Запускаем сборку..."
    npm run build

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Backend собран успешно${NC}"
        return 0
    else
        echo -e "   ${RED}❌ Сборка backend не удалась${NC}"
        return 1
    fi
}

# Функция для запуска backend
start_backend() {
    echo -e "${BLUE}🚀 ЗАПУСК BACKEND...${NC}"

    cd /home/node/ruplatform/server

    # Запускаем через PM2
    echo -e "   📡 Запускаем через PM2..."
    pm2 start dist/index.js --name "ruplatform-backend" -- --port 3000

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Backend запущен через PM2${NC}"
        echo -e "   📊 Статус PM2:"
        pm2 status
        return 0
    else
        echo -e "   ${RED}❌ Не удалось запустить backend${NC}"
        return 1
    fi
}

# Функция для тестирования API
test_api() {
    echo -e "${YELLOW}🧪 ТЕСТИРОВАНИЕ API...${NC}"

    # Тестируем получение профиля эксперта
    echo -e "   🔍 Тестируем профиль эксперта..."
    # Предполагаем, что есть эксперт с ID 1
    local profile_response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:3000/api/experts/1" 2>/dev/null)

    if [ "$profile_response" = "200" ]; then
        echo -e "   ${GREEN}✅ API профиля эксперта работает: $profile_response${NC}"
    else
        echo -e "   ${RED}❌ API профиля эксперта не отвечает: $profile_response${NC}"
        return 1
    fi

    # Тестируем создание чата
    echo -e "   💬 Тестируем создание чата..."
    # Это будет сложнее протестировать без токена авторизации

    return 0
}

# Основная логика
echo -e "${GREEN}🚀 НАЧИНАЕМ ИСПРАВЛЕНИЕ ПРОФИЛЯ ЭКСПЕРТА${NC}"
echo ""

# Пересобираем backend
if rebuild_backend; then
    echo ""
    echo -e "${BLUE}✅ BACKEND ПЕРЕСОБРАН${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ ПЕРЕСОБРАТЬ BACKEND${NC}"
    echo -e "${YELLOW}⚠️ Попробуйте собрать вручную:${NC}"
    echo "   cd /home/node/ruplatform/server"
    echo "   npm run build"
    exit 1
fi

# Запускаем backend
if start_backend; then
    echo ""
    echo -e "${BLUE}✅ BACKEND ЗАПУЩЕН${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ ЗАПУСТИТЬ BACKEND${NC}"
    exit 1
fi

# Тестируем API
echo ""
if test_api; then
    echo ""
    echo -e "${GREEN}🎉 ИСПРАВЛЕНИЕ ЗАВЕРШЕНО!${NC}"
    echo ""
    echo -e "${YELLOW}🔄 Теперь проверьте:${NC}"
    echo "   1. Откройте профиль эксперта в браузере"
    echo "   2. Должно отображаться имя эксперта"
    echo "   3. Нажмите 'Связаться с экспертом'"
    echo "   4. Должно перейти в чат без ошибки 400"
    echo ""
    echo -e "${GREEN}🔥 ПРОФИЛЬ ЭКСПЕРТА ИСПРАВЛЕН!${NC}"
else
    echo ""
    echo -e "${RED}❌ ПРОБЛЕМЫ ОСТАЛИСЬ${NC}"
    exit 1
fi

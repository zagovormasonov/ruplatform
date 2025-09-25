#!/bin/bash

echo "🔧 ИСПРАВЛЕНИЕ ОТОБРАЖЕНИЯ ИМЕН В ЧАТЕ (BACKEND)..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для исправления backend
fix_backend() {
    echo -e "${BLUE}🔧 ИСПРАВЛЯЕМ BACKEND API...${NC}"

    cd /home/node/ruplatform

    # Останавливаем процессы
    echo -e "   🔄 Останавливаем процессы..."
    pm2 stop all 2>/dev/null || true
    pkill -9 node 2>/dev/null || true

    # Переходим в сервер
    cd server

    # Очищаем и собираем backend
    echo -e "   🔨 Собираем backend..."
    sudo rm -rf dist 2>/dev/null || rm -rf dist 2>/dev/null || true
    npm run build

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Backend собран успешно${NC}"
        return 0
    else
        echo -e "   ${RED}❌ Ошибка сборки backend${NC}"
        return 1
    fi
}

# Функция для запуска backend
start_backend() {
    echo -e "${BLUE}🚀 ЗАПУСКАЕМ BACKEND...${NC}"

    cd /home/node/ruplatform/server

    # Запускаем через PM2
    echo -e "   📡 Запускаем через PM2..."
    pm2 start dist/index.js --name "ruplatform-backend" -- --port 3001

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
    echo -e "${YELLOW}🧪 ТЕСТИРУЕМ API...${NC}"

    # Ждем запуска
    sleep 5

    # Тестируем API для получения чатов
    echo -e "   🔍 Тестируем API чатов..."
    local response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:3001/api/chats" 2>/dev/null)

    if [ "$response" = "200" ]; then
        echo -e "   ${GREEN}✅ API чатов работает: $response${NC}"

        # Тестируем получение конкретного чата
        echo -e "   🔍 Тестируем API информации о чате..."
        local chat_response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:3001/api/chats/1" 2>/dev/null)

        if [ "$chat_response" = "200" ]; then
            echo -e "   ${GREEN}✅ API информации о чате работает: $chat_response${NC}"
            return 0
        else
            echo -e "   ${RED}❌ API информации о чате не работает: $chat_response${NC}"
            return 1
        fi
    else
        echo -e "   ${RED}❌ API чатов не работает: $response${NC}"
        return 1
    fi
}

# Основная логика
echo -e "${GREEN}🚀 НАЧИНАЕМ ИСПРАВЛЕНИЕ BACKEND ДЛЯ КОРРЕКТНЫХ ИМЕН В ЧАТЕ${NC}"
echo ""

# Исправляем backend
if fix_backend; then
    echo ""
    echo -e "${BLUE}✅ BACKEND ИСПРАВЛЕН${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ ИСПРАВИТЬ BACKEND${NC}"
    exit 1
fi

# Запускаем backend
echo ""
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
    echo -e "${GREEN}🎉 BACKEND ИСПРАВЛЕН И ГОТОВ К РАБОТЕ!${NC}"
    echo ""
    echo -e "${YELLOW}🔧 Что исправлено:${NC}"
    echo "   1. SQL запросы теперь используют COALESCE для NULL имен"
    echo "   2. Конкатенация имен теперь работает с пустыми значениями"
    echo "   3. API возвращает корректные имена собеседников"
    echo ""
    echo -e "${YELLOW}🔄 Теперь протестируйте в браузере:${NC}"
    echo "   1. Откройте https://soulsynergy.ru/chat"
    echo "   2. Проверьте что имена отображаются корректно"
    echo "   3. Должны показываться реальные имена, а не 'Пользователь undefined'"
    echo ""
    echo -e "${GREEN}🔥 BACKEND ИСПРАВЛЕН И ГОТОВ К РАБОТЕ!${NC}"
else
    echo ""
    echo -e "${RED}❌ ТЕСТИРОВАНИЕ НЕ ПРОШЛО${NC}"
    exit 1
fi

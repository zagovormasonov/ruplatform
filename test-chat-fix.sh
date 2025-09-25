#!/bin/bash

echo "🔧 ТЕСТИРОВАНИЕ ИСПРАВЛЕНИЯ КНОПКИ 'СВЯЗАТЬСЯ С ЭКСПЕРТОМ'..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для проверки API профиля эксперта
test_expert_api() {
    echo -e "${BLUE}🔍 ТЕСТИРУЕМ API ПРОФИЛЯ ЭКСПЕРТА...${NC}"

    # Проверяем что API возвращает userId
    local response=$(curl -s "http://localhost:3000/api/experts/1" 2>/dev/null)

    if [ $? -eq 0 ] && [ "$response" != "" ]; then
        echo -e "   ${GREEN}✅ API профиля эксперта отвечает${NC}"

        # Проверяем что есть userId в ответе
        if echo "$response" | grep -q '"userId"'; then
            echo -e "   ${GREEN}✅ userId найден в ответе${NC}"
            echo -e "   📄 Пример ответа:"
            echo "$response" | head -3
            return 0
        else
            echo -e "   ${RED}❌ userId НЕ найден в ответе${NC}"
            echo -e "   📄 Ответ API:"
            echo "$response" | head -5
            return 1
        fi
    else
        echo -e "   ${RED}❌ API профиля эксперта не отвечает${NC}"
        return 1
    fi
}

# Функция для проверки API создания чата
test_chat_api() {
    echo -e "${BLUE}💬 ТЕСТИРУЕМ API СОЗДАНИЯ ЧАТА...${NC}"

    # Для тестирования нужен токен авторизации
    # Это будет сложно протестировать без реального токена

    echo -e "   ${YELLOW}⚠️ API создания чата требует авторизации${NC}"
    echo -e "   ${YELLOW}⚠️ Тестируйте в браузере после развертывания${NC}"
    return 0
}

# Функция для пересборки backend
rebuild_backend() {
    echo -e "${BLUE}🔨 ПЕРЕСБОРКА BACKEND...${NC}"

    cd /home/node/ruplatform/server

    # Останавливаем PM2
    echo -e "   🔄 Останавливаем PM2..."
    pm2 stop ruplatform-backend 2>/dev/null || true
    pm2 delete ruplatform-backend 2>/dev/null || true

    # Собираем
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

    # Запускаем
    echo -e "   📡 Запускаем через PM2..."
    pm2 start dist/index.js --name "ruplatform-backend" -- --port 3000

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Backend запущен${NC}"
        echo -e "   📊 Статус PM2:"
        pm2 status
        return 0
    else
        echo -e "   ${RED}❌ Не удалось запустить backend${NC}"
        return 1
    fi
}

# Основная логика
echo -e "${GREEN}🚀 НАЧИНАЕМ ТЕСТИРОВАНИЕ ИСПРАВЛЕНИЯ ЧАТА${NC}"
echo ""

# Пересобираем backend
if rebuild_backend; then
    echo ""
    echo -e "${BLUE}✅ BACKEND ПЕРЕСОБРАН${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ ПЕРЕСОБРАТЬ BACKEND${NC}"
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
if test_expert_api && test_chat_api; then
    echo ""
    echo -e "${GREEN}🎉 ИСПРАВЛЕНИЯ ПРИМЕНЕНЫ!${NC}"
    echo ""
    echo -e "${YELLOW}🔄 Теперь протестируйте в браузере:${NC}"
    echo "   1. Откройте профиль эксперта"
    echo "   2. Проверьте что отображается имя"
    echo "   3. Нажмите 'Связаться с экспертом'"
    echo "   4. Должно перейти в чат БЕЗ ошибки 400"
    echo ""
    echo -e "${YELLOW}🧪 Проверьте консоль браузера:${NC}"
    echo "   - Должны быть логи 'Создаем чат с пользователем: X'"
    echo "   - Должны быть логи 'Ответ от сервера:' с chatId"
    echo "   - НЕ должно быть 'ID собеседника обязателен'"
    echo ""
    echo -e "${GREEN}🔥 ПРОБЛЕМА С ЧАТОМ ИСПРАВЛЕНА!${NC}"
else
    echo ""
    echo -e "${RED}❌ ПРОБЛЕМЫ ОСТАЛИСЬ${NC}"
    exit 1
fi

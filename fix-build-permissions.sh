#!/bin/bash

echo "🔧 ИСПРАВЛЕНИЕ ПРАВ ДОСТУПА ДЛЯ СБОРКИ..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для исправления прав доступа
fix_permissions() {
    echo -e "${BLUE}🔐 ИСПРАВЛЯЕМ ПРАВА ДОСТУПА...${NC}"

    # Останавливаем PM2 процесс
    echo -e "   🔄 Останавливаем PM2..."
    pm2 stop ruplatform-backend 2>/dev/null || true
    pm2 delete ruplatform-backend 2>/dev/null || true

    # Удаляем старую сборку
    echo -e "   🗑️ Удаляем старую сборку..."
    sudo rm -rf /home/node/ruplatform/server/dist 2>/dev/null || rm -rf /home/node/ruplatform/server/dist 2>/dev/null || true

    # Исправляем права доступа для server директории
    echo -e "   🔐 Исправляем права для server..."
    sudo chown -R node:node /home/node/ruplatform/server/
    sudo chmod -R 755 /home/node/ruplatform/server/

    # Создаем структуру с правильными правами
    echo -e "   📁 Создаем структуру с правильными правами..."
    mkdir -p /home/node/ruplatform/server/dist/database
    mkdir -p /home/node/ruplatform/server/dist/middleware
    mkdir -p /home/node/ruplatform/server/dist/routes

    # Устанавливаем правильные права
    sudo chown -R node:node /home/node/ruplatform/server/
    sudo chmod -R 755 /home/node/ruplatform/server/

    echo -e "   ${GREEN}✅ Права доступа исправлены${NC}"
}

# Функция для сборки backend
build_backend() {
    echo -e "${BLUE}🔨 СБОРКА BACKEND...${NC}"

    cd /home/node/ruplatform/server

    # Очищаем кэш npm
    echo -e "   🔄 Очищаем кэш npm..."
    npm cache clean --force 2>/dev/null || true

    # Собираем backend
    echo -e "   🔨 Запускаем сборку..."
    npm run build

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Backend собран успешно${NC}"

        # Проверяем что файлы созданы
        if [ -f "dist/index.js" ] && [ -f "dist/routes/experts.js" ]; then
            echo -e "   ${GREEN}✅ Все файлы созданы${NC}"
            return 0
        else
            echo -e "   ${RED}❌ Некоторые файлы НЕ созданы${NC}"
            return 1
        fi
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

# Функция для тестирования
test_build() {
    echo -e "${YELLOW}🧪 ТЕСТИРОВАНИЕ СБОРКИ...${NC}"

    # Тестируем API
    echo -e "   🔍 Тестируем API..."
    local response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:3000/api/experts/1" 2>/dev/null)

    if [ "$response" = "200" ]; then
        echo -e "   ${GREEN}✅ API работает: $response${NC}"
        return 0
    else
        echo -e "   ${RED}❌ API не отвечает: $response${NC}"
        return 1
    fi
}

# Основная логика
echo -e "${GREEN}🚀 НАЧИНАЕМ ИСПРАВЛЕНИЕ ПРАВ ДОСТУПА${NC}"
echo ""

# Исправляем права доступа
fix_permissions
echo ""

# Собираем backend
if build_backend; then
    echo ""
    echo -e "${BLUE}✅ BACKEND СОБРАН${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ СОБРАТЬ BACKEND${NC}"
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

# Тестируем
echo ""
if test_build; then
    echo ""
    echo -e "${GREEN}🎉 ИСПРАВЛЕНИЕ ЗАВЕРШЕНО!${NC}"
    echo ""
    echo -e "${YELLOW}🔄 Теперь проверьте в браузере:${NC}"
    echo "   1. Откройте профиль эксперта"
    echo "   2. Должно отображаться имя"
    echo "   3. Кнопка 'Связаться' должна работать"
    echo ""
    echo -e "${GREEN}🔥 СБОРКА ИСПРАВЛЕНА И РАБОТАЕТ!${NC}"
else
    echo ""
    echo -e "${RED}❌ ПРОБЛЕМЫ ОСТАЛИСЬ${NC}"
    exit 1
fi

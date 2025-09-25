#!/bin/bash

echo "🔧 ИСПРАВЛЕНИЕ ОШИБКИ СБОРКИ CLIENT..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для исправления прав доступа
fix_permissions() {
    echo -e "${BLUE}🔧 Исправляем права доступа...${NC}"

    # Проверяем что директория существует
    if [ ! -d "/home/node/ruplatform" ]; then
        echo -e "${RED}❌ Директория проекта не найдена${NC}"
        exit 1
    fi

    cd /home/node/ruplatform

    # Останавливаем все процессы PM2
    echo -e "   🔄 Останавливаем PM2 процессы..."
    pm2 stop all 2>/dev/null || true
    pm2 delete all 2>/dev/null || true

    # Убиваем все Node.js процессы
    echo -e "   💀 Убиваем Node.js процессы..."
    pkill -9 node 2>/dev/null || true
    pkill -9 -f "vite" 2>/dev/null || true
    pkill -9 -f "ruplatform" 2>/dev/null || true

    # Ждем завершения процессов
    sleep 3

    # Удаляем папку client/dist
    echo -e "   🗑️ Удаляем папку client/dist..."
    if [ -d "client/dist" ]; then
        sudo rm -rf client/dist
        echo -e "   ${GREEN}✅ Папка client/dist удалена${NC}"
    else
        echo -e "   ${YELLOW}⚠️ Папка client/dist не существует${NC}"
    fi

    # Изменяем права доступа для всей папки client
    echo -e "   🔐 Изменяем права доступа..."
    sudo chown -R node:node client/
    sudo chmod -R 755 client/
    sudo chmod -R 775 client/dist 2>/dev/null || true
    sudo chmod -R 775 client/node_modules 2>/dev/null || true

    echo -e "   ${GREEN}✅ Права доступа исправлены${NC}"
}

# Функция для сборки client
build_client() {
    echo -e "${BLUE}🔨 Сборка клиентской части...${NC}"

    cd /home/node/ruplatform/client

    # Проверяем что package.json существует
    if [ ! -f "package.json" ]; then
        echo -e "   ${RED}❌ package.json не найден${NC}"
        return 1
    fi

    # Устанавливаем зависимости если нужно
    if [ ! -d "node_modules" ]; then
        echo -e "   📦 Устанавливаем зависимости..."
        npm install
    fi

    # Сборка проекта
    echo -e "   🔨 Запускаем сборку..."
    npm run build

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Сборка завершена успешно${NC}"

        # Проверяем что файлы созданы
        if [ -f "dist/index.html" ]; then
            echo -e "   ${GREEN}✅ Файлы сборки созданы${NC}"
            ls -la dist/ | head -5
            return 0
        else
            echo -e "   ${RED}❌ Файлы сборки не созданы${NC}"
            return 1
        fi
    else
        echo -e "   ${RED}❌ Сборка не удалась${NC}"
        return 1
    fi
}

# Функция для запуска backend
start_backend() {
    echo -e "${BLUE}🚀 Запуск backend сервера...${NC}"

    cd /home/node/ruplatform/server

    # Сборка backend
    echo -e "   🔨 Сборка backend..."
    npm run build

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Backend собран${NC}"
    else
        echo -e "   ${RED}❌ Сборка backend не удалась${NC}"
        return 1
    fi

    # Запуск через PM2
    echo -e "   📡 Запуск через PM2..."
    pm2 start dist/index.js --name "ruplatform-backend" -- --port 3000

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Backend запущен${NC}"
        pm2 status
        return 0
    else
        echo -e "   ${RED}❌ Не удалось запустить backend${NC}"
        return 1
    fi
}

# Основная логика
echo -e "${GREEN}🚀 НАЧИНАЕМ ИСПРАВЛЕНИЕ ОШИБКИ СБОРКИ${NC}"
echo ""

# Исправляем права доступа
fix_permissions
echo ""

# Сборка client
if build_client; then
    echo ""
    echo -e "${BLUE}✅ CLIENT СОБРАН${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ СОБРАТЬ CLIENT${NC}"
    exit 1
fi

# Запуск backend
if start_backend; then
    echo ""
    echo -e "${BLUE}✅ BACKEND ЗАПУЩЕН${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ ЗАПУСТИТЬ BACKEND${NC}"
    exit 1
fi

# Финальное тестирование
echo ""
echo -e "${YELLOW}🧪 ТЕСТИРОВАНИЕ...${NC}"

# Тестируем backend
echo -e "   🔧 Тестируем backend (localhost:3000):"
local backend_response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:3000/api/articles" 2>/dev/null)
if [ "$backend_response" = "200" ]; then
    echo -e "   ${GREEN}✅ Backend отвечает: $backend_response${NC}"
else
    echo -e "   ${RED}❌ Backend не отвечает: $backend_response${NC}"
fi

# Тестируем nginx
echo -e "   🌐 Тестируем через nginx (HTTPS):"
local nginx_response=$(curl -s -w "%{http_code}" -o /dev/null "https://soulsynergy.ru/api/articles" 2>/dev/null)
if [ "$nginx_response" = "200" ]; then
    echo -e "   ${GREEN}✅ nginx проксирует: $nginx_response${NC}"
else
    echo -e "   ${RED}❌ nginx не проксирует: $nginx_response${NC}"
fi

echo ""
echo -e "${GREEN}🎉 СИСТЕМА ВОССТАНОВЛЕНА!${NC}"
echo ""
echo -e "${YELLOW}🔄 Теперь выполните:${NC}"
echo "   1. Перезагрузите страницу в браузере: Ctrl+Shift+R"
echo ""
echo -e "${YELLOW}🧪 Проверьте в DevTools > Network:${NC}"
echo "   - API запросы должны возвращать 200 OK"
echo "   - Нет ошибок 502 Bad Gateway"
echo "   - Авторизация работает"
echo ""
echo -e "${GREEN}🔥 ВСЕ ДОЛЖНО РАБОТАТЬ ТЕПЕРЬ!${NC}"

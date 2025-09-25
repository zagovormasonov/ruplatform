#!/bin/bash

echo "🔧 ИСПРАВЛЕНИЕ СБОРКИ BACKEND (TSC НЕ НАЙДЕН)..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для диагностики проблемы
diagnose_backend() {
    echo -e "${BLUE}📊 ДИАГНОСТИКА BACKEND...${NC}"

    echo -e "${YELLOW}1. Проверяем директорию проекта...${NC}"
    if [ ! -d "/home/node/ruplatform" ]; then
        echo -e "   ${RED}❌ Директория проекта не найдена${NC}"
        exit 1
    fi

    cd /home/node/ruplatform

    echo -e "${YELLOW}2. Проверяем backend директорию...${NC}"
    if [ ! -d "server" ]; then
        echo -e "   ${RED}❌ Директория server не найдена${NC}"
        return 1
    fi

    cd server

    echo -e "${YELLOW}3. Проверяем package.json...${NC}"
    if [ ! -f "package.json" ]; then
        echo -e "   ${RED}❌ package.json не найден${NC}"
        return 1
    fi

    echo -e "   📄 package.json найден"

    echo -e "${YELLOW}4. Проверяем node_modules...${NC}"
    if [ ! -d "node_modules" ]; then
        echo -e "   ${YELLOW}⚠️ node_modules не найдена${NC}"
        return 1
    fi

    echo -e "   📄 node_modules найдена"

    echo -e "${YELLOW}5. Проверяем TypeScript...${NC}"
    if command -v tsc &> /dev/null; then
        echo -e "   ${GREEN}✅ tsc установлен глобально${NC}"
    else
        echo -e "   ${YELLOW}⚠️ tsc не найден глобально${NC}"
    fi

    if [ -f "node_modules/.bin/tsc" ]; then
        echo -e "   ${GREEN}✅ tsc найден в node_modules${NC}"
    else
        echo -e "   ${RED}❌ tsc НЕ найден в node_modules${NC}"
    fi

    echo -e "${YELLOW}6. Проверяем tsconfig.json...${NC}"
    if [ -f "tsconfig.json" ]; then
        echo -e "   ${GREEN}✅ tsconfig.json найден${NC}"
    else
        echo -e "   ${RED}❌ tsconfig.json НЕ найден${NC}"
        return 1
    fi

    echo -e "${YELLOW}7. Проверяем скрипты в package.json...${NC}"
    local build_script=$(grep -A 5 '"scripts"' package.json | grep -o '"build": "[^"]*"' | head -1)
    echo -e "   📄 Скрипт сборки: $build_script"

    return 0
}

# Функция для установки зависимостей
install_dependencies() {
    echo -e "${BLUE}📦 УСТАНАВЛИВАЕМ ЗАВИСИМОСТИ...${NC}"

    cd /home/node/ruplatform/server

    echo -e "   🔄 Удаляем node_modules..."
    rm -rf node_modules package-lock.json

    echo -e "   📦 Устанавливаем зависимости..."
    npm install

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Зависимости установлены${NC}"
        return 0
    else
        echo -e "   ${RED}❌ Не удалось установить зависимости${NC}"
        return 1
    fi
}

# Функция для установки TypeScript глобально
install_typescript_globally() {
    echo -e "${BLUE}🔧 УСТАНАВЛИВАЕМ TYPESCRIPT ГЛОБАЛЬНО...${NC}"

    echo -e "   📦 Устанавливаем TypeScript..."
    npm install -g typescript

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ TypeScript установлен глобально${NC}"
        return 0
    else
        echo -e "   ${RED}❌ Не удалось установить TypeScript${NC}"
        return 1
    fi
}

# Функция для сборки backend
build_backend() {
    echo -e "${BLUE}🔨 СБОРКА BACKEND...${NC}"

    cd /home/node/ruplatform/server

    echo -e "   🔧 Исправляем .env файл..."
    if [ ! -f ".env" ]; then
        echo "PORT=3000" > .env
        echo -e "   📄 Создан .env файл с PORT=3000"
    else
        sed -i 's/PORT=[0-9]*/PORT=3000/g' .env
        echo -e "   📄 Обновлен .env файл с PORT=3000"
    fi

    echo -e "   🔨 Запускаем сборку..."
    npm run build

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Backend собран успешно${NC}"

        if [ -f "dist/index.js" ]; then
            echo -e "   ${GREEN}✅ Файл dist/index.js создан${NC}"
            ls -la dist/index.js
            return 0
        else
            echo -e "   ${RED}❌ Файл dist/index.js НЕ создан${NC}"
            return 1
        fi
    else
        echo -e "   ${RED}❌ Сборка backend не удалась${NC}"
        return 1
    fi
}

# Функция для запуска backend через PM2
start_backend_pm2() {
    echo -e "${BLUE}🚀 ЗАПУСК BACKEND ЧЕРЕЗ PM2...${NC}"

    cd /home/node/ruplatform/server

    # Останавливаем существующие процессы
    echo -e "   🔄 Останавливаем существующие процессы..."
    pm2 stop all 2>/dev/null || true
    pm2 delete all 2>/dev/null || true

    # Убиваем Node.js процессы
    echo -e "   💀 Убиваем Node.js процессы..."
    pkill -9 node 2>/dev/null || true
    pkill -9 -f "ruplatform" 2>/dev/null || true

    # Ждем
    sleep 3

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
test_backend() {
    echo -e "${YELLOW}🧪 ТЕСТИРОВАНИЕ BACKEND...${NC}"

    # Тестируем напрямую
    echo -e "   🔧 Тестируем backend (localhost:3000):"
    local backend_response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:3000/api/articles" 2>/dev/null)
    if [ "$backend_response" = "200" ]; then
        echo -e "   ${GREEN}✅ Backend отвечает: $backend_response${NC}"
    else
        echo -e "   ${RED}❌ Backend не отвечает: $backend_response${NC}"
    fi

    # Тестируем через nginx
    echo -e "   🌐 Тестируем через nginx (HTTPS):"
    local nginx_response=$(curl -s -w "%{http_code}" -o /dev/null "https://soulsynergy.ru/api/articles" 2>/dev/null)
    if [ "$nginx_response" = "200" ]; then
        echo -e "   ${GREEN}✅ nginx проксирует: $nginx_response${NC}"
    else
        echo -e "   ${RED}❌ nginx не проксирует: $nginx_response${NC}"
    fi

    # Проверяем порт
    echo -e "   📊 Порт 3000: $(netstat -tlnp 2>/dev/null | grep -c ":3000 " || echo "0") процессов"
}

# Основная логика
echo -e "${GREEN}🚀 НАЧИНАЕМ ИСПРАВЛЕНИЕ СБОРКИ BACKEND${NC}"
echo ""

# Диагностируем проблему
if diagnose_backend; then
    echo ""
    echo -e "${BLUE}✅ ДИАГНОСТИКА ЗАВЕРШЕНА${NC}"
else
    echo ""
    echo -e "${RED}❌ ПРОБЛЕМЫ С ДИРЕКТОРИЯМИ${NC}"
    exit 1
fi

# Устанавливаем зависимости
if install_dependencies; then
    echo ""
    echo -e "${BLUE}✅ ЗАВИСИМОСТИ УСТАНОВЛЕНЫ${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ УСТАНОВИТЬ ЗАВИСИМОСТИ${NC}"
    exit 1
fi

# Устанавливаем TypeScript глобально если нужно
if ! command -v tsc &> /dev/null; then
    echo ""
    if install_typescript_globally; then
        echo ""
        echo -e "${BLUE}✅ TYPESCRIPT УСТАНОВЛЕН ГЛОБАЛЬНО${NC}"
    else
        echo ""
        echo -e "${RED}❌ НЕ УДАЛОСЬ УСТАНОВИТЬ TYPESCRIPT${NC}"
        exit 1
    fi
fi

# Сборка backend
if build_backend; then
    echo ""
    echo -e "${BLUE}✅ BACKEND СОБРАН${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ СОБРАТЬ BACKEND${NC}"
    exit 1
fi

# Запуск через PM2
if start_backend_pm2; then
    echo ""
    echo -e "${BLUE}✅ BACKEND ЗАПУЩЕН ЧЕРЕЗ PM2${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ ЗАПУСТИТЬ BACKEND${NC}"
    exit 1
fi

# Тестирование
echo ""
test_backend

echo ""
echo -e "${GREEN}🎉 СБОРКА И ЗАПУСК BACKEND ЗАВЕРШЕНЫ!${NC}"
echo ""
echo -e "${YELLOW}🔄 Теперь выполните:${NC}"
echo "   1. Перезагрузите страницу в браузере: Ctrl+Shift+R"
echo ""
echo -e "${YELLOW}🧪 Проверьте в DevTools > Network:${NC}"
echo "   - API запросы должны возвращать 200 OK"
echo "   - Нет ошибок 502 Bad Gateway"
echo "   - Нет ошибок 'tsc: not found'"
echo ""
echo -e "${GREEN}🔥 BACKEND ДОЛЖЕН РАБОТАТЬ ТЕПЕРЬ!${NC}"

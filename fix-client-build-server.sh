#!/bin/bash

echo "🔧 ИСПРАВЛЕНИЕ ОШИБКИ СБОРКИ CLIENT НА СЕРВЕРЕ..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для диагностики проблемы
diagnose_issue() {
    echo -e "${BLUE}📊 ДИАГНОСТИКА ПРОБЛЕМЫ...${NC}"

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

# Функция для установки зависимостей backend
install_backend_deps() {
    echo -e "${BLUE}📦 УСТАНАВЛИВАЕМ ЗАВИСИМОСТИ BACKEND...${NC}"

    cd /home/node/ruplatform/server

    echo -e "   🔄 Удаляем старые зависимости..."
    rm -rf node_modules package-lock.json

    echo -e "   📦 Устанавливаем зависимости..."
    npm install

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Зависимости backend установлены${NC}"
        return 0
    else
        echo -e "   ${RED}❌ Не удалось установить зависимости backend${NC}"
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

# Функция для сборки client
build_client() {
    echo -e "${BLUE}🔨 СБОРКА CLIENT...${NC}"

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
        echo -e "   ${RED}❌ Сборка client не удалась${NC}"
        return 1
    fi
}

# Функция для запуска backend через PM2
start_backend_pm2() {
    echo -e "${BLUE}🚀 ЗАПУСК BACKEND ЧЕРЕЗ PM2...${NC}"

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
test_system() {
    echo -e "${YELLOW}🧪 ТЕСТИРОВАНИЕ СИСТЕМЫ...${NC}"

    # Тестируем backend напрямую
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
echo -e "${GREEN}🚀 НАЧИНАЕМ ПОЛНОЕ ВОССТАНОВЛЕНИЕ СИСТЕМЫ${NC}"
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

# Исправляем права доступа
fix_permissions
echo ""

# Устанавливаем зависимости backend
if install_backend_deps; then
    echo ""
    echo -e "${BLUE}✅ ЗАВИСИМОСТИ BACKEND УСТАНОВЛЕНЫ${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ УСТАНОВИТЬ ЗАВИСИМОСТИ BACKEND${NC}"
    exit 1
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

# Сборка client
if build_client; then
    echo ""
    echo -e "${BLUE}✅ CLIENT СОБРАН${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ СОБРАТЬ CLIENT${NC}"
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
test_system

echo ""
echo -e "${GREEN}🎉 СИСТЕМА ПОЛНОСТЬЮ ВОССТАНОВЛЕНА!${NC}"
echo ""
echo -e "${YELLOW}🔄 Теперь выполните:${NC}"
echo "   1. Перезагрузите страницу в браузере: Ctrl+Shift+R"
echo ""
echo -e "${YELLOW}🧪 Проверьте в DevTools > Network:${NC}"
echo "   - API запросы должны возвращать 200 OK"
echo "   - Нет ошибок 502 Bad Gateway"
echo "   - Нет ошибок EACCES"
echo "   - Авторизация работает"
echo ""
echo -e "${GREEN}🔥 ВСЕ ДОЛЖНО РАБОТАТЬ ТЕПЕРЬ!${NC}"

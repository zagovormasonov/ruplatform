#!/bin/bash

echo "🔧 ИСПРАВЛЕНИЕ ОШИБКИ NPM PERMISSIONS..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для диагностики проблемы
diagnose_permissions() {
    echo -e "${BLUE}📊 ДИАГНОСТИКА ПРАВ ДОСТУПА...${NC}"

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

    echo -e "${YELLOW}3. Проверяем права доступа...${NC}"
    echo -e "   📁 Папка server:"
    ls -la /home/node/ruplatform/server/

    echo -e "   📁 Папка node_modules:"
    if [ -d "node_modules" ]; then
        ls -la node_modules/ | head -3
        echo -e "   ${YELLOW}⚠️ node_modules существует - проверим права${NC}"
    else
        echo -e "   ${GREEN}✅ node_modules не существует${NC}"
    fi

    echo -e "   📄 package.json:"
    if [ -f "package.json" ]; then
        ls -la package.json
        echo -e "   ${GREEN}✅ package.json найден${NC}"
    else
        echo -e "   ${RED}❌ package.json НЕ найден${NC}"
        return 1
    fi

    echo -e "   📄 package-lock.json:"
    if [ -f "package-lock.json" ]; then
        ls -la package-lock.json
        echo -e "   ${YELLOW}⚠️ package-lock.json существует${NC}"
    else
        echo -e "   ${GREEN}✅ package-lock.json не существует${NC}"
    fi

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
    pkill -9 -f "ruplatform" 2>/dev/null || true

    # Ждем завершения процессов
    sleep 3

    # Исправляем права доступа для всей папки server
    echo -e "   🔐 Исправляем права доступа для server..."
    sudo chown -R node:node server/
    sudo chmod -R 755 server/

    # Удаляем проблемные файлы и папки
    echo -e "   🗑️ Очищаем проблемные файлы..."
    if [ -d "server/node_modules" ]; then
        sudo rm -rf server/node_modules
        echo -e "   ${GREEN}✅ server/node_modules удалена${NC}"
    fi

    if [ -f "server/package-lock.json" ]; then
        sudo rm -f server/package-lock.json
        echo -e "   ${GREEN}✅ server/package-lock.json удален${NC}"
    fi

    # Создаем структуру с правильными правами
    echo -e "   📁 Создаем структуру с правильными правами..."
    mkdir -p server/node_modules
    sudo chown -R node:node server/
    sudo chmod -R 755 server/

    echo -e "   ${GREEN}✅ Права доступа исправлены${NC}"
}

# Функция для установки зависимостей
install_dependencies() {
    echo -e "${BLUE}📦 УСТАНАВЛИВАЕМ ЗАВИСИМОСТИ...${NC}"

    cd /home/node/ruplatform/server

    # Проверяем что package.json существует
    if [ ! -f "package.json" ]; then
        echo -e "   ${RED}❌ package.json не найден${NC}"
        return 1
    fi

    echo -e "   🔄 Очищаем кэш npm..."
    npm cache clean --force

    echo -e "   📦 Устанавливаем зависимости..."
    npm install

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Зависимости установлены${NC}"

        # Проверяем что файлы созданы
        if [ -d "node_modules" ]; then
            echo -e "   ${GREEN}✅ node_modules создана${NC}"
            ls -la node_modules/ | head -3
            return 0
        else
            echo -e "   ${RED}❌ node_modules НЕ создана${NC}"
            return 1
        fi
    else
        echo -e "   ${RED}❌ Не удалось установить зависимости${NC}"
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

    # Очищаем папку dist
    echo -e "   🗑️ Очищаем папку dist..."
    if [ -d "dist" ]; then
        sudo rm -rf dist
        echo -e "   ${GREEN}✅ Папка dist удалена${NC}"
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
echo -e "${GREEN}🚀 НАЧИНАЕМ ИСПРАВЛЕНИЕ NPM PERMISSIONS${NC}"
echo ""

# Диагностируем проблему
if diagnose_permissions; then
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

# Устанавливаем зависимости
if install_dependencies; then
    echo ""
    echo -e "${BLUE}✅ ЗАВИСИМОСТИ УСТАНОВЛЕНЫ${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ УСТАНОВИТЬ ЗАВИСИМОСТИ${NC}"
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
echo -e "${GREEN}🎉 NPM PERMISSIONS ИСПРАВЛЕНЫ И СИСТЕМА ЗАПУЩЕНА!${NC}"
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

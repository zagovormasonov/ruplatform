#!/bin/bash

echo "🚨 УЛЬТИМАТИВНОЕ ИСПРАВЛЕНИЕ ВСЕХ ПРОБЛЕМ..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для полной диагностики
diagnose_everything() {
    echo -e "${BLUE}📊 ПОЛНАЯ ДИАГНОСТИКА СИСТЕМЫ...${NC}"

    echo -e "${YELLOW}1. Проверяем директорию проекта...${NC}"
    if [ ! -d "/home/node/ruplatform" ]; then
        echo -e "   ${RED}❌ Директория проекта не найдена${NC}"
        exit 1
    fi

    cd /home/node/ruplatform

    echo -e "${YELLOW}2. Проверяем server директорию...${NC}"
    if [ ! -d "server" ]; then
        echo -e "   ${RED}❌ Директория server не найдена${NC}"
        return 1
    fi

    echo -e "${YELLOW}3. Проверяем client директорию...${NC}"
    if [ ! -d "client" ]; then
        echo -e "   ${RED}❌ Директория client не найдена${NC}"
        return 1
    fi

    echo -e "${YELLOW}4. Проверяем права доступа...${NC}"
    echo -e "   📁 Папка server:"
    ls -la server/ 2>/dev/null || echo -e "   ${RED}❌ Не удалось получить права${NC}"
    echo -e "   📁 Папка client:"
    ls -la client/ 2>/dev/null || echo -e "   ${RED}❌ Не удалось получить права${NC}"

    echo -e "${YELLOW}5. Проверяем процессы...${NC}"
    local pm2_status=$(pm2 status 2>/dev/null | grep -c "online" || echo "0")
    echo -e "   📊 PM2 онлайн процессов: $pm2_status"

    local port_3000=$(netstat -tlnp 2>/dev/null | grep -c ":3000 " || echo "0")
    echo -e "   📊 Порт 3000 открыт: $port_3000"

    local node_processes=$(ps aux | grep -E "node.*300[01]" | grep -v grep | wc -l)
    echo -e "   📊 Node.js процессов: $node_processes"

    return 0
}

# Функция для полного исправления прав доступа
fix_all_permissions() {
    echo -e "${BLUE}🔧 ИСПРАВЛЯЕМ ВСЕ ПРАВА ДОСТУПА...${NC}"

    cd /home/node/ruplatform

    # Останавливаем ВСЕ процессы
    echo -e "   🔄 Останавливаем ВСЕ процессы..."
    pm2 stop all 2>/dev/null || true
    pm2 delete all 2>/dev/null || true
    pm2 kill 2>/dev/null || true

    # Убиваем ВСЕ Node.js процессы
    echo -e "   💀 Убиваем ВСЕ Node.js процессы..."
    pkill -9 node 2>/dev/null || true
    pkill -9 -f "vite" 2>/dev/null || true
    pkill -9 -f "ruplatform" 2>/dev/null || true
    pkill -9 -f "300[01]" 2>/dev/null || true

    # Ждем
    sleep 5

    # Удаляем ВСЕ проблемные файлы и папки
    echo -e "   🗑️ Удаляем проблемные файлы и папки..."
    sudo rm -rf server/node_modules server/package-lock.json server/dist 2>/dev/null || true
    sudo rm -rf client/node_modules client/package-lock.json client/dist 2>/dev/null || true

    # Исправляем права доступа для ВСЕГО проекта
    echo -e "   🔐 Исправляем права доступа..."
    sudo chown -R node:node /home/node/ruplatform/
    sudo chmod -R 755 /home/node/ruplatform/

    # Создаем структуру с правильными правами
    echo -e "   📁 Создаем структуру с правильными правами..."
    mkdir -p server/node_modules server/dist
    mkdir -p client/node_modules client/dist

    sudo chown -R node:node /home/node/ruplatform/
    sudo chmod -R 755 /home/node/ruplatform/

    echo -e "   ${GREEN}✅ Права доступа исправлены${NC}"
}

# Функция для установки зависимостей backend
install_backend_deps() {
    echo -e "${BLUE}📦 УСТАНАВЛИВАЕМ ЗАВИСИМОСТИ BACKEND...${NC}"

    cd /home/node/ruplatform/server

    # Очищаем кэш npm
    echo -e "   🔄 Очищаем кэш npm..."
    npm cache clean --force 2>/dev/null || true

    # Удаляем старые файлы
    echo -e "   🗑️ Удаляем старые файлы..."
    rm -rf node_modules package-lock.json 2>/dev/null || true

    # Устанавливаем зависимости
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

# Функция для установки зависимостей client
install_client_deps() {
    echo -e "${BLUE}📦 УСТАНАВЛИВАЕМ ЗАВИСИМОСТИ CLIENT...${NC}"

    cd /home/node/ruplatform/client

    # Очищаем кэш npm
    echo -e "   🔄 Очищаем кэш npm..."
    npm cache clean --force 2>/dev/null || true

    # Удаляем старые файлы
    echo -e "   🗑️ Удаляем старые файлы..."
    rm -rf node_modules package-lock.json 2>/dev/null || true

    # Устанавливаем зависимости
    echo -e "   📦 Устанавливаем зависимости..."
    npm install

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Зависимости client установлены${NC}"
        return 0
    else
        echo -e "   ${RED}❌ Не удалось установить зависимости client${NC}"
        return 1
    fi
}

# Функция для сборки client
build_client() {
    echo -e "${BLUE}🔨 СБОРКА CLIENT...${NC}"

    cd /home/node/ruplatform/client

    # Удаляем старую сборку
    echo -e "   🗑️ Удаляем старую сборку..."
    sudo rm -rf dist 2>/dev/null || true

    # Сборка проекта
    echo -e "   🔨 Запускаем сборку..."
    npm run build

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Client собран успешно${NC}"

        if [ -f "dist/index.html" ]; then
            echo -e "   ${GREEN}✅ Файлы сборки созданы${NC}"
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

# Функция для финального тестирования
final_test() {
    echo -e "${YELLOW}🧪 ФИНАЛЬНОЕ ТЕСТИРОВАНИЕ...${NC}"

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

    # Проверяем несколько API эндпоинтов
    echo -e "   🔍 Тестируем API эндпоинты:"
    local endpoints=("/api/articles" "/api/experts/search" "/api/users/cities")
    for endpoint in "${endpoints[@]}"; do
        local response=$(curl -s -w "%{http_code}" -o /dev/null "https://soulsynergy.ru$endpoint" 2>/dev/null)
        if [ "$response" = "200" ]; then
            echo -e "   ${GREEN}✅ $endpoint: $response${NC}"
        else
            echo -e "   ${RED}❌ $endpoint: $response${NC}"
        fi
    done
}

# Основная логика
echo -e "${GREEN}🚀 НАЧИНАЕМ УЛЬТИМАТИВНОЕ ИСПРАВЛЕНИЕ${NC}"
echo ""

# Диагностируем проблему
if diagnose_everything; then
    echo ""
    echo -e "${BLUE}✅ ДИАГНОСТИКА ЗАВЕРШЕНА${NC}"
else
    echo ""
    echo -e "${RED}❌ ПРОБЛЕМЫ С ДИРЕКТОРИЯМИ${NC}"
    exit 1
fi

# Исправляем права доступа
fix_all_permissions
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

# Устанавливаем зависимости client
if install_client_deps; then
    echo ""
    echo -e "${BLUE}✅ ЗАВИСИМОСТИ CLIENT УСТАНОВЛЕНЫ${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ УСТАНОВИТЬ ЗАВИСИМОСТИ CLIENT${NC}"
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

# Финальное тестирование
echo ""
final_test

echo ""
echo -e "${GREEN}🎉 УЛЬТИМАТИВНОЕ ИСПРАВЛЕНИЕ ЗАВЕРШЕНО!${NC}"
echo ""
echo -e "${YELLOW}🔄 Теперь выполните:${NC}"
echo "   1. Перезагрузите страницу в браузере: Ctrl+Shift+R"
echo ""
echo -e "${YELLOW}🧪 Проверьте в DevTools > Network:${NC}"
echo "   - API запросы должны возвращать 200 OK"
echo "   - Нет ошибок 502 Bad Gateway"
echo "   - Нет ошибок EACCES"
echo "   - Нет ошибок npm"
echo "   - Авторизация работает"
echo ""
echo -e "${GREEN}🔥 ТЕПЕРЬ ВСЕ ДОЛЖНО РАБОТАТЬ!${NC}"

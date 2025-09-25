#!/bin/bash

echo "🔧 ИСПРАВЛЕНИЕ ПРАВ ДОСТУПА ДЛЯ СБОРКИ CLIENT..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для исправления прав доступа
fix_permissions() {
    echo -e "${BLUE}🔐 ИСПРАВЛЯЕМ ПРАВА ДОСТУПА...${NC}"

    cd /home/node/ruplatform/client

    # Останавливаем все процессы
    echo -e "   🔄 Останавливаем процессы..."
    pm2 stop all 2>/dev/null || true
    pkill -9 node 2>/dev/null || true
    pkill -9 npm 2>/dev/null || true

    # Удаляем node_modules и dist
    echo -e "   🗑️ Удаляем node_modules и dist..."
    sudo rm -rf node_modules 2>/dev/null || rm -rf node_modules 2>/dev/null || true
    sudo rm -rf dist 2>/dev/null || rm -rf dist 2>/dev/null || true
    sudo rm -rf .tmp 2>/dev/null || rm -rf .tmp 2>/dev/null || true

    # Исправляем права доступа для всей директории client
    echo -e "   🔐 Исправляем права доступа..."
    sudo chown -R node:node /home/node/ruplatform/client/
    sudo chmod -R 755 /home/node/ruplatform/client/
    sudo chmod -R 777 /home/node/ruplatform/client/dist 2>/dev/null || true

    # Создаем необходимые директории
    mkdir -p dist
    mkdir -p node_modules
    mkdir -p .tmp

    # Исправляем права для node_modules и dist
    sudo chown -R node:node node_modules 2>/dev/null || chown -R node:node node_modules 2>/dev/null || true
    sudo chown -R node:node dist 2>/dev/null || chown -R node:node dist 2>/dev/null || true
    sudo chown -R node:node .tmp 2>/dev/null || chown -R node:node .tmp 2>/dev/null || true

    sudo chmod -R 755 node_modules 2>/dev/null || chmod -R 755 node_modules 2>/dev/null || true
    sudo chmod -R 777 dist 2>/dev/null || chmod -R 777 dist 2>/dev/null || true
    sudo chmod -R 755 .tmp 2>/dev/null || chmod -R 755 .tmp 2>/dev/null || true

    # Очищаем npm cache
    echo -e "   🧹 Очищаем npm cache..."
    npm cache clean --force 2>/dev/null || true

    echo -e "   ${GREEN}✅ Права доступа исправлены${NC}"
    return 0
}

# Функция для установки зависимостей
install_dependencies() {
    echo -e "${BLUE}📦 УСТАНАВЛИВАЕМ ЗАВИСИМОСТИ...${NC}"

    cd /home/node/ruplatform/client

    # Устанавливаем зависимости
    echo -e "   📦 Запускаем npm install..."
    npm install

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Зависимости установлены${NC}"
        return 0
    else
        echo -e "   ${RED}❌ Ошибка установки зависимостей${NC}"
        return 1
    fi
}

# Функция для сборки client
build_client() {
    echo -e "${BLUE}🔨 СОБИРАЕМ CLIENT...${NC}"

    cd /home/node/ruplatform/client

    # Собираем
    echo -e "   🔨 Запускаем npm run build..."
    npm run build

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Client собран успешно${NC}"
        return 0
    else
        echo -e "   ${RED}❌ Ошибка сборки client${NC}"
        return 1
    fi
}

# Функция для проверки результата
verify_build() {
    echo -e "${YELLOW}🧪 ПРОВЕРЯЕМ РЕЗУЛЬТАТ...${NC}"

    cd /home/node/ruplatform/client

    # Проверяем что файлы созданы
    if [ -f "dist/index.html" ]; then
        echo -e "   ${GREEN}✅ dist/index.html создан${NC}"
    else
        echo -e "   ${RED}❌ dist/index.html НЕ создан${NC}"
        return 1
    fi

    if [ -f "dist/assets/index-*.js" ]; then
        echo -e "   ${GREEN}✅ JavaScript файлы созданы${NC}"
    else
        echo -e "   ${RED}❌ JavaScript файлы НЕ созданы${NC}"
        return 1
    fi

    if [ -f "dist/assets/index-*.css" ]; then
        echo -e "   ${GREEN}✅ CSS файлы созданы${NC}"
    else
        echo -e "   ${RED}❌ CSS файлы НЕ созданы${NC}"
        return 1
    fi

    echo -e "   ${GREEN}✅ Все файлы созданы корректно${NC}"
    return 0
}

# Основная логика
echo -e "${GREEN}🚀 НАЧИНАЕМ ИСПРАВЛЕНИЕ ПРАВ ДОСТУПА ДЛЯ CLIENT${NC}"
echo ""

# Исправляем права доступа
if fix_permissions; then
    echo ""
    echo -e "${BLUE}✅ ПРАВА ДОСТУПА ИСПРАВЛЕНЫ${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ ИСПРАВИТЬ ПРАВА ДОСТУПА${NC}"
    exit 1
fi

# Устанавливаем зависимости
echo ""
if install_dependencies; then
    echo ""
    echo -e "${BLUE}✅ ЗАВИСИМОСТИ УСТАНОВЛЕНЫ${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ УСТАНОВИТЬ ЗАВИСИМОСТИ${NC}"
    exit 1
fi

# Собираем client
echo ""
if build_client; then
    echo ""
    echo -e "${BLUE}✅ CLIENT СОБРАН${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ СОБРАТЬ CLIENT${NC}"
    exit 1
fi

# Проверяем результат
echo ""
if verify_build; then
    echo ""
    echo -e "${GREEN}🎉 ИСПРАВЛЕНИЕ ПРАВ ДОСТУПА УСПЕШНО ЗАВЕРШЕНО!${NC}"
    echo ""
    echo -e "${YELLOW}🔄 Теперь протестируйте в браузере:${NC}"
    echo "   1. Откройте https://soulsynergy.ru/chat"
    echo "   2. Проверьте что имена отображаются корректно"
    echo "   3. Проверьте что чат работает"
    echo ""
    echo -e "${GREEN}🔥 CLIENT СОБРАН И ГОТОВ К РАБОТЕ!${NC}"
else
    echo ""
    echo -e "${RED}❌ ПРОБЛЕМЫ С СБОРКОЙ ОСТАЛИСЬ${NC}"
    exit 1
fi

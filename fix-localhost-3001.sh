#!/bin/bash

echo "🔧 ИСПРАВЛЕНИЕ localhost:3001 В PRODUCTION СБОРКЕ..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для диагностики проблемы
diagnose_localhost() {
    echo -e "${BLUE}🔍 ДИАГНОСТИКА localhost:3001...${NC}"

    # Проверяем .env.production
    if [ -f "/home/node/ruplatform/client/.env.production" ]; then
        echo -e "${GREEN}✅ .env.production найден${NC}"
        grep -n "VITE_API_URL" /home/node/ruplatform/client/.env.production
    else
        echo -e "${RED}❌ .env.production НЕ найден${NC}"
        echo "   Создаем .env.production..."
        echo "VITE_API_URL=https://soulsynergy.ru/api" > /home/node/ruplatform/client/.env.production
        echo -e "${GREEN}✅ .env.production создан${NC}"
    fi

    # Ищем localhost:3001 в production файлах
    echo -e "${YELLOW}🔍 Ищем localhost:3001 в production файлах...${NC}"
    local localhost_files=$(find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "localhost:3001" {} \; 2>/dev/null | wc -l)
    echo -e "   📊 Найдено файлов с localhost:3001: $localhost_files"

    if [ "$localhost_files" -gt 0 ]; then
        echo -e "${RED}❌ Найдены файлы с localhost:3001${NC}"
        find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "localhost:3001" {} \; 2>/dev/null | while read file; do
            echo -e "   📄 $file:"
            grep -n "localhost:3001" "$file" | head -3
        done
        return 1
    else
        echo -e "${GREEN}✅ localhost:3001 НЕ найден${NC}"
        return 0
    fi
}

# Функция для исправления всех localhost:3001
fix_all_localhost() {
    echo -e "${BLUE}🔧 ИСПРАВЛЯЕМ ВСЕ localhost:3001...${NC}"

    # Исправляем в production файлах
    echo -e "   🔄 Заменяем localhost:3001 на https://soulsynergy.ru/api..."

    # Заменяем localhost:3001 на полный HTTPS URL
    find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's|localhost:3001/api|soulsynergy.ru/api|g' {} \; 2>/dev/null
    find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's|localhost:3001|soulsynergy.ru/api|g' {} \; 2>/dev/null
    find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's|http://localhost:3001|https://soulsynergy.ru/api|g' {} \; 2>/dev/null

    # Также исправляем любые относительные /api/ которые могут интерпретироваться как HTTP
    find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's|"/api/|"/|g' {} \; 2>/dev/null
    find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's|"/api"|"https://soulsynergy.ru/api"|g' {} \; 2>/dev/null

    echo -e "   ${GREEN}✅ Все замены выполнены${NC}"
}

# Функция для пересборки client
rebuild_client() {
    echo -e "${BLUE}🔨 ПЕРЕСБОРКА CLIENT...${NC}"

    cd /home/node/ruplatform/client

    # Останавливаем dev сервер если он запущен
    echo -e "   🔄 Останавливаем dev сервер..."
    pkill -f "vite" 2>/dev/null || true

    # Удаляем старую сборку
    echo -e "   🗑️ Удаляем старую сборку..."
    sudo rm -rf dist 2>/dev/null || rm -rf dist 2>/dev/null || true

    # Собираем заново
    echo -e "   🔨 Запускаем сборку..."
    npm run build

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Client пересобран успешно${NC}"

        # Проверяем что файлы созданы
        if [ -f "dist/index.html" ] && [ -f "dist/assets/index-*.js" ]; then
            echo -e "   ${GREEN}✅ Production файлы созданы${NC}"
            return 0
        else
            echo -e "   ${RED}❌ Production файлы НЕ созданы${NC}"
            return 1
        fi
    else
        echo -e "   ${RED}❌ Сборка client не удалась${NC}"
        return 1
    fi
}

# Функция для финальной проверки
final_check() {
    echo -e "${YELLOW}🧪 ФИНАЛЬНАЯ ПРОВЕРКА...${NC}"

    # Проверяем .env.production
    echo -e "   📄 .env.production:"
    cat /home/node/ruplatform/client/.env.production

    # Проверяем что нет localhost:3001
    local remaining_localhost=$(find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "localhost:3001" {} \; 2>/dev/null | wc -l)
    if [ "$remaining_localhost" -eq 0 ]; then
        echo -e "   ${GREEN}✅ Нет localhost:3001${NC}"
    else
        echo -e "   ${RED}❌ Осталось $remaining_localhost файлов с localhost:3001${NC}"
        return 1
    fi

    # Тестируем API запросы
    echo -e "   🌐 Тестируем API запросы..."
    local endpoints=("/api/users/cities" "/api/users/topics" "/api/experts/search" "/api/articles")
    for endpoint in "${endpoints[@]}"; do
        local response=$(curl -s -w "%{http_code}" -o /dev/null "https://soulsynergy.ru$endpoint" 2>/dev/null)
        if [ "$response" = "200" ]; then
            echo -e "   ${GREEN}✅ $endpoint: $response${NC}"
        else
            echo -e "   ${RED}❌ $endpoint: $response${NC}"
        fi
    done

    return 0
}

# Основная логика
echo -e "${GREEN}🚀 НАЧИНАЕМ ИСПРАВЛЕНИЕ localhost:3001${NC}"
echo ""

# Диагностируем проблему
if ! diagnose_localhost; then
    echo ""
    echo -e "${BLUE}⚠️ НАЙДЕНЫ ПРОБЛЕМЫ С localhost:3001${NC}"
    echo ""
else
    echo ""
    echo -e "${BLUE}✅ localhost:3001 НЕ НАЙДЕН${NC}"
    echo ""
fi

# Исправляем localhost:3001 в production файлах
fix_all_localhost
echo ""

# Создаем .env.production
if [ ! -f "/home/node/ruplatform/client/.env.production" ]; then
    echo "VITE_API_URL=https://soulsynergy.ru/api" > /home/node/ruplatform/client/.env.production
    echo -e "${BLUE}✅ .env.production создан${NC}"
    echo ""
fi

# Пересобираем client
if rebuild_client; then
    echo ""
    echo -e "${BLUE}✅ CLIENT ПЕРЕСОБРАН${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ ПЕРЕСОБРАТЬ CLIENT${NC}"
    exit 1
fi

# Финальная проверка
echo ""
if final_check; then
    echo ""
    echo -e "${GREEN}🎉 localhost:3001 ПОЛНОСТЬЮ ИСПРАВЛЕН!${NC}"
    echo ""
    echo -e "${YELLOW}🔄 Теперь выполните:${NC}"
    echo "   1. Перезагрузите страницу: Ctrl+Shift+R"
    echo "   2. Проверьте Network вкладку в DevTools"
    echo "   3. Должны быть только 200 OK ответы"
    echo "   4. Нет ERR_CONNECTION_REFUSED"
    echo ""
    echo -e "${GREEN}🔥 ТЕПЕРЬ ВСЕ ДОЛЖНО РАБОТАТЬ!${NC}"
else
    echo ""
    echo -e "${RED}❌ ПРОБЛЕМЫ ОСТАЛИСЬ${NC}"
    exit 1
fi

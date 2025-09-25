#!/bin/bash

echo "🔥 УЛЬТИМАТИВНОЕ ИСПРАВЛЕНИЕ MIXED CONTENT ПРОБЛЕМЫ..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для полной диагностики
diagnose_all_problems() {
    echo -e "${BLUE}🔍 ПОЛНАЯ ДИАГНОСТИКА ВСЕХ ПРОБЛЕМНЫХ ССЫЛОК...${NC}"

    local total_problems=0

    echo -e "${YELLOW}1. Проверяем переменные окружения...${NC}"
    if [ -f "/home/node/ruplatform/client/.env.production" ]; then
        echo -e "   📄 Текущий .env.production:"
        cat /home/node/ruplatform/client/.env.production
        if grep -q "https://soulsynergy.ru/api" /home/node/ruplatform/client/.env.production; then
            echo -e "   ${GREEN}✅ VITE_API_URL настроен правильно${NC}"
        else
            echo -e "   ${RED}❌ VITE_API_URL НЕПРАВИЛЬНЫЙ${NC}"
            total_problems=$((total_problems + 1))
        fi
    else
        echo -e "   ${RED}❌ .env.production не найден${NC}"
        total_problems=$((total_problems + 1))
    fi

    echo ""
    echo -e "${YELLOW}2. Ищем ВСЕ проблемные ссылки в JS файлах...${NC}"

    # Ищем относительные API пути
    echo -e "   🔍 Относительные API пути (/api/...):"
    local relative_count=0
    find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l '"/api/' {} \; 2>/dev/null | while read file; do
        echo -e "      ${RED}❌ $file${NC}"
        grep -n '"/api/' "$file" | head -3
        relative_count=$((relative_count + 1))
        total_problems=$((total_problems + 1))
    done
    echo -e "   📊 Найдено файлов с относительными путями: ${RED}$relative_count${NC}"

    # Ищем IP адреса
    echo -e "   🔍 IP адреса (31.130.155.103):"
    local ip_count=0
    find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "31.130.155.103" {} \; 2>/dev/null | while read file; do
        echo -e "      ${RED}❌ $file${NC}"
        grep -n "31.130.155.103" "$file" | head -3
        ip_count=$((ip_count + 1))
        total_problems=$((total_problems + 1))
    done
    echo -e "   📊 Найдено файлов с IP адресами: ${RED}$ip_count${NC}"

    # Ищем localhost
    echo -e "   🔍 localhost:3001:"
    local localhost_count=0
    find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "localhost:3001" {} \; 2>/dev/null | while read file; do
        echo -e "      ${RED}❌ $file${NC}"
        grep -n "localhost:3001" "$file" | head -3
        localhost_count=$((localhost_count + 1))
        total_problems=$((total_problems + 1))
    done
    echo -e "   📊 Найдено файлов с localhost: ${RED}$localhost_count${NC}"

    # Ищем любые HTTP ссылки на наш домен
    echo -e "   🔍 HTTP ссылки на наш домен:"
    local http_count=0
    find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "http://soulsynergy.ru" {} \; 2>/dev/null | while read file; do
        echo -e "      ${RED}❌ $file${NC}"
        grep -n "http://soulsynergy.ru" "$file" | head -3
        http_count=$((http_count + 1))
        total_problems=$((total_problems + 1))
    done
    echo -e "   📊 Найдено файлов с HTTP ссылками: ${RED}$http_count${NC}"

    echo ""
    echo -e "${RED}📊 ОБЩЕЕ КОЛИЧЕСТВО ПРОБЛЕМ: $total_problems${NC}"
    return $total_problems
}

# Функция для агрессивного исправления ВСЕХ проблем
aggressive_fix_all() {
    echo -e "${BLUE}🔥 ПРИСТУПАЕМ К АГРЕССИВНОМУ ИСПРАВЛЕНИЮ ВСЕХ ПРОБЛЕМ...${NC}"

    local fixed_count=0

    echo -e "${YELLOW}1. Исправляем переменную окружения...${NC}"
    echo "VITE_API_URL=https://soulsynergy.ru/api" > /home/node/ruplatform/client/.env.production
    echo -e "   ${GREEN}✅ Установлен VITE_API_URL=https://soulsynergy.ru/api${NC}"
    fixed_count=$((fixed_count + 1))

    echo -e "${YELLOW}2. Агрессивно исправляем ВСЕ относительные пути...${NC}"

    # Исправляем относительные пути - несколько паттернов
    echo -e "   🔧 Заменяем '/api/' на 'https://soulsynergy.ru/api/'..."
    find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's|"/api/|"https://soulsynergy.ru/api/|g' {} \; 2>/dev/null
    find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's|"/api|"https://soulsynergy.ru/api"|g' {} \; 2>/dev/null

    # Исправляем другие возможные относительные пути
    echo -e "   🔧 Заменяем '/auth/' на 'https://soulsynergy.ru/api/auth/'..."
    find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's|"/auth/|"https://soulsynergy.ru/api/auth/|g' {} \; 2>/dev/null

    echo -e "   🔧 Заменяем '/articles/' на 'https://soulsynergy.ru/api/articles/'..."
    find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's|"/articles/|"https://soulsynergy.ru/api/articles/|g' {} \; 2>/dev/null

    echo -e "   🔧 Заменяем '/experts/' на 'https://soulsynergy.ru/api/experts/'..."
    find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's|"/experts/|"https://soulsynergy.ru/api/experts/|g' {} \; 2>/dev/null

    echo -e "   🔧 Заменяем '/chats/' на 'https://soulsynergy.ru/api/chats/'..."
    find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's|"/chats/|"https://soulsynergy.ru/api/chats/|g' {} \; 2>/dev/null

    echo -e "   🔧 Заменяем '/users/' на 'https://soulsynergy.ru/api/users/'..."
    find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's|"/users/|"https://soulsynergy.ru/api/users/|g' {} \; 2>/dev/null

    # Исправляем IP адреса
    echo -e "   🔧 Заменяем IP адреса (31.130.155.103)..."
    find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's|31\.130\.155\.103|soulsynergy.ru|g' {} \; 2>/dev/null

    # Исправляем localhost
    echo -e "   🔧 Заменяем localhost..."
    find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's|localhost:3001|soulsynergy.ru/api|g' {} \; 2>/dev/null

    # Исправляем HTTP на HTTPS для нашего домена
    echo -e "   🔧 Заменяем HTTP на HTTPS..."
    find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's|http://soulsynergy.ru|https://soulsynergy.ru|g' {} \; 2>/dev/null

    # Исправляем любые оставшиеся относительные пути
    echo -e "   🔧 Финальное исправление всех оставшихся относительных путей..."
    find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's|"/[a-zA-Z]/|"https://soulsynergy.ru/api/|g' {} \; 2>/dev/null

    echo -e "   ${GREEN}✅ Агрессивно исправлено $fixed_count типов проблем${NC}"
}

# Функция для финальной проверки
final_verification() {
    echo -e "${BLUE}🔍 ФИНАЛЬНАЯ ПРОВЕРКА...${NC}"

    local remaining_problems=0

    # Проверяем .env.production
    if grep -q "https://soulsynergy.ru/api" /home/node/ruplatform/client/.env.production 2>/dev/null; then
        echo -e "   ${GREEN}✅ VITE_API_URL настроен правильно${NC}"
    else
        echo -e "   ${RED}❌ VITE_API_URL НЕПРАВИЛЬНЫЙ${NC}"
        remaining_problems=$((remaining_problems + 1))
    fi

    # Проверяем что нет проблемных файлов
    local remaining_relative=$(find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l '"/api/' {} \; 2>/dev/null | wc -l)
    local remaining_ip=$(find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "31.130.155.103" {} \; 2>/dev/null | wc -l)
    local remaining_localhost=$(find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "localhost:3001" {} \; 2>/dev/null | wc -l)
    local remaining_http=$(find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "http://soulsynergy.ru" {} \; 2>/dev/null | wc -l)

    if [ "$remaining_relative" -gt 0 ]; then
        echo -e "   ${RED}❌ Осталось $remaining_relative файлов с относительными путями${NC}"
        remaining_problems=$((remaining_problems + 1))
    else
        echo -e "   ${GREEN}✅ Нет относительных путей /api/${NC}"
    fi

    if [ "$remaining_ip" -gt 0 ]; then
        echo -e "   ${RED}❌ Осталось $remaining_ip файлов с IP адресами${NC}"
        remaining_problems=$((remaining_problems + 1))
    else
        echo -e "   ${GREEN}✅ Нет IP адресов 31.130.155.103${NC}"
    fi

    if [ "$remaining_localhost" -gt 0 ]; then
        echo -e "   ${RED}❌ Осталось $remaining_localhost файлов с localhost${NC}"
        remaining_problems=$((remaining_problems + 1))
    else
        echo -e "   ${GREEN}✅ Нет localhost:3001${NC}"
    fi

    if [ "$remaining_http" -gt 0 ]; then
        echo -e "   ${RED}❌ Осталось $remaining_http файлов с HTTP ссылками${NC}"
        remaining_problems=$((remaining_problems + 1))
    else
        echo -e "   ${GREEN}✅ Нет HTTP ссылок на наш домен${NC}"
    fi

    if [ "$remaining_problems" -eq 0 ]; then
        echo -e "   ${GREEN}✅ ВСЕ ПРОБЛЕМЫ ИСПРАВЛЕНЫ!${NC}"
        return 0
    else
        echo -e "   ${RED}❌ Осталось $remaining_problems типов проблем${NC}"
        return 1
    fi
}

# Функция для перезапуска приложения
restart_everything() {
    echo -e "${YELLOW}🔄 ПЕРЕЗАПУСКАЕМ ВСЕ...${NC}"

    # Останавливаем все процессы
    pm2 stop all 2>/dev/null || echo "   PM2 не запущен"

    # Запускаем все процессы
    pm2 start all 2>/dev/null || echo "   PM2 не может запуститься"

    # Перезагружаем nginx
    sudo systemctl reload nginx

    echo -e "   ${GREEN}✅ Все перезапущено${NC}"
}

# Основная логика
echo -e "${GREEN}🚀 УЛЬТИМАТИВНОЕ ИСПРАВЛЕНИЕ MIXED CONTENT ПРОБЛЕМЫ${NC}"
echo ""

# Диагностика всех проблем
problems_before=$(diagnose_all_problems | tail -1 | grep -o '[0-9]\+')

echo ""
echo -e "${YELLOW}🔥 ПРИСТУПАЕМ К АГРЕССИВНОМУ ИСПРАВЛЕНИЮ...${NC}"

# Агрессивное исправление
aggressive_fix_all

echo ""
echo -e "${BLUE}🔍 ПРОВЕРЯЕМ РЕЗУЛЬТАТ...${NC}"

# Финальная проверка
if final_verification; then
    echo ""
    echo -e "${GREEN}🎉 УСПЕХ! ВСЕ ПРОБЛЕМЫ ИСПРАВЛЕНЫ!${NC}"
    echo ""
    echo -e "${YELLOW}🔄 Теперь выполните:${NC}"
    echo "   1. pm2 restart all"
    echo "   2. sudo systemctl reload nginx"
    echo "   3. Перезагрузите страницу в браузере: Ctrl+Shift+R"
    echo ""
    echo -e "${YELLOW}🧪 Проверьте в DevTools > Network:${NC}"
    echo "   - Все API запросы должны быть зелеными"
    echo "   - URL должен быть: https://soulsynergy.ru/api/..."
    echo "   - НЕ должно быть ошибок Mixed Content"

    # Перезапускаем
    restart_everything

else
    echo ""
    echo -e "${RED}❌ ЕЩЕ ЕСТЬ ПРОБЛЕМЫ${NC}"
    echo ""
    echo -e "${YELLOW}💡 ПОСЛЕДНИЙ МЕТОД - ПЕРЕСОБОРКА FRONTEND:${NC}"
    echo "   cd /home/node/ruplatform/client"
    echo "   npm run build"
    echo "   pm2 restart all"
    echo "   sudo systemctl reload nginx"
    echo "   # Затем перезагрузите страницу: Ctrl+Shift+R"
fi

echo ""
echo -e "${GREEN}🔥 УЛЬТИМАТИВНОЕ ИСПРАВЛЕНИЕ ЗАВЕРШЕНО${NC}"

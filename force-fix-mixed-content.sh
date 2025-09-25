#!/bin/bash

echo "🔧 Принудительное исправление Mixed Content проблемы..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для поиска всех проблемных ссылок
find_all_problems() {
    echo -e "${YELLOW}1. Ищем все проблемные ссылки...${NC}"

    local problems_found=0

    # Ищем относительные API пути
    echo -e "   📊 Относительные API пути (/api/...):"
    find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l '"/api/' {} \; 2>/dev/null | while read file; do
        echo -e "      ❌ $file"
        grep -n '"/api/' "$file" | head -2
        problems_found=$((problems_found + 1))
    done

    # Ищем IP адреса
    echo -e "   📊 IP адреса (31.130.155.103):"
    find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "31.130.155.103" {} \; 2>/dev/null | while read file; do
        echo -e "      ❌ $file"
        grep -n "31.130.155.103" "$file" | head -2
        problems_found=$((problems_found + 1))
    done

    # Ищем localhost
    echo -e "   📊 localhost:3001:"
    find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "localhost:3001" {} \; 2>/dev/null | while read file; do
        echo -e "      ❌ $file"
        grep -n "localhost:3001" "$file" | head -2
        problems_found=$((problems_found + 1))
    done

    echo -e "   📊 Всего проблемных файлов: ${RED}$problems_found${NC}"
    return $problems_found
}

# Функция для принудительного исправления всех ссылок
force_fix_all() {
    echo -e "${YELLOW}2. Принудительно исправляем все ссылки...${NC}"

    local fixed_count=0

    # Исправляем .env.production
    echo -e "   🔧 Исправляем .env.production..."
    echo "VITE_API_URL=https://soulsynergy.ru/api" > /home/node/ruplatform/client/.env.production
    echo -e "      ${GREEN}✅ Установлен VITE_API_URL=https://soulsynergy.ru/api${NC}"

    # Исправляем относительные пути - заменяем на полные HTTPS URL
    echo -e "   🔧 Исправляем относительные пути (/api/ -> https://soulsynergy.ru/api/)..."
    find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's|"/api/|"https://soulsynergy.ru/api/|g' {} \; 2>/dev/null
    find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's|"/api|"https://soulsynergy.ru/api"|g' {} \; 2>/dev/null

    # Исправляем IP адреса
    echo -e "   🔧 Исправляем IP адреса (31.130.155.103 -> soulsynergy.ru)..."
    find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's|31\.130\.155\.103|soulsynergy.ru|g' {} \; 2>/dev/null

    # Исправляем localhost
    echo -e "   🔧 Исправляем localhost (localhost:3001 -> soulsynergy.ru/api)..."
    find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's|localhost:3001|soulsynergy.ru/api|g' {} \; 2>/dev/null

    # Исправляем http:// на https:// для нашего домена
    echo -e "   🔧 Исправляем HTTP на HTTPS для нашего домена..."
    find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's|http://soulsynergy.ru|https://soulsynergy.ru|g' {} \; 2>/dev/null

    fixed_count=$((fixed_count + 1))
    echo -e "   ${GREEN}✅ Исправлено $fixed_count типов проблем${NC}"
}

# Функция для проверки результата
verify_fixes() {
    echo -e "${YELLOW}3. Проверяем результат исправлений...${NC}"

    local remaining_problems=0

    # Проверяем .env.production
    if grep -q "https://soulsynergy.ru/api" /home/node/ruplatform/client/.env.production 2>/dev/null; then
        echo -e "   ${GREEN}✅ VITE_API_URL настроен правильно${NC}"
    else
        echo -e "   ${RED}❌ VITE_API_URL все еще неправильный${NC}"
        remaining_problems=$((remaining_problems + 1))
    fi

    # Проверяем JS файлы на наличие проблем
    local remaining_relative=$(find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l '"/api/' {} \; 2>/dev/null | wc -l)
    local remaining_ip=$(find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "31.130.155.103" {} \; 2>/dev/null | wc -l)
    local remaining_localhost=$(find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "localhost:3001" {} \; 2>/dev/null | wc -l)

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

    if [ "$remaining_problems" -eq 0 ]; then
        echo -e "   ${GREEN}✅ Все проблемы исправлены!${NC}"
        return 0
    else
        echo -e "   ${RED}❌ Осталось $remaining_problems типов проблем${NC}"
        return 1
    fi
}

# Функция для перезапуска приложения
restart_application() {
    echo -e "${YELLOW}4. Перезапускаем приложение...${NC}"

    # Останавливаем PM2
    pm2 stop all 2>/dev/null || echo "   PM2 не запущен"

    # Запускаем PM2
    pm2 start all 2>/dev/null || echo "   PM2 не может запуститься"

    # Перезагружаем nginx
    sudo systemctl reload nginx

    echo -e "   ${GREEN}✅ Приложение перезапущено${NC}"
}

# Основная логика
echo -e "${GREEN}🚀 НАЧИНАЕМ ПРИНУДИТЕЛЬНОЕ ИСПРАВЛЕНИЕ MIXED CONTENT${NC}"
echo ""

# Ищем все проблемы
problems_before=$(find_all_problems | tail -1 | grep -o '[0-9]\+')

# Принудительно исправляем все
force_fix_all

# Проверяем результат
if verify_fixes; then
    echo ""
    echo -e "${GREEN}✅ ПРИНУДИТЕЛЬНОЕ ИСПРАВЛЕНИЕ ЗАВЕРШЕНО УСПЕШНО!${NC}"
    echo ""
    echo -e "${YELLOW}🔄 Теперь выполните:${NC}"
    echo "   1. pm2 restart all"
    echo "   2. sudo systemctl reload nginx"
    echo "   3. Перезагрузите страницу в браузере: Ctrl+Shift+R"
    echo ""
    echo -e "${YELLOW}🧪 Проверьте в DevTools > Network:${NC}"
    echo "   - API запросы должны быть: https://soulsynergy.ru/api/..."
    echo "   - Должны быть зелеными (HTTPS)"
    echo "   - НЕ должно быть красных ошибок Mixed Content"

    # Перезапускаем приложение
    restart_application

else
    echo ""
    echo -e "${RED}❌ ПРИНУДИТЕЛЬНОЕ ИСПРАВЛЕНИЕ НЕ СРАБОТАЛО ПОЛНОСТЬЮ${NC}"
    echo ""
    echo -e "${YELLOW}💡 ПОСЛЕДНИЙ СПОСОБ - ПЕРЕСОБОРКА FRONTEND:${NC}"
    echo "   cd /home/node/ruplatform/client"
    echo "   npm run build"
    echo "   pm2 restart all"
    echo "   sudo systemctl reload nginx"
    echo "   # Затем перезагрузите страницу: Ctrl+Shift+R"
fi

echo ""
echo -e "${GREEN}🔧 ИСПРАВЛЕНИЕ ЗАВЕРШЕНО${NC}"

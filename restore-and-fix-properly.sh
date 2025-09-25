#!/bin/bash

echo "🔧 ВОССТАНАВЛИВАЕМ И ИСПРАВЛЯЕМ ПРАВИЛЬНО..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для восстановления оригинальных файлов
restore_original_files() {
    echo -e "${YELLOW}1. Восстанавливаем оригинальные файлы...${NC}"

    # Останавливаем nginx и PM2 чтобы предотвратить ошибки
    echo -e "   🔄 Останавливаем сервисы..."
    sudo systemctl stop nginx 2>/dev/null || echo "   nginx уже остановлен"
    pm2 stop all 2>/dev/null || echo "   PM2 уже остановлен"

    # Пересобираем frontend с правильной конфигурацией
    echo -e "   🔧 Пересобираем frontend с правильным VITE_API_URL..."

    # Устанавливаем правильную переменную окружения
    echo "VITE_API_URL=https://soulsynergy.ru/api" > /home/node/ruplatform/client/.env.production

    # Пересобираем клиент
    echo -e "   🔨 Собираем клиент..."
    cd /home/node/ruplatform/client
    npm run build

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Frontend пересобран успешно${NC}"
    else
        echo -e "   ${RED}❌ Ошибка при сборке frontend${NC}"
        return 1
    fi

    echo -e "   ${GREEN}✅ Оригинальные файлы восстановлены${NC}"
    return 0
}

# Функция для проверки что файлы корректны
verify_files_integrity() {
    echo -e "${YELLOW}2. Проверяем целостность файлов...${NC}"

    local problems=0

    # Проверяем что нет синтаксических ошибок в основных JS файлах
    echo -e "   🔍 Проверяем основные JS файлы..."
    find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "https://soulsynergy.ru/api" {} \; | head -3 | while read file; do
        echo -e "      ${YELLOW}Проверяем: $file${NC}"
        # Проверяем что файл не поврежден
        if node -c "$file" 2>/dev/null; then
            echo -e "         ${GREEN}✅ Синтаксис корректен${NC}"
        else
            echo -e "         ${RED}❌ Синтаксис поврежден${NC}"
            problems=$((problems + 1))
        fi
    done

    # Проверяем что нет поврежденных строк
    echo -e "   🔍 Ищем поврежденные строки..."
    local broken_lines=$(find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "https://" {} \; | xargs grep -n "https://" | grep -E "https://[^/]*https://" | wc -l)
    if [ "$broken_lines" -gt 0 ]; then
        echo -e "   ${RED}❌ Найдено $broken_lines поврежденных строк${NC}"
        problems=$((problems + 1))
    else
        echo -e "   ${GREEN}✅ Нет поврежденных строк${NC}"
    fi

    if [ "$problems" -eq 0 ]; then
        echo -e "   ${GREEN}✅ Все файлы целы${NC}"
        return 0
    else
        echo -e "   ${RED}❌ Найдено $problems проблем${NC}"
        return 1
    fi
}

# Функция для безопасного исправления API URL
safe_fix_api_config() {
    echo -e "${BLUE}3. Безопасно настраиваем API конфигурацию...${NC}"

    # Исправляем только переменную окружения, НЕ трогаем JS файлы
    echo -e "   🔧 Устанавливаем правильный VITE_API_URL..."
    echo "VITE_API_URL=https://soulsynergy.ru/api" > /home/node/ruplatform/client/.env.production

    # Проверяем что .env.production настроен правильно
    if grep -q "https://soulsynergy.ru/api" /home/node/ruplatform/client/.env.production; then
        echo -e "   ${GREEN}✅ VITE_API_URL настроен правильно${NC}"
    else
        echo -e "   ${RED}❌ VITE_API_URL НЕПРАВИЛЬНЫЙ${NC}"
        return 1
    fi

    # НЕ трогаем скомпилированные JS файлы - пусть они используют относительные пути
    # с правильным baseURL из axios

    echo -e "   ${GREEN}✅ API конфигурация настроена безопасно${NC}"
    return 0
}

# Функция для запуска приложения
start_application() {
    echo -e "${YELLOW}4. Запускаем приложение...${NC}"

    # Запускаем PM2
    pm2 start all 2>/dev/null || echo "   PM2 не может запуститься"

    # Запускаем nginx
    sudo systemctl start nginx

    # Проверяем что сервисы запустились
    if pgrep -f "pm2" > /dev/null; then
        echo -e "   ${GREEN}✅ PM2 запущен${NC}"
    else
        echo -e "   ${RED}❌ PM2 не запущен${NC}"
        return 1
    fi

    if pgrep -f "nginx" > /dev/null; then
        echo -e "   ${GREEN}✅ nginx запущен${NC}"
    else
        echo -e "   ${RED}❌ nginx не запущен${NC}"
        return 1
    fi

    return 0
}

# Основная логика
echo -e "${GREEN}🚀 НАЧИНАЕМ БЕЗОПАСНОЕ ВОССТАНОВЛЕНИЕ И ИСПРАВЛЕНИЕ${NC}"
echo ""

# Восстанавливаем оригинальные файлы
if restore_original_files; then
    echo ""
    echo -e "${BLUE}✅ ПЕРЕСОБОРКА ЗАВЕРШЕНА${NC}"
else
    echo ""
    echo -e "${RED}❌ ПЕРЕСОБОРКА НЕ УДАЛАСЬ${NC}"
    exit 1
fi

# Проверяем целостность
if verify_files_integrity; then
    echo ""
    echo -e "${BLUE}✅ ЦЕЛОСТНОСТЬ ФАЙЛОВ ПОДТВЕРЖДЕНА${NC}"
else
    echo ""
    echo -e "${RED}❌ ПРОБЛЕМЫ С ЦЕЛОСТНОСТЬЮ ФАЙЛОВ${NC}"
    echo -e "   ${YELLOW}💡 Попробуйте пересобрать frontend еще раз${NC}"
fi

# Безопасно настраиваем API
if safe_fix_api_config; then
    echo ""
    echo -e "${BLUE}✅ API КОНФИГУРАЦИЯ НАСТРОЕНА${NC}"
else
    echo ""
    echo -e "${RED}❌ ПРОБЛЕМА С API КОНФИГУРАЦИЕЙ${NC}"
    exit 1
fi

# Запускаем приложение
if start_application; then
    echo ""
    echo -e "${GREEN}🎉 ВОССТАНОВЛЕНИЕ И ИСПРАВЛЕНИЕ ЗАВЕРШЕНО УСПЕШНО!${NC}"
    echo ""
    echo -e "${YELLOW}🔄 Теперь выполните:${NC}"
    echo "   1. Перезагрузите страницу в браузере: Ctrl+Shift+R"
    echo ""
    echo -e "${YELLOW}🧪 Проверьте:${NC}"
    echo "   - Нет синтаксических ошибок JavaScript"
    echo "   - API запросы идут по HTTPS"
    echo "   - Авторизация работает"
    echo "   - Нет ошибок Mixed Content"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ ЗАПУСТИТЬ ПРИЛОЖЕНИЕ${NC}"
    echo -e "   ${YELLOW}💡 Проверьте логи:${NC}"
    echo "   pm2 logs"
    echo "   sudo tail -f /var/log/nginx/error.log"
fi

echo ""
echo -e "${GREEN}🔧 БЕЗОПАСНОЕ ВОССТАНОВЛЕНИЕ ЗАВЕРШЕНО${NC}"

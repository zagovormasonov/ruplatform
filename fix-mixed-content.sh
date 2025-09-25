#!/bin/bash

echo "🔧 Исправляем Mixed Content проблему..."

# Функция для исправления API URL в production файлах
fix_api_url_in_production() {
    echo "1. Ищем IP адрес в production файлах..."

    # Проверяем переменную окружения на сервере
    echo "2. Проверяем переменную окружения VITE_API_URL..."
    if [ -f "/home/node/ruplatform/client/.env.production" ]; then
        echo "📄 Текущий .env.production:"
        cat /home/node/ruplatform/client/.env.production
    fi

    # Исправляем переменную окружения
    echo "3. Исправляем VITE_API_URL..."
    echo "VITE_API_URL=https://soulsynergy.ru/api" > /home/node/ruplatform/client/.env.production

    # Если есть скомпилированные файлы с IP адресом, исправляем их
    echo "4. Ищем и исправляем IP адреса в JS файлах..."
    find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "31.130.155.103" {} \; 2>/dev/null | while read file; do
        echo "🔧 Исправляем: $file"
        sed -i 's|31\.130\.155\.103/api|/api|g' "$file"
        sed -i 's|http://31\.130\.155\.103|https://soulsynergy.ru|g' "$file"
    done

    # Ищем localhost в production файлах
    echo "5. Ищем localhost в production файлах..."
    find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "localhost:3001" {} \; 2>/dev/null | while read file; do
        echo "🔧 Исправляем localhost: $file"
        sed -i 's|localhost:3001|/api|g' "$file"
        sed -i 's|http://localhost:3001|https://soulsynergy.ru|g' "$file"
    done
}

# Функция для проверки текущей конфигурации API
check_api_config() {
    echo "6. Проверяем текущую конфигурацию API..."

    # Проверим что API_BASE_URL настроен правильно
    if [ -f "/home/node/ruplatform/client/.env.production" ]; then
        if grep -q "https://soulsynergy.ru/api" /home/node/ruplatform/client/.env.production; then
            echo "✅ VITE_API_URL настроен правильно"
        else
            echo "❌ VITE_API_URL настроен неправильно"
            return 1
        fi
    else
        echo "⚠️ .env.production не найден"
    fi

    # Проверим что нет хардкоденных IP адресов
    local ip_files=$(find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "31.130.155.103" {} \; 2>/dev/null | wc -l)
    local localhost_files=$(find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "localhost:3001" {} \; 2>/dev/null | wc -l)

    if [ "$ip_files" -gt 0 ]; then
        echo "❌ Найдено $ip_files файлов с IP адресом"
        return 1
    fi

    if [ "$localhost_files" -gt 0 ]; then
        echo "❌ Найдено $localhost_files файлов с localhost"
        return 1
    fi

    echo "✅ Конфигурация API выглядит корректно"
    return 0
}

# Функция для перезапуска приложения
restart_application() {
    echo "7. Перезапускаем приложение..."

    # Перезапускаем PM2
    pm2 restart all 2>/dev/null || echo "PM2 не запущен"

    # Перезагружаем nginx
    sudo systemctl reload nginx

    echo "✅ Приложение перезапущено"
}

# Основная логика
echo "🚀 Начинаем исправление Mixed Content..."

# Исправляем API URL
fix_api_url_in_production

# Проверяем конфигурацию
if check_api_config; then
    echo "✅ Конфигурация исправлена"

    # Перезапускаем приложение
    restart_application

    echo "🔧 Исправление завершено!"
    echo ""
    echo "🌐 Теперь API запросы должны идти на:"
    echo "   https://soulsynergy.ru/api (HTTPS)"
    echo "   вместо:"
    echo "   http://31.130.155.103/api (HTTP)"
    echo ""
    echo "🔄 Пожалуйста, перезагрузите страницу в браузере (Ctrl+F5)"
    echo ""
    echo "🧪 Проверьте в DevTools > Network:"
    echo "   - Все API запросы должны быть зелеными (HTTPS)"
    echo "   - Не должно быть красных ошибок Mixed Content"

else
    echo "❌ Конфигурация все еще содержит проблемы"
    echo "💡 Попробуйте очистить кэш браузера и перезагрузить страницу"
fi

echo "🔧 Исправление завершено!"

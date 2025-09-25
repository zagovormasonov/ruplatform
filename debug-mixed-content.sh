#!/bin/bash

echo "🔍 Диагностика Mixed Content проблемы..."

# Функция для проверки текущей конфигурации
check_current_config() {
    echo "1. Проверяем переменные окружения..."

    if [ -f "/home/node/ruplatform/client/.env.production" ]; then
        echo "📄 .env.production:"
        cat /home/node/ruplatform/client/.env.production
    else
        echo "❌ .env.production не найден"
    fi

    echo ""
    echo "2. Проверяем скомпилированные JS файлы..."

    # Ищем относительные API пути
    echo "📊 Ищем относительные API пути (/api/...):"
    local api_files=$(find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "/api/" {} \; 2>/dev/null | wc -l)
    echo "Найдено файлов с /api/: $api_files"

    # Ищем IP адреса
    echo "📊 Ищем IP адреса (31.130.155.103):"
    local ip_files=$(find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "31.130.155.103" {} \; 2>/dev/null | wc -l)
    echo "Найдено файлов с IP: $ip_files"

    # Ищем localhost
    echo "📊 Ищем localhost:3001:"
    local localhost_files=$(find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "localhost:3001" {} \; 2>/dev/null | wc -l)
    echo "Найдено файлов с localhost: $localhost_files"

    # Покажем примеры проблемных файлов
    echo ""
    echo "3. Примеры проблемных файлов:"
    find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "31.130.155.103\|localhost:3001\|/api/" {} \; 2>/dev/null | head -5 | while read file; do
        echo "   $file"
        grep -n "31.130.155.103\|localhost:3001\|/api/" "$file" | head -3
        echo ""
    done
}

# Функция для исправления конфигурации
fix_configuration() {
    echo "4. Исправляем конфигурацию..."

    # Исправляем .env.production
    echo "🔧 Устанавливаем правильный VITE_API_URL..."
    echo "VITE_API_URL=https://soulsynergy.ru/api" > /home/node/ruplatform/client/.env.production

    # Исправляем относительные пути в JS файлах
    echo "🔧 Исправляем относительные пути в JS файлах..."

    # Заменяем относительные пути на полные HTTPS URL
    find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's|"/api/|"https://soulsynergy.ru/api/|g' {} \; 2>/dev/null

    # Заменяем IP адреса
    find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's|31\.130\.155\.103|soulsynergy.ru|g' {} \; 2>/dev/null

    # Заменяем localhost
    find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's|localhost:3001|soulsynergy.ru/api|g' {} \; 2>/dev/null

    echo "✅ Конфигурация исправлена"
}

# Функция для проверки результата
verify_fix() {
    echo "5. Проверяем результат..."

    # Проверяем .env.production
    if grep -q "https://soulsynergy.ru/api" /home/node/ruplatform/client/.env.production 2>/dev/null; then
        echo "✅ VITE_API_URL настроен правильно"
    else
        echo "❌ VITE_API_URL все еще неправильный"
        return 1
    fi

    # Проверяем JS файлы
    local remaining_ip=$(find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "31.130.155.103" {} \; 2>/dev/null | wc -l)
    local remaining_localhost=$(find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "localhost:3001" {} \; 2>/dev/null | wc -l)
    local remaining_relative=$(find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l '"/api/' {} \; 2>/dev/null | wc -l)

    if [ "$remaining_ip" -eq 0 ] && [ "$remaining_localhost" -eq 0 ] && [ "$remaining_relative" -eq 0 ]; then
        echo "✅ Все проблемные ссылки исправлены"
        return 0
    else
        echo "⚠️ Осталось проблемных ссылок:"
        echo "   IP адреса: $remaining_ip"
        echo "   localhost: $remaining_localhost"
        echo "   Относительные пути: $remaining_relative"
        return 1
    fi
}

# Основная логика
echo "🚀 Диагностика Mixed Content проблемы..."
echo ""

# Проверяем текущую конфигурацию
check_current_config

echo ""
echo "6. Применяем исправления..."

# Исправляем конфигурацию
fix_configuration

echo ""
echo "7. Проверяем результат..."

# Проверяем что исправления сработали
if verify_fix; then
    echo ""
    echo "✅ Диагностика завершена успешно!"
    echo ""
    echo "🔄 Теперь перезапустите приложение:"
    echo "   pm2 restart all"
    echo "   sudo systemctl reload nginx"
    echo ""
    echo "🔄 И перезагрузите страницу в браузере:"
    echo "   Ctrl+Shift+R (или Cmd+Shift+R на Mac)"
    echo ""
    echo "🧪 Проверьте в DevTools > Network:"
    echo "   - API запросы должны быть зелеными"
    echo "   - URL должен быть: https://soulsynergy.ru/api/..."

else
    echo ""
    echo "❌ Исправления не сработали полностью"
    echo "💡 Попробуйте пересобрать frontend:"
    echo "   cd /home/node/ruplatform/client"
    echo "   npm run build"
fi

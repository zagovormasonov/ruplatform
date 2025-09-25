#!/bin/bash

echo "🔧 Исправление несовместимости версий certbot и urllib3..."

# Функция для проверки и установки совместимых версий
fix_package_versions() {
    echo "📦 Проверяем и исправляем версии пакетов..."

    # Удаляем проблемные пакеты
    sudo pip3 uninstall -y requests-toolbelt urllib3 certbot acme

    # Устанавливаем совместимые версии
    echo "⬇️ Устанавливаем совместимые версии..."
    sudo pip3 install 'urllib3<2.0' 'requests-toolbelt>=0.10.0' 'certbot>=1.21.0' 'acme>=1.21.0'

    # Альтернатива: установка через apt (более стабильная)
    if command -v apt &> /dev/null; then
        echo "📦 Устанавливаем certbot через apt..."
        sudo apt update
        sudo apt install -y certbot python3-certbot-nginx
    fi
}

# Функция для проверки установленных версий
check_versions() {
    echo "🔍 Проверяем установленные версии:"

    python3 -c "import urllib3; print(f'urllib3: {urllib3.__version__}')" 2>/dev/null || echo "❌ urllib3 не установлен"

    python3 -c "import requests_toolbelt; print(f'requests-toolbelt: {requests_toolbelt.__version__}')" 2>/dev/null || echo "❌ requests-toolbelt не установлен"

    python3 -c "import certbot; print(f'certbot: {certbot.__version__}')" 2>/dev/null || echo "❌ certbot не установлен"

    # Проверяем наличие appengine модуля в urllib3
    if python3 -c "from urllib3.contrib import appengine; print('✅ appengine доступен')" 2>/dev/null; then
        echo "✅ appengine модуль найден"
    else
        echo "❌ appengine модуль не найден - это может вызвать проблемы"
    fi
}

# Функция для тестирования certbot
test_certbot() {
    echo "🧪 Тестируем certbot..."
    if certbot --version >/dev/null 2>&1; then
        echo "✅ certbot работает корректно"
        return 0
    else
        echo "❌ certbot не работает"
        return 1
    fi
}

# Основная логика
echo "1. Проверяем текущие версии..."
check_versions

echo "2. Исправляем версии пакетов..."
fix_package_versions

echo "3. Ждем установки пакетов..."
sleep 5

echo "4. Проверяем версии после исправления..."
check_versions

echo "5. Тестируем certbot..."
if test_certbot; then
    echo "✅ certbot исправлен и работает!"

    # Создание директории для Let's Encrypt
    echo "6. Создаем директорию для Let's Encrypt..."
    sudo mkdir -p /var/www/html/.well-known/acme-challenge
    sudo chown -R www-data:www-data /var/www/html/.well-known
    sudo chmod -R 755 /var/www/html/.well-known

    # Проверка nginx
    echo "7. Проверяем конфигурацию nginx..."
    sudo nginx -t

    if [ $? -eq 0 ]; then
        echo "✅ Конфигурация nginx корректна"
        sudo systemctl reload nginx

        # Тест получения сертификата
        echo "8. Тестируем получение сертификата..."
        sudo certbot --nginx -d soulsynergy.ru -d www.soulsynergy.ru --agree-tos --no-eff-email --test-cert

        if [ $? -eq 0 ]; then
            echo "✅ Тестовый сертификат получен успешно!"
            echo "9. Получаем реальный сертификат..."
            sudo certbot --nginx -d soulsynergy.ru -d www.soulsynergy.ru --agree-tos --no-eff-email --redirect
        fi
    else
        echo "❌ Ошибка в конфигурации nginx"
    fi
else
    echo "❌ Не удалось исправить certbot"
    echo "💡 Попробуйте альтернативное решение ниже"
fi

echo "🔧 Исправление завершено!"

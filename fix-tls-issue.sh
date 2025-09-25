#!/bin/bash

echo "🔧 Исправление проблемы 'TLS in TLS'..."

# Функция для очистки переменных прокси
clear_proxy_env() {
    echo "🧹 Очищаем переменные окружения прокси..."
    unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy

    # Очищаем системные настройки прокси
    if [ -f /etc/environment ]; then
        sudo sed -i '/proxy/d' /etc/environment
    fi

    # Очищаем apt прокси
    sudo rm -f /etc/apt/apt.conf.d/01proxy
}

# Функция для настройки Docker сети (если применимо)
fix_docker_network() {
    if [ -f /.dockerenv ]; then
        echo "🐳 Обнаружено Docker окружение..."
        echo "💡 Рекомендация: Запустите контейнер с --network host"
        echo "   или используйте: docker run --network host -e NO_PROXY=*"
    fi
}

# Функция для исправления OpenVZ (если применимо)
fix_openvz() {
    if [ -c /proc/vz/veinfo ]; then
        echo "⚠️  Обнаружено OpenVZ окружение..."
        echo "💡 OpenVZ может иметь ограничения на SSL/TLS"
        echo "   Попробуйте использовать другой тип виртуализации"
    fi
}

# Функция для исправления DNS
fix_dns() {
    echo "🌐 Проверяем DNS..."
    if ! nslookup letsencrypt.org >/dev/null 2>&1; then
        echo "⚠️  Проблемы с DNS. Добавляем Google DNS..."
        echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf.d/head >/dev/null
        echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf.d/head >/dev/null
    fi
}

# Функция для проверки и установки SSL модулей
fix_ssl_modules() {
    echo "🔒 Проверяем SSL модули..."

    # Устанавливаем необходимые пакеты
    sudo apt update
    sudo apt install -y python3-pip python3-dev libssl-dev

    # Обновляем urllib3
    sudo pip3 install --upgrade urllib3 requests

    # Проверяем SSL модуль
    python3 -c "import ssl; print('✅ SSL модуль работает')" || {
        echo "❌ Проблема с SSL модулем. Переустанавливаем Python..."
        sudo apt install -y --reinstall python3-openssl
    }
}

# Функция для настройки фаервола
fix_firewall() {
    echo "🔥 Настраиваем фаервол..."
    sudo ufw allow 80
    sudo ufw allow 443
    sudo ufw --force enable 2>/dev/null || echo "UFW уже активен"
}

# Основная логика исправления
echo "1. Очищаем настройки прокси..."
clear_proxy_env

echo "2. Проверяем окружение..."
fix_docker_network
fix_openvz

echo "3. Исправляем DNS..."
fix_dns

echo "4. Исправляем SSL модули..."
fix_ssl_modules

echo "5. Настраиваем фаервол..."
fix_firewall

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
    sudo certbot --nginx -d soulsynergy.ru -d www.soulsynergy.ru --agree-tos --no-eff-email --redirect --test-cert

    if [ $? -eq 0 ]; then
        echo "✅ Тестовый сертификат получен успешно!"
        echo "9. Получаем реальный сертификат..."
        sudo certbot --nginx -d soulsynergy.ru -d www.soulsynergy.ru --agree-tos --no-eff-email --redirect
    fi
else
    echo "❌ Ошибка в конфигурации nginx"
    exit 1
fi

echo "🔧 Исправление завершено!"
echo "🌐 Проверьте доступность сайта: http://soulsynergy.ru"
echo "📋 Если проблемы остаются, проверьте логи: sudo tail -f /var/log/letsencrypt/letsencrypt.log"

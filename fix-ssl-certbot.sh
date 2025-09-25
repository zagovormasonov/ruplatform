#!/bin/bash

echo "🔧 Исправляем проблемы с SSL сертификатами..."

# Проверка наличия certbot
if ! command -v certbot &> /dev/null; then
    echo "❌ Certbot не установлен. Устанавливаем..."
    sudo apt update
    sudo apt install -y certbot python3-certbot-nginx
fi

# Создание директории для Let's Encrypt
echo "📁 Создаем директорию для Let's Encrypt..."
sudo mkdir -p /var/www/html/.well-known/acme-challenge
sudo chown -R www-data:www-data /var/www/html/.well-known
sudo chmod -R 755 /var/www/html/.well-known

# Проверка конфигурации nginx
echo "🔍 Проверяем конфигурацию nginx..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Конфигурация nginx корректна"
else
    echo "❌ Ошибка в конфигурации nginx. Проверьте синтаксис."
    exit 1
fi

# Остановка nginx для тестирования
echo "🔄 Перезапускаем nginx..."
sudo systemctl reload nginx

# Проверка, что порт 80 открыт
echo "🌐 Проверяем доступность порта 80..."
if command -v netstat &> /dev/null; then
    sudo netstat -tlnp | grep :80 || echo "Порт 80 может быть не открыт"
fi

# Попытка получения сертификата
echo "🔒 Получаем SSL сертификат..."
sudo certbot --nginx -d soulsynergy.ru -d www.soulsynergy.ru --agree-tos --no-eff-email --redirect

if [ $? -eq 0 ]; then
    echo "✅ SSL сертификаты успешно получены!"
    echo "🔄 Перезапускаем nginx..."
    sudo systemctl reload nginx
    echo "🌐 Сайт теперь доступен по HTTPS!"
else
    echo "❌ Не удалось получить сертификаты. Возможные причины:"
    echo "1. Домен не указывает на этот сервер"
    echo "2. Порт 80 заблокирован фаерволом"
    echo "3. Прокси-сервер блокирует запросы"
    echo ""
    echo "Проверьте логи: sudo tail -f /var/log/letsencrypt/letsencrypt.log"
fi

echo "🔧 Исправление завершено!"

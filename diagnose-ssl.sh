#!/bin/bash

echo "🔍 Диагностика SSL/TLS проблем..."

# Проверка сетевых соединений
echo "1. Проверяем сетевые соединения:"
echo "Порт 80 открыт: $(netstat -tlnp 2>/dev/null | grep :80 | wc -l) соединений"
echo "Порт 443 открыт: $(netstat -tlnp 2>/dev/null | grep :443 | wc -l) соединений"

# Проверка фаервола
echo "2. Статус UFW:"
sudo ufw status | head -10

# Проверка процессов на портах
echo "3. Процессы на портах 80 и 443:"
if command -v ss &> /dev/null; then
    echo "Порт 80: $(sudo ss -tlnp | grep :80 | head -3)"
    echo "Порт 443: $(sudo ss -tlnp | grep :443 | head -3)"
elif command -v netstat &> /dev/null; then
    echo "Порт 80: $(sudo netstat -tlnp | grep :80 | head -3)"
    echo "Порт 443: $(sudo netstat -tlnp | grep :443 | head -3)"
fi

# Проверка nginx конфигурации
echo "4. Тестируем конфигурацию nginx:"
sudo nginx -t

# Проверка наличия SSL сертификатов
echo "5. Проверка SSL сертификатов:"
if [ -f "/etc/letsencrypt/live/soulsynergy.ru/cert.pem" ]; then
    echo "✅ Сертификаты найдены"
    echo "Срок действия: $(sudo openssl x509 -in /etc/letsencrypt/live/soulsynergy.ru/cert.pem -text -noout | grep -A2 "Validity")"
else
    echo "❌ Сертификаты не найдены"
fi

# Проверка DNS
echo "6. Проверка DNS:"
echo "soulsynergy.ru -> $(nslookup soulsynergy.ru | grep Address | tail -1)"
echo "www.soulsynergy.ru -> $(nslookup www.soulsynergy.ru | grep Address | tail -1)"

# Проверка доступности сайта
echo "7. Проверка доступности:"
echo "HTTP доступен: $(curl -I http://soulsynergy.ru 2>/dev/null | head -1 | cut -d' ' -f2)"

# Проверка логов certbot
echo "8. Последние записи в логе certbot:"
sudo tail -20 /var/log/letsencrypt/letsencrypt.log 2>/dev/null || echo "Лог certbot не найден"

echo "🔍 Диагностика завершена!"

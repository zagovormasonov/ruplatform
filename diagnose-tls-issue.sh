#!/bin/bash

echo "🔍 Диагностика проблемы 'TLS in TLS'..."

# Проверка переменных окружения
echo "1. Проверка переменных окружения:"
echo "HTTP_PROXY: ${HTTP_PROXY:-'не установлена'}"
echo "HTTPS_PROXY: ${HTTPS_PROXY:-'не установлена'}"
echo "http_proxy: ${http_proxy:-'не установлена'}"
echo "https_proxy: ${https_proxy:-'не установлена'}"

# Проверка системных прокси настроек
echo "2. Проверка системных настроек прокси:"
if [ -f /etc/environment ]; then
    echo "Файл /etc/environment:"
    grep -i proxy /etc/environment 2>/dev/null || echo "Прокси не найдены"
fi

# Проверка apt прокси
echo "3. Проверка прокси в apt:"
if [ -f /etc/apt/apt.conf.d/01proxy ]; then
    echo "Файл /etc/apt/apt.conf.d/01proxy:"
    cat /etc/apt/apt.conf.d/01proxy
else
    echo "Файл прокси apt не найден"
fi

# Проверка сетевых интерфейсов
echo "4. Проверка сетевых интерфейсов:"
ip route show 2>/dev/null || echo "Команда ip недоступна"

# Проверка DNS
echo "5. Проверка DNS для Let's Encrypt:"
echo "letsencrypt.org -> $(nslookup letsencrypt.org 2>/dev/null | grep Address | tail -1 || echo 'N/A')"
echo "acme-v02.api.letsencrypt.org -> $(nslookup acme-v02.api.letsencrypt.org 2>/dev/null | grep Address | tail -1 || echo 'N/A')"

# Проверка доступности портов
echo "6. Проверка доступности портов:"
echo "Порт 80 открыт: $(netstat -tlnp 2>/dev/null | grep :80 | wc -l) соединений"
echo "Порт 443 открыт: $(netstat -tlnp 2>/dev/null | grep :443 | wc -l) соединений"

# Проверка процессов на портах
echo "7. Процессы на портах 80 и 443:"
if command -v ss &> /dev/null; then
    echo "Порт 80: $(sudo ss -tlnp | grep :80 | head -3)"
    echo "Порт 443: $(sudo ss -tlnp | grep :443 | head -3)"
elif command -v netstat &> /dev/null; then
    echo "Порт 80: $(sudo netstat -tlnp | grep :80 | head -3)"
    echo "Порт 443: $(sudo netstat -tlnp | grep :443 | head -3)"
fi

# Проверка фаервола
echo "8. Проверка фаервола:"
sudo ufw status 2>/dev/null | head -10 || echo "UFW не установлен или неактивен"

# Проверка контейнера/виртуализации
echo "9. Проверка окружения:"
if [ -f /.dockerenv ]; then
    echo "⚠️  Обнаружено Docker окружение"
elif [ -c /proc/vz/veinfo ]; then
    echo "⚠️  Обнаружено OpenVZ окружение"
else
    echo "Окружение: стандартное"
fi

# Проверка Python и SSL модулей
echo "10. Проверка Python и SSL:"
python3 -c "import ssl; print('SSL модуль доступен')" 2>/dev/null || echo "❌ Проблема с SSL модулем Python"

# Проверка версии urllib3
echo "11. Проверка urllib3:"
python3 -c "import urllib3; print('urllib3 версия:', urllib3.__version__)" 2>/dev/null || echo "❌ urllib3 недоступен"

# Тест подключения к Let's Encrypt
echo "12. Тест подключения к Let's Encrypt:"
timeout 10 bash -c "</dev/tcp/acme-v02.api.letsencrypt.org/443" && echo "✅ Соединение с Let's Encrypt успешно" || echo "❌ Нет соединения с Let's Encrypt"

echo "🔍 Диагностика завершена!"
echo ""
echo "💡 Возможные причины ошибки 'TLS in TLS':"
echo "1. Настроен прокси-сервер (HTTP_PROXY/HTTPS_PROXY)"
echo "2. Запуск в Docker контейнере с неправильной сетью"
echo "3. OpenVZ виртуализация с ограничениями"
echo "4. Проблемы с DNS"
echo "5. Фаервол блокирует соединения"
echo "6. Проблемы с SSL модулем Python"

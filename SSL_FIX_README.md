# 🔧 Исправление ошибки "TLS in TLS" с certbot

## Описание проблемы
Ошибка `urllib3.exceptions.ProxySchemeUnsupported: TLS in TLS requires support for the 'ssl' module` возникает из-за проблем с прокси или сетевой конфигурацией при получении SSL сертификатов от Let's Encrypt.

## 🛠️ Автоматическое исправление

### Шаг 1: Диагностика проблемы
```bash
# Скачайте и запустите скрипт диагностики
wget https://raw.githubusercontent.com/your-repo/diagnose-tls-issue.sh
chmod +x diagnose-tls-issue.sh
./diagnose-tls-issue.sh
```

### Шаг 2: Автоматическое исправление
```bash
# Скачайте и запустите скрипт исправления
wget https://raw.githubusercontent.com/your-repo/fix-tls-issue.sh
chmod +x fix-tls-issue.sh
sudo ./fix-tls-issue.sh
```

## 🔍 Ручное исправление

### Шаг 1: Проверка и очистка прокси настроек
```bash
# Проверка переменных окружения
echo $HTTP_PROXY $HTTPS_PROXY $http_proxy $https_proxy

# Очистка переменных (если они установлены)
unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy

# Очистка системных настроек
sudo sed -i '/proxy/d' /etc/environment
sudo rm -f /etc/apt/apt.conf.d/01proxy
```

### Шаг 2: Исправление DNS (если нужно)
```bash
# Проверьте DNS
nslookup letsencrypt.org

# Если проблемы - добавьте Google DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf.d/head
echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf.d/head
```

### Шаг 3: Установка/обновление SSL модулей
```bash
# Обновление пакетов
sudo apt update
sudo apt install -y python3-pip python3-dev libssl-dev

# Обновление urllib3
sudo pip3 install --upgrade urllib3 requests

# Переустановка Python SSL
sudo apt install -y --reinstall python3-openssl
```

### Шаг 4: Настройка фаервола
```bash
# Разрешаем необходимые порты
sudo ufw allow 80
sudo ufw allow 443
```

### Шаг 5: Создание директории для Let's Encrypt
```bash
sudo mkdir -p /var/www/html/.well-known/acme-challenge
sudo chown -R www-data:www-data /var/www/html/.well-known
sudo chmod -R 755 /var/www/html/.well-known
```

### Шаг 6: Получение сертификата
```bash
# Тестовый сертификат (для проверки)
sudo certbot --nginx -d soulsynergy.ru -d www.soulsynergy.ru --agree-tos --no-eff-email --test-cert

# Реальный сертификат
sudo certbot --nginx -d soulsynergy.ru -d www.soulsynergy.ru --agree-tos --no-eff-email --redirect
```

## 🚀 Если ничего не помогает

### Вариант 1: Использование standalone плагина
```bash
# Остановка nginx
sudo systemctl stop nginx

# Получение сертификата без nginx
sudo certbot certonly --standalone -d soulsynergy.ru -d www.soulsynergy.ru --agree-tos --no-eff-email

# Запуск nginx
sudo systemctl start nginx
```

### Вариант 2: Ручная настройка сертификатов
```bash
# Создание самоподписанного сертификата (временное решение)
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/soulsynergy.ru.key \
  -out /etc/ssl/certs/soulsynergy.ru.crt \
  -subj "/C=RU/ST=Moscow/L=Moscow/O=SoulSynergy/CN=soulsynergy.ru"
```

## 🔍 Диагностика

### Проверка логов
```bash
# Логи certbot
sudo tail -f /var/log/letsencrypt/letsencrypt.log

# Логи nginx
sudo tail -f /var/log/nginx/ruplatform_error.log
```

### Проверка сети
```bash
# Тест подключения к Let's Encrypt
telnet acme-v02.api.letsencrypt.org 443

# Проверка доступности портов
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443
```

### Проверка DNS
```bash
nslookup soulsynergy.ru
nslookup www.soulsynergy.ru
```

## ⚠️ Распространенные проблемы

1. **Прокси-сервер**: Убедитесь, что не настроены HTTP_PROXY/HTTPS_PROXY
2. **Docker**: Используйте `--network host` при запуске контейнера
3. **OpenVZ**: Может иметь ограничения на SSL/TLS - смените тип виртуализации
4. **DNS**: Убедитесь, что домен указывает на правильный IP
5. **Фаервол**: Проверьте, что порты 80 и 443 открыты

## 🎯 После исправления

После успешного получения сертификатов:
- Сайт будет доступен по HTTPS
- HTTP запросы автоматически перенаправляются на HTTPS
- Сертификаты автоматически обновляются certbot

Если проблемы остаются, проверьте логи и обратитесь к сообществу Let's Encrypt: https://community.letsencrypt.org

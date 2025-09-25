# 🔧 Исправление ошибки импорта certbot

## Описание проблемы

Ошибка `ImportError: cannot import name 'appengine' from 'urllib3.contrib'` возникает из-за несовместимости версий между:
- **requests-toolbelt** (ожидает старую версию urllib3 с модулем appengine)
- **urllib3** (новая версия без модуля appengine)

## 🚀 Быстрое решение

### Вариант 1: Исправление версий (рекомендуется)

```bash
# Скачайте и запустите скрипт исправления
wget https://raw.githubusercontent.com/your-repo/fix-certbot-compatibility.sh
chmod +x fix-certbot-compatibility.sh
sudo ./fix-certbot-compatibility.sh
```

### Вариант 2: Альтернативная настройка SSL

```bash
# Если certbot не работает, используйте альтернативу
wget https://raw.githubusercontent.com/your-repo/manual-ssl-setup.sh
chmod +x manual-ssl-setup.sh
sudo ./manual-ssl-setup.sh
```

## 🔍 Ручное исправление

### Шаг 1: Удаление несовместимых пакетов
```bash
sudo pip3 uninstall -y requests-toolbelt urllib3 certbot acme
```

### Шаг 2: Установка совместимых версий
```bash
# Вариант A: Через pip
sudo pip3 install 'urllib3<2.0' 'requests-toolbelt>=0.10.0' 'certbot>=1.21.0' 'acme>=1.21.0'

# Вариант B: Через apt (более стабильный)
sudo apt update
sudo apt install -y certbot python3-certbot-nginx
```

### Шаг 3: Проверка версий
```bash
python3 -c "import urllib3; print(f'urllib3: {urllib3.__version__}')"
python3 -c "import requests_toolbelt; print(f'requests-toolbelt: {requests_toolbelt.__version__}')"
python3 -c "import certbot; print(f'certbot: {certbot.__version__}')"
```

### Шаг 4: Тестирование certbot
```bash
certbot --version
```

### Шаг 5: Получение сертификата
```bash
# Создание директории для Let's Encrypt
sudo mkdir -p /var/www/html/.well-known/acme-challenge
sudo chown -R www-data:www-data /var/www/html/.well-known
sudo chmod -R 755 /var/www/html/.well-known

# Получение сертификата
sudo certbot --nginx -d soulsynergy.ru -d www.soulsynergy.ru --agree-tos --no-eff-email --redirect
```

## ⚠️ Если ничего не помогает

### Standalone режим certbot
```bash
sudo systemctl stop nginx
sudo certbot certonly --standalone --agree-tos --no-eff-email -d soulsynergy.ru -d www.soulsynergy.ru
sudo systemctl start nginx
```

### Самоподписанный сертификат (временное решение)
```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/soulsynergy.ru.key \
  -out /etc/ssl/certs/soulsynergy.ru.crt \
  -subj "/C=RU/ST=Moscow/L=Moscow/O=SoulSynergy/CN=soulsynergy.ru"
```

## 🔍 Диагностика

### Проверка логов
```bash
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

### Проверка установленных пакетов
```bash
pip3 list | grep -E "(urllib3|requests-toolbelt|certbot|acme)"
```

### Проверка импортов Python
```bash
python3 -c "from urllib3.contrib import appengine; print('appengine доступен')"
```

## 💡 Советы

1. **Используйте apt вместо pip** для certbot - это более стабильный способ
2. **Не смешивайте** установки через pip и apt для одних и тех же пакетов
3. **Проверяйте версии** перед установкой новых пакетов
4. **Создавайте бэкапы** конфигурации nginx перед изменениями

## 🎯 После исправления

- ✅ certbot работает без ошибок
- ✅ SSL сертификаты получены
- ✅ Сайт доступен по HTTPS
- ✅ HTTP автоматически перенаправляется на HTTPS

Если проблемы остаются, попробуйте альтернативную настройку SSL или создайте самоподписанный сертификат для временного решения.

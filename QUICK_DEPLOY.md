# ⚡ БЫСТРЫЙ ДЕПЛОЙ НА TIMEWEB CLOUD

## 🎯 КРАТКО: 3 ШАГА ДО ЗАПУСКА

### 1. **Подготовка на локальной машине**

```bash
# 1. Создайте файл переменных окружения для продакшена
cp server/env.production.example server/.env
cp client/env.production.example client/.env.production

# 2. Отредактируйте server/.env:
# - Замените yourdomain.ru на ваш домен
# - Смените JWT_SECRET на уникальный ключ (минимум 32 символа)

# 3. Отредактируйте client/.env.production:
# - Замените yourdomain.ru на ваш домен

# 4. Создайте архив проекта
zip -r ruplatform.zip . -x "node_modules/*" "*/node_modules/*" "*/dist/*" "*/logs/*"
```

### 2. **Загрузка на VPS Timeweb**

```bash
# 1. Подключитесь к VPS
ssh root@your-vps-ip

# 2. Создайте директорию
mkdir -p /var/www/ruplatform
cd /var/www/ruplatform

# 3. Загрузите и распакуйте архив
# (Через scp, wget или файловый менеджер)
unzip ruplatform.zip

# 4. Сделайте скрипт исполняемым
chmod +x deploy.sh
```

### 3. **Запуск автоматического деплоя**

```bash
# Запустите скрипт деплоя
./deploy.sh
```

## 🔧 НАСТРОЙКА NGINX

Создайте конфиг для вашего домена:

```bash
# 1. Скопируйте конфиг
cp nginx.conf /etc/nginx/sites-available/ruplatform

# 2. Отредактируйте домен
nano /etc/nginx/sites-available/ruplatform
# Замените yourdomain.ru на ваш домен

# 3. Активируйте конфиг
ln -s /etc/nginx/sites-available/ruplatform /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
```

## 🔒 SSL СЕРТИФИКАТ

```bash
# Установите SSL
apt install certbot python3-certbot-nginx -y
certbot --nginx -d yourdomain.ru -d www.yourdomain.ru
```

## ✅ ПРОВЕРКА

Откройте ваш сайт:
- **Сайт:** https://yourdomain.ru
- **API:** https://yourdomain.ru/api/users/cities
- **Поиск экспертов:** https://yourdomain.ru/experts

## 📊 МОНИТОРИНГ

```bash
# Статус сервера
pm2 status

# Логи
pm2 logs ruplatform-api

# Рестарт при необходимости
pm2 restart ruplatform-api
```

## 🔄 ОБНОВЛЕНИЕ

```bash
cd /var/www/ruplatform
git pull origin main  # Если используете Git
./deploy.sh           # Повторный деплой
```

---

**🎉 ВСЁ ГОТОВО! Ваша платформа духовных мастеров работает на продакшене!**

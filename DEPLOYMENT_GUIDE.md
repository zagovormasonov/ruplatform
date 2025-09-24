# 🚀 РУКОВОДСТВО ПО РАЗВЕРТЫВАНИЮ НА TIMEWEB CLOUD

## 📋 ПОДГОТОВКА К ДЕПЛОЮ

### 1. **Подготовка файлов для загрузки**

Создайте архив со следующими папками:
```
RuPlatform/
├── client/          # React приложение
├── server/          # Node.js сервер
├── package.json     # Корневой package.json
└── README.md        # Инструкции
```

### 2. **Настройка переменных окружения**

Создайте файл `server/.env` с настройками для продакшена:

```env
# База данных (ваша существующая)
DATABASE_URL=postgresql://gen_user:OCS(ifoR||A5$~@40e0a3b39459bee0b2e47359.twc1.net:5432/default_db

# JWT секрет (ОБЯЗАТЕЛЬНО смените!)
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production

# Порт сервера
PORT=3000

# Окружение
NODE_ENV=production

# CORS настройки (замените на ваш домен)
CLIENT_URL=https://yourdomain.ru
```

## 🌐 РАЗВЕРТЫВАНИЕ НА TIMEWEB CLOUD

### ВАРИАНТ 1: Shared хостинг (PHP хостинг)

#### **Подготовка клиента (React)**

1. **Соберите продакшен версию клиента:**
```bash
cd client
npm run build
```

2. **Загрузите содержимое папки `dist/` в корень домена**
   - Через файловый менеджер Timeweb
   - Или через FTP в папку `public_html`

3. **Настройте перенаправления для SPA**
   
Создайте файл `.htaccess` в корне домена:
```apache
RewriteEngine On
RewriteBase /

# Handle Angular and React Routes
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.html [L]

# Cache static assets
<IfModule mod_expires.c>
  ExpiresActive on
  ExpiresByType text/css "access plus 1 year"
  ExpiresByType application/javascript "access plus 1 year"
  ExpiresByType image/png "access plus 1 year"
  ExpiresByType image/jpg "access plus 1 year"
  ExpiresByType image/jpeg "access plus 1 year"
</IfModule>
```

### ВАРИАНТ 2: VPS (Рекомендуется)

#### **1. Подключение к VPS**
```bash
ssh root@your-vps-ip
```

#### **2. Установка Node.js**
```bash
# Обновление системы
apt update && apt upgrade -y

# Установка Node.js 18 LTS
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt-get install -y nodejs

# Проверка установки
node --version
npm --version
```

#### **3. Установка PM2 (менеджер процессов)**
```bash
npm install -g pm2
```

#### **4. Загрузка кода на сервер**

**Вариант A: Git (рекомендуется)**
```bash
# Клонирование репозитория
git clone https://github.com/yourusername/ruplatform.git
cd ruplatform
```

**Вариант B: Загрузка архива**
```bash
# Создание папки
mkdir /var/www/ruplatform
cd /var/www/ruplatform

# Загрузите архив через scp или файловый менеджер
scp -r RuPlatform/ root@your-vps-ip:/var/www/ruplatform/
```

#### **5. Установка зависимостей**
```bash
cd /var/www/ruplatform

# Корневые зависимости
npm install

# Серверные зависимости
cd server
npm install

# Клиентские зависимости и сборка
cd ../client
npm install
npm run build
```

#### **6. Настройка Nginx**

Создайте конфиг Nginx:
```bash
nano /etc/nginx/sites-available/ruplatform
```

```nginx
server {
    listen 80;
    server_name yourdomain.ru www.yourdomain.ru;

    # Static files (React app)
    location / {
        root /var/www/ruplatform/client/dist;
        try_files $uri $uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # API routes
    location /api/ {
        proxy_pass http://localhost:3000/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Socket.IO
    location /socket.io/ {
        proxy_pass http://localhost:3000/socket.io/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Активируйте конфиг:
```bash
ln -s /etc/nginx/sites-available/ruplatform /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
```

#### **7. Запуск сервера с PM2**
```bash
cd /var/www/ruplatform/server

# Создание ecosystem файла для PM2
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'ruplatform-api',
    script: 'dist/index.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    }
  }]
}
EOF

# Сборка TypeScript
npm run build

# Запуск с PM2
pm2 start ecosystem.config.js
pm2 startup
pm2 save
```

#### **8. Настройка SSL (Let's Encrypt)**
```bash
# Установка Certbot
apt install certbot python3-certbot-nginx -y

# Получение SSL сертификата
certbot --nginx -d yourdomain.ru -d www.yourdomain.ru

# Автообновление
crontab -e
# Добавьте строку:
0 12 * * * /usr/bin/certbot renew --quiet
```

## 🗄️ ИНИЦИАЛИЗАЦИЯ БАЗЫ ДАННЫХ

Поскольку БД уже существует, выполните инициализацию:

```bash
cd /var/www/ruplatform/server
node init-db.js
```

Если нужно добавить тестовых экспертов:
```bash
node add-test-data.js
```

## 🔧 НАСТРОЙКА КЛИЕНТА ДЛЯ ПРОДАКШЕНА

Обновите `client/src/services/api.ts`:

```typescript
const API_BASE_URL = process.env.NODE_ENV === 'production' 
  ? 'https://yourdomain.ru/api'  // Ваш домен
  : 'http://localhost:3001/api';
```

Или используйте переменную окружения в Vite:

Создайте `client/.env.production`:
```env
VITE_API_URL=https://yourdomain.ru/api
```

И обновите `api.ts`:
```typescript
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';
```

## 🚀 ФИНАЛЬНЫЕ ШАГИ

### 1. **Проверка работы**
- Откройте ваш домен в браузере
- Проверьте работу API: `https://yourdomain.ru/api/users/cities`
- Протестируйте регистрацию и поиск экспертов

### 2. **Мониторинг**
```bash
# Логи сервера
pm2 logs ruplatform-api

# Статус процессов
pm2 status

# Перезапуск при необходимости
pm2 restart ruplatform-api
```

### 3. **Обновление кода**
```bash
cd /var/www/ruplatform

# Обновление из Git
git pull origin main

# Пересборка клиента
cd client
npm run build

# Пересборка и перезапуск сервера
cd ../server
npm run build
pm2 restart ruplatform-api
```

## 🔒 БЕЗОПАСНОСТЬ

1. **Смените JWT_SECRET** в production
2. **Настройте firewall:**
```bash
ufw allow ssh
ufw allow 80
ufw allow 443
ufw enable
```

3. **Ограничьте доступ к .env файлам**
4. **Регулярно обновляйте систему и зависимости**

## 🎉 ГОТОВО!

Ваша платформа духовных мастеров теперь работает на продакшене!

**URL:** https://yourdomain.ru
**API:** https://yourdomain.ru/api
**Чаты:** WebSocket через Socket.IO

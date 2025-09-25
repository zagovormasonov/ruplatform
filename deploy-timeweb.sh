#!/bin/bash

# 🚀 СКРИПТ РАЗВЕРТЫВАНИЯ НА TIMEWEB
# Использовать: ./deploy-timeweb.sh your-server-ip yourdomain.timeweb.ru

set -e

SERVER_IP=$1
DOMAIN=$2

if [ -z "$SERVER_IP" ] || [ -z "$DOMAIN" ]; then
    echo "❌ Использование: ./deploy-timeweb.sh <server-ip> <domain>"
    echo "Пример: ./deploy-timeweb.sh 192.168.1.100 mysite.timeweb.ru"
    exit 1
fi

echo "🚀 Начинаем развертывание на Timeweb..."
echo "📡 Сервер: $SERVER_IP"
echo "🌐 Домен: $DOMAIN"

# Проверка готовности билдов
if [ ! -d "client/dist" ]; then
    echo "❌ Папка client/dist не найдена. Сначала соберите клиент: cd client && npm run build"
    exit 1
fi

if [ ! -d "server/dist" ]; then
    echo "❌ Папка server/dist не найдена. Сначала соберите сервер: cd server && npm run build"
    exit 1
fi

echo "✅ Билды найдены"

# Создание production .env
echo "📝 Создание production .env..."
cat > server/.env.production << EOF
DATABASE_URL=postgresql://gen_user:OCS(ifoR||A5$~@40e0a3b39459bee0b2e47359.twc1.net:5432/default_db
JWT_SECRET=timeweb_production_secret_$(date +%s)
PORT=3000
NODE_ENV=production
CLIENT_URL=https://$DOMAIN
EOF

echo "✅ .env.production создан"

# Создание PM2 конфигурации
echo "📝 Создание PM2 конфигурации..."
cat > server/ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'ruplatform-server',
    script: './dist/index.js',
    cwd: '/var/www/ruplatform/server',
    instances: 1,
    exec_mode: 'fork',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    restart_delay: 1000,
    max_restarts: 10
  }]
};
EOF

echo "✅ PM2 конфигурация создана"

# Создание Nginx конфигурации
echo "📝 Создание Nginx конфигурации..."
cat > nginx-site.conf << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    # React приложение
    root /var/www/ruplatform/client/dist;
    index index.html;
    
    # Gzip сжатие
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    # Обслуживание статических файлов
    location / {
        try_files \$uri \$uri/ /index.html;
        add_header Cache-Control "public, max-age=31536000";
    }
    
    # API запросы к Node.js серверу
    location /api/ {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Socket.IO
    location /socket.io/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

echo "✅ Nginx конфигурация создана"

# Создание архива для загрузки
echo "📦 Создание архива для загрузки..."
tar -czf ruplatform-deploy.tar.gz \
    client/dist/ \
    server/dist/ \
    server/package.json \
    server/package-lock.json \
    server/.env.production \
    server/ecosystem.config.js \
    nginx-site.conf

echo "✅ Архив ruplatform-deploy.tar.gz создан"

# Создание скрипта установки для сервера
cat > install-on-server.sh << 'EOF'
#!/bin/bash

echo "🔧 Установка приложения на сервере..."

# Обновление системы
apt update && apt upgrade -y

# Установка Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt install -y nodejs

# Установка PM2 и Nginx
npm install -g pm2
apt install -y nginx

# Создание директории приложения
mkdir -p /var/www/ruplatform
cd /var/www/ruplatform

# Извлечение архива (предполагается, что архив уже загружен)
tar -xzf ruplatform-deploy.tar.gz

# Установка зависимостей сервера
cd server
npm install --production
mkdir -p logs

# Настройка Nginx
cp ../nginx-site.conf /etc/nginx/sites-available/ruplatform
ln -sf /etc/nginx/sites-available/ruplatform /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# Запуск приложения
pm2 start ecosystem.config.js
pm2 save
pm2 startup

echo "✅ Установка завершена!"
echo "🌐 Приложение доступно по адресу: https://soulsynergy.ru"
echo "📊 Логи: pm2 logs"
echo "🔄 Перезапуск: pm2 restart ruplatform-server"
EOF

chmod +x install-on-server.sh

echo ""
echo "🎉 ПОДГОТОВКА ЗАВЕРШЕНА!"
echo ""
echo "📦 Файлы готовы к развертыванию:"
echo "   ✅ ruplatform-deploy.tar.gz - архив с приложением"
echo "   ✅ install-on-server.sh - скрипт установки"
echo ""
echo "🚀 СЛЕДУЮЩИЕ ШАГИ:"
echo ""
echo "1. Загрузите файлы на сервер:"
echo "   scp ruplatform-deploy.tar.gz root@$SERVER_IP:/tmp/"
echo "   scp install-on-server.sh root@$SERVER_IP:/tmp/"
echo ""
echo "2. Подключитесь к серверу и запустите установку:"
echo "   ssh root@$SERVER_IP"
echo "   cd /tmp"
echo "   chmod +x install-on-server.sh"
echo "   ./install-on-server.sh"
echo ""
echo "3. Настройте SSL (опционально):"
echo "   apt install -y certbot python3-certbot-nginx"
echo "   certbot --nginx -d $DOMAIN -d www.$DOMAIN"
echo ""
echo "🌐 После установки сайт будет доступен по адресу: https://$DOMAIN"
echo ""

# Очистка временных файлов
rm -f nginx-site.conf

echo "✨ Готово! Удачного развертывания! 🚀"

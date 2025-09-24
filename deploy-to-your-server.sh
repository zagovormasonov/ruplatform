#!/bin/bash

# 🚀 АВТОМАТИЧЕСКОЕ РАЗВЕРТЫВАНИЕ НА СЕРВЕРЕ 31.130.155.103
# Использование: ./deploy-to-your-server.sh

set -e

SERVER_IP="31.130.155.103"
DOMAIN="31.130.155.103"

echo "🚀 Развертывание RuPlatform на сервере $SERVER_IP..."

# Проверка готовности билдов
if [ ! -d "client/dist" ]; then
    echo "❌ Папка client/dist не найдена!"
    echo "Сначала соберите клиент: cd client && npm run build"
    exit 1
fi

if [ ! -d "server/dist" ]; then
    echo "❌ Папка server/dist не найдена!" 
    echo "Сначала соберите сервер: cd server && npm run build"
    exit 1
fi

echo "✅ Билды найдены"

# Создание production .env
echo "📝 Создание .env для продакшена..."
cat > server/.env.production << EOF
DATABASE_URL=postgresql://gen_user:OCS(ifoR||A5$~@40e0a3b39459bee0b2e47359.twc1.net:5432/default_db
JWT_SECRET=ruplatform_production_$(date +%s)_secret
PORT=3000
NODE_ENV=production
CLIENT_URL=http://$SERVER_IP
EOF

echo "✅ .env создан"

# Создание PM2 конфигурации
echo "📝 Создание PM2 конфигурации..."
cat > server/ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'ruplatform',
    script: './server-dist/index.js',
    cwd: '/var/www/ruplatform',
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

# Создание скрипта установки для сервера
echo "📝 Создание скрипта установки..."
cat > install-on-server.sh << 'EOFINSTALL'
#!/bin/bash

echo "🔧 Установка RuPlatform на сервере..."

# Обновление системы
echo "📦 Обновление системы..."
apt update && apt upgrade -y

# Установка Node.js 18
echo "🟢 Установка Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt install -y nodejs

# Установка PM2 и Nginx
echo "⚙️ Установка PM2 и Nginx..."
npm install -g pm2
apt install -y nginx

# Создание структуры папок
echo "📁 Создание структуры приложения..."
mkdir -p /var/www/ruplatform/client-dist
mkdir -p /var/www/ruplatform/server-dist  
mkdir -p /var/www/ruplatform/logs

echo "✅ Система подготовлена!"
echo ""
echo "📂 Теперь загрузите файлы проекта:"
echo "   scp -r client/dist/* root@31.130.155.103:/var/www/ruplatform/client-dist/"
echo "   scp -r server/dist/* root@31.130.155.103:/var/www/ruplatform/server-dist/"
echo "   scp server/package.json root@31.130.155.103:/var/www/ruplatform/"
echo "   scp server/.env.production root@31.130.155.103:/var/www/ruplatform/.env"
echo "   scp server/ecosystem.config.js root@31.130.155.103:/var/www/ruplatform/"
echo ""
echo "После загрузки файлов запустите: ./configure-and-start.sh"
EOFINSTALL

# Создание скрипта финальной конфигурации
cat > configure-and-start.sh << 'EOFCONFIG'
#!/bin/bash

echo "🚀 Финальная настройка и запуск RuPlatform..."

cd /var/www/ruplatform

# Установка зависимостей
echo "📦 Установка зависимостей..."
npm install --production

# Настройка Nginx
echo "🌐 Настройка Nginx..."
cat > /etc/nginx/sites-available/ruplatform << 'EOFNGINX'
server {
    listen 80;
    server_name 31.130.155.103;
    
    # React приложение
    root /var/www/ruplatform/client-dist;
    index index.html;
    
    # Gzip сжатие
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    # Обслуживание статических файлов
    location / {
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "public, max-age=3600";
    }
    
    # API запросы к Node.js серверу
    location /api/ {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Socket.IO для чатов
    location /socket.io/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Безопасность
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";
}
EOFNGINX

# Активация сайта в Nginx
ln -sf /etc/nginx/sites-available/ruplatform /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Проверка и перезапуск Nginx
nginx -t
if [ $? -eq 0 ]; then
    systemctl restart nginx
    echo "✅ Nginx настроен"
else
    echo "❌ Ошибка в конфигурации Nginx"
    exit 1
fi

# Запуск приложения
echo "🚀 Запуск приложения..."
pm2 start ecosystem.config.js
pm2 save
pm2 startup

echo ""
echo "🎉 УСТАНОВКА ЗАВЕРШЕНА!"
echo ""
echo "🌐 Ваш сайт доступен по адресу: http://31.130.155.103"
echo "🔌 API доступно по адресу: http://31.130.155.103/api"
echo ""
echo "📊 Полезные команды:"
echo "   pm2 status          - статус приложения"
echo "   pm2 logs ruplatform - логи приложения"
echo "   pm2 restart ruplatform - перезапуск"
echo "   systemctl status nginx - статус Nginx"
echo ""
EOFCONFIG

# Делаем скрипты исполняемыми
chmod +x install-on-server.sh
chmod +x configure-and-start.sh

echo ""
echo "🎉 ПОДГОТОВКА ЗАВЕРШЕНА!"
echo ""
echo "📦 Созданы файлы:"
echo "   ✅ server/.env.production - настройки для продакшена"
echo "   ✅ server/ecosystem.config.js - конфигурация PM2"
echo "   ✅ install-on-server.sh - скрипт подготовки сервера"
echo "   ✅ configure-and-start.sh - скрипт запуска приложения"
echo ""
echo "🚀 ПОШАГОВАЯ ИНСТРУКЦИЯ:"
echo ""
echo "1️⃣ Загрузите скрипт на сервер и запустите подготовку:"
echo "   scp install-on-server.sh root@$SERVER_IP:/tmp/"
echo "   ssh root@$SERVER_IP"
echo "   cd /tmp && chmod +x install-on-server.sh && ./install-on-server.sh"
echo ""
echo "2️⃣ Загрузите файлы проекта на сервер:"
echo "   scp -r client/dist/* root@$SERVER_IP:/var/www/ruplatform/client-dist/"
echo "   scp -r server/dist/* root@$SERVER_IP:/var/www/ruplatform/server-dist/"
echo "   scp server/package.json root@$SERVER_IP:/var/www/ruplatform/"
echo "   scp server/.env.production root@$SERVER_IP:/var/www/ruplatform/.env"
echo "   scp server/ecosystem.config.js root@$SERVER_IP:/var/www/ruplatform/"
echo ""
echo "3️⃣ Загрузите скрипт конфигурации и запустите:"
echo "   scp configure-and-start.sh root@$SERVER_IP:/var/www/ruplatform/"
echo "   ssh root@$SERVER_IP"
echo "   cd /var/www/ruplatform && chmod +x configure-and-start.sh && ./configure-and-start.sh"
echo ""
echo "🌐 После выполнения ваш сайт будет доступен: http://$SERVER_IP"
echo ""
echo "✨ Удачного развертывания! 🚀"

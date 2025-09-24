# 🔄 СМЕНА ПОРТА С 3000 НА 3001

## 🎯 ПЛАН:
Меняем порт Node.js сервера с 3000 на 3001, чтобы избежать конфликтов.

## 🔧 ПОШАГОВАЯ СМЕНА ПОРТА:

**Выполните на сервере 31.130.155.103:**

### ШАГ 1: Остановить PM2
```bash
# Остановить все процессы PM2
pm2 stop all
pm2 delete all
```

### ШАГ 2: Обновить .env файл
```bash
# Перейти в папку сервера
cd /home/node/ruplatform/server

# Создать новый .env с портом 3001
cat > .env << 'EOF'
DATABASE_URL=postgresql://gen_user:OCS(ifoR||A5$~@40e0a3b39459bee0b2e47359.twc1.net:5432/default_db
JWT_SECRET=ruplatform_production_secret_2024
PORT=3001
NODE_ENV=production
CLIENT_URL=http://31.130.155.103
EOF

echo "✅ .env обновлен - порт изменен на 3001"
```

### ШАГ 3: Обновить PM2 конфиг
```bash
# Создать новый ecosystem.config.js с портом 3001
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'ruplatform',
    script: './dist/index.js',
    cwd: '/home/node/ruplatform/server',
    instances: 1,
    exec_mode: 'fork',
    env: {
      NODE_ENV: 'production',
      PORT: 3001
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

echo "✅ PM2 конфиг обновлен - порт изменен на 3001"
```

### ШАГ 4: Обновить Nginx конфиг
```bash
# Создать новую конфигурацию Nginx с портом 3001
sudo tee /etc/nginx/conf.d/ruplatform.conf > /dev/null << 'EOF'
server {
    listen 80;
    server_name 31.130.155.103;
    root /home/node/ruplatform/client/dist;
    index index.html;
    
    # Логи
    access_log /var/log/nginx/ruplatform.access.log;
    error_log /var/log/nginx/ruplatform.error.log;
    
    # Статические файлы React
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # API запросы к Node.js на порту 3001
    location /api/ {
        proxy_pass http://127.0.0.1:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Socket.IO на порту 3001
    location /socket.io/ {
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

echo "✅ Nginx конфиг обновлен - проксирование на порт 3001"
```

### ШАГ 5: Перезапустить сервисы
```bash
# Проверить и перезапустить Nginx
sudo nginx -t && sudo systemctl restart nginx

# Запустить PM2 с новым портом
pm2 start ecosystem.config.js

# Сохранить конфигурацию PM2
pm2 save

echo "✅ Все сервисы перезапущены"
```

## ✅ ПРОВЕРКА РАБОТЫ:

```bash
# 1. Проверить статус PM2
pm2 status

# 2. Проверить что порт 3001 занят нашим приложением
sudo netstat -tulpn | grep :3001

# 3. Проверить что порт 3000 свободен
sudo netstat -tulpn | grep :3000

# 4. Тест API напрямую
curl http://localhost:3001/api/experts/search

# 5. Тест API через Nginx
curl http://31.130.155.103/api/experts/search

# 6. Проверить логи PM2
pm2 logs ruplatform --lines 10
```

## 🎉 ОЖИДАЕМЫЙ РЕЗУЛЬТАТ:

```bash
# PM2 status должен показать:
pm2 status
# ┌─────┬──────────────┬─────────────┬─────────┬─────────┬──────────┐
# │ id  │ name         │ namespace   │ version │ mode    │ pid      │
# ├─────┼──────────────┼─────────────┼─────────┼─────────┼──────────┤
# │ 0   │ ruplatform   │ default     │ 1.0.0   │ fork    │ 12345    │
# └─────┴──────────────┴─────────────┴─────────┴─────────┴──────────┘

# netstat должен показать порт 3001:
sudo netstat -tulpn | grep :3001
# tcp6    0    0 :::3001    :::*    LISTEN    12345/node

# API должно отвечать:
curl http://31.130.155.103/api/experts/search
# {"experts":[],"pagination":{"page":1,"limit":12,"total":0,"totalPages":0}}
```

## 🚨 ЕСЛИ ЕСТЬ ПРОБЛЕМЫ:

### Проблема: PM2 не запускается
```bash
pm2 logs ruplatform
# Посмотреть ошибки в логах
```

### Проблема: Nginx ошибка
```bash
sudo nginx -t
# Проверить конфигурацию

sudo tail -f /var/log/nginx/error.log
# Посмотреть логи Nginx
```

### Проблема: API не отвечает
```bash
# Проверить что сервер слушает правильный порт
pm2 show ruplatform

# Проверить переменные окружения
cat /home/node/ruplatform/server/.env
```

## 📊 ИТОГОВАЯ СТРУКТУРА:

```
Порты:
├── 80 (HTTP) → Nginx → Фронтенд (статические файлы)
└── 80/api/ → Nginx → 127.0.0.1:3001 → Node.js API

Файлы:
├── /home/node/ruplatform/client/dist/ → Фронтенд
├── /home/node/ruplatform/server/dist/ → Бэкенд
├── /home/node/ruplatform/server/.env → PORT=3001
└── /etc/nginx/conf.d/ruplatform.conf → proxy_pass http://127.0.0.1:3001
```

## 🎯 ФИНАЛЬНЫЙ ТЕСТ:

После выполнения всех шагов:

1. **Откройте в браузере:** http://31.130.155.103
2. **Проверьте API:** http://31.130.155.103/api/experts/search
3. **Бесконечная загрузка должна исчезнуть**
4. **Приложение должно работать полностью**

**ВЫПОЛНИТЕ ВСЕ ШАГИ И ПРОВЕРЬТЕ РЕЗУЛЬТАТ! 🚀**

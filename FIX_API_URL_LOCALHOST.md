# 🔧 ИСПРАВЛЕНИЕ: ФРОНТЕНД ОБРАЩАЕТСЯ К LOCALHOST

## ❌ ПРОБЛЕМА:
Фронтенд пытается подключиться к `localhost:3001`, но должен обращаться к `31.130.155.103/api`

## 🔍 ПРИЧИНА:
Переменная `VITE_API_URL` не настроена в клиенте, поэтому используется localhost.

## ✅ РЕШЕНИЕ:

### ВАРИАНТ 1: Пересобрать клиент с правильным API URL

**На вашем компьютере:**

```bash
# 1. Перейти в папку клиента
cd client

# 2. Создать .env файл для продакшена
cat > .env.production << 'EOF'
VITE_API_URL=https://soulsynergy.ru/api
EOF

# 3. Пересобрать клиент
npm run build

# 4. Загрузить новые файлы на сервер
scp -r dist/* root@soulsynergy.ru:/home/node/ruplatform/client/dist/
```

### ВАРИАНТ 2: Настроить Nginx редирект (быстрее)

**На сервере 31.130.155.103:**

```bash
# Обновить Nginx конфиг для обработки localhost запросов
sudo tee /etc/nginx/conf.d/ruplatform.conf > /dev/null << 'EOF'
server {
    listen 80;
    server_name soulsynergy.ru;
    root /home/node/ruplatform/client/dist;
    index index.html;
    
    # Основные файлы
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # API запросы
    location /api/ {
        proxy_pass http://127.0.0.1:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS заголовки
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type' always;
        
        # Обработка preflight запросов
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*';
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS';
            add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type';
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain charset=UTF-8';
            add_header 'Content-Length' 0;
            return 204;
        }
    }
    
    # Socket.IO
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

# Дополнительный сервер для обработки localhost запросов
server {
    listen 3001;
    server_name localhost 127.0.0.1 soulsynergy.ru;
    
    # Перенаправить все API запросы на наш Node.js сервер
    location / {
        proxy_pass http://127.0.0.1:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS заголовки
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type' always;
    }
}
EOF

# Перезапустить Nginx
sudo nginx -t && sudo systemctl restart nginx
```

### ВАРИАНТ 3: Изменить настройки в API клиенте (самый быстрый)

**На сервере найти и отредактировать api.ts:**

```bash
# Найти файл api.ts в собранном клиенте
find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "localhost:3001" {} \;

# Если найден, заменить localhost на IP сервера
sudo sed -i 's/localhost:3001/31.130.155.103\/api/g' /home/node/ruplatform/client/dist/assets/*.js

# Перезагрузить страницу в браузере
```

## 🚀 РЕКОМЕНДУЕМОЕ БЫСТРОЕ РЕШЕНИЕ:

```bash
# На сервере 31.130.155.103:

# 1. Найти и заменить localhost в JS файлах
sudo find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's/localhost:3001/31.130.155.103\/api/g' {} \;

# 2. Также заменить http://localhost:3001/api на /api (относительный путь)
sudo find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's/http:\/\/localhost:3001\/api/\/api/g' {} \;

# 3. Проверить что изменения применились
sudo grep -r "localhost" /home/node/ruplatform/client/dist/ || echo "✅ localhost заменен"

# 4. Обновить страницу в браузере (Ctrl+F5)
```

## ✅ ПРОВЕРКА РЕЗУЛЬТАТА:

```bash
# 1. Проверить что API работает
curl https://soulsynergy.ru/api/experts/search

# 2. Проверить что в JS файлах нет localhost
sudo grep -r "localhost" /home/node/ruplatform/client/dist/

# 3. Открыть сайт в браузере и проверить Network вкладку в DevTools
# Запросы должны идти на 31.130.155.103/api, а не на localhost:3001
```

## 📊 ДО И ПОСЛЕ:

**До исправления:**
```
Frontend → localhost:3001/api → ❌ Connection Refused
```

**После исправления:**
```
Frontend → 31.130.155.103/api → Nginx → 127.0.0.1:3001 → Node.js → ✅ Success
```

## 🎯 ОЖИДАЕМЫЙ РЕЗУЛЬТАТ:

После исправления:
- ✅ Ошибки "Network Error" исчезнут
- ✅ Запросы будут идти на `https://soulsynergy.ru/api`
- ✅ Поиск экспертов заработает
- ✅ Авторизация заработает
- ✅ Все API функции заработают

## 🚨 ЕСЛИ НЕ ПОМОГЛО:

```bash
# Проверить консоль браузера (F12)
# Во вкладке Network смотреть куда идут запросы

# Если все еще localhost:3001, то нужно пересобрать клиент:
# На вашем компьютере:
# echo 'VITE_API_URL=https://soulsynergy.ru/api' > client/.env.production
# cd client && npm run build
# scp -r dist/* root@soulsynergy.ru:/home/node/ruplatform/client/dist/
```

**ВЫПОЛНИТЕ БЫСТРОЕ РЕШЕНИЕ И ОБНОВИТЕ СТРАНИЦУ! 🚀**

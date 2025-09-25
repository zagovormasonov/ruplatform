# 🚀 ЗАПУСК BACKEND НА ПОРТУ 3001

## ✅ ПЕРЕХОД НА ПОРТ 3001

Backend был успешно перенесен с порта 3000 на порт 3001 для избежания конфликтов.

## 🔧 ЗАПУСК BACKEND НА ПОРТУ 3001

### ШАГ 1: Запустите скрипт
```bash
# На сервере выполните:
wget https://raw.githubusercontent.com/your-repo/start-backend-3001.sh
chmod +x start-backend-3001.sh
sudo ./start-backend-3001.sh
```

### ШАГ 2: Проверьте результат
```bash
# Должно показать:
# ✅ Порт 3001 свободен
# ✅ Backend собран успешно
# ✅ Backend запущен через PM2
# ✅ API работает: 200 OK
```

## 🔧 РУЧНОЙ ЗАПУСК

### 1. Проверьте порт 3001:
```bash
netstat -tlnp | grep ":3001"
# Должно показать: ничего
```

### 2. Соберите и запустите backend:
```bash
cd /home/node/ruplatform/server

# Создайте .env файл
echo "PORT=3001" > .env

# Соберите backend
npm run build

# Запустите через PM2
pm2 start dist/index.js --name "ruplatform-backend" -- --port 3001
```

### 3. Проверьте что работает:
```bash
# PM2 должен показать online
pm2 status

# Порт 3001 должен быть открыт
netstat -tlnp | grep ":3001"

# API должен отвечать
curl -I http://localhost:3001/api/experts/1
# Должно вернуть: 200 OK
```

## 🧪 ТЕСТИРОВАНИЕ

### В браузере:
```javascript
// ✅ ДОЛЖНЫ РАБОТАТЬ:
✓ https://soulsynergy.ru/api/experts/1 200 OK
✓ https://soulsynergy.ru/api/users/cities 200 OK
✓ https://soulsynergy.ru/api/experts/search 200 OK
✓ Профиль эксперта отображает имя
✓ Кнопка "Связаться" работает

// ❌ НЕ ДОЛЖНО БЫТЬ:
✗ 404 Not Found
✗ Connection refused
✗ "ID собеседника обязателен"
✗ Ошибки чата
```

### В консоли сервера:
```bash
# ✅ ДОЛЖНЫ РАБОТАТЬ:
✓ pm2 status - показывает online
✓ netstat -tlnp | grep ":3001" - показывает LISTEN
✓ curl -I http://localhost:3001/api/experts/1 - 200 OK
✓ ps aux | grep node - только PM2 процесс

# ❌ НЕ ДОЛЖНО БЫТЬ:
✗ EADDRINUSE ошибки
✗ Port already in use
✗ Множественные Node.js процессы
✗ Ошибки сборки
```

## 🎯 РЕЗУЛЬТАТ

✅ **Порт 3001 свободен** - нет конфликтов
✅ **Backend собран** - dist/index.js создан
✅ **PM2 запущен** - процесс online
✅ **API отвечает 200 OK** - все endpoints работают
✅ **В браузере все работает** - профиль, чат, авторизация

## 🔄 NGINX КОНФИГУРАЦИЯ

Nginx уже настроен для проксирования запросов на порт 3001:
```nginx
location /api/ {
    proxy_pass http://localhost:3001/api/;
    # ...
}

location /socket.io/ {
    proxy_pass http://localhost:3001/socket.io/;
    # ...
}
```

## 🚨 ЕСЛИ ВОЗНИКЛИ ПРОБЛЕМЫ

### Используйте аварийное исправление:
```bash
# Если порт 3001 занят:
wget https://raw.githubusercontent.com/your-repo/emergency-port-fix.sh
chmod +x emergency-port-fix.sh
sudo ./emergency-port-fix.sh
```

### Или ядерное исправление:
```bash
# Если ничего не помогает:
wget https://raw.githubusercontent.com/your-repo/nuclear-port-fix.sh
chmod +x nuclear-port-fix.sh
sudo ./nuclear-port-fix.sh
```

**BACKEND УСПЕШНО ПЕРЕНЕСЕН НА ПОРТ 3001 И ГОТОВ К РАБОТЕ!** 🚀

# 🚨 АВАРИЙНОЕ ИСПРАВЛЕНИЕ КОНФЛИКТА ПОРТА 3001

## ❌ ПРОБЛЕМА
```
Error: listen EADDRINUSE: address already in use :::3001
```
Порт 3001 занят другим процессом и PM2 не может запустить backend.

## 🔍 ПРИЧИНЫ
1. **Старый PM2 процесс** все еще слушает порт
2. **Другой Node.js процесс** использует порт 3001
3. **Процесс не был остановлен корректно** при предыдущем запуске
4. **Множественные backend процессы** запущены одновременно

## 🚨 АВАРИЙНОЕ РЕШЕНИЕ

### ШАГ 1: ЗАПУСТИТЕ АВАРИЙНОЕ ИСПРАВЛЕНИЕ
```bash
# На сервере выполните:
wget https://raw.githubusercontent.com/your-repo/emergency-port-fix.sh
chmod +x emergency-port-fix.sh
sudo ./emergency-port-fix.sh
```

### ШАГ 2: ПРОВЕРЬТЕ РЕЗУЛЬТАТ
```bash
# Должно показать:
# ✅ ПОРТ 3001 ОСВОБОЖДЕН
# ✅ Backend собран успешно
# ✅ Backend запущен через PM2
# ✅ API работает: 200 OK
```

## 🔧 РУЧНОЕ АВАРИЙНОЕ ИСПРАВЛЕНИЕ

### 1. Принудительно освободите порт:
```bash
# Остановите ВСЕ PM2 процессы
pm2 stop all && pm2 delete all && pm2 kill

# Убейте ВСЕ Node.js процессы
pkill -9 node
pkill -9 -f "3001"
pkill -9 -f "ruplatform"
pkill -9 -f "dist/index.js"

# Ждите освобождения
sleep 5

# Проверьте что порт свободен
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

## 🧪 ПРОВЕРКА РЕЗУЛЬТАТА

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
```

### В браузере:
```javascript
// ✅ ДОЛЖНЫ РАБОТАТЬ:
✓ https://soulsynergy.ru/api/experts/1 200 OK
✓ https://soulsynergy.ru/api/users/cities 200 OK
✓ https://soulsynergy.ru/api/experts/search 200 OK

// ❌ НЕ ДОЛЖНО БЫТЬ:
✗ 404 Not Found
✗ Connection refused
✗ "ID собеседника обязателен"
✗ Ошибки чата
```

## 🎯 ОЖИДАЕМЫЙ РЕЗУЛЬТАТ

✅ **Порт 3001 свободен** - нет конфликтов
✅ **Backend собран** - dist/index.js создан
✅ **PM2 запущен** - процесс online
✅ **API отвечает 200 OK** - все endpoints работают
✅ **В браузере все работает** - профиль, чат, авторизация

**Это аварийное исправление убьет ВСЕ процессы на порту 3001 и перезапустит backend!** 🚀

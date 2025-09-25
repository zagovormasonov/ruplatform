# 🔍 ДИАГНОСТИКА И ИСПРАВЛЕНИЕ 404 NOT FOUND

## ❌ ПРОБЛЕМА
API возвращает 404 Not Found, хотя nginx отвечает с правильными заголовками.

## 🔍 ПРИЧИНЫ
1. **Backend не запущен** на порту 3000
2. **PM2 процесс остановлен** или не запущен
3. **nginx не может проксировать** запросы к backend
4. **Порт 3000 занят** другим процессом

## ⚡ НЕМЕДЛЕННОЕ РЕШЕНИЕ

### ШАГ 1: ЗАПУСТИТЕ ДИАГНОСТИКУ
```bash
# На сервере выполните:
wget https://raw.githubusercontent.com/your-repo/diagnose-404.sh
chmod +x diagnose-404.sh
sudo ./diagnose-404.sh
```

### ШАГ 2: ПРОВЕРЬТЕ РЕЗУЛЬТАТ
```bash
# Должно показать:
# ✅ PM2 запущен
# ✅ Порт 3000 открыт
# ✅ nginx проксирует запросы
# ✅ API отвечает 200 OK
```

## 🔧 РУЧНАЯ ДИАГНОСТИКА

### 1. Проверьте PM2 процессы:
```bash
pm2 status
# Должно показать: online
```

### 2. Проверьте порт 3000:
```bash
netstat -tlnp | grep ":3000"
# Должно показать: LISTEN (node процесс)
```

### 3. Тестируйте API напрямую:
```bash
curl -I http://localhost:3000/api/experts/1
# Должно вернуть: 200 OK
```

### 4. Тестируйте через nginx:
```bash
curl -I https://soulsynergy.ru/api/experts/1
# Должно вернуть: 200 OK
```

## 🔍 ПОДРОБНАЯ ДИАГНОСТИКА

### Если PM2 не запущен:
```bash
# Остановите все процессы
pm2 stop all && pm2 delete all && pm2 kill
pkill -9 node && pkill -9 -f "3000"

# Соберите и запустите backend
cd /home/node/ruplatform/server
npm run build
pm2 start dist/index.js --name "ruplatform-backend" -- --port 3000

# Проверьте
pm2 status
```

### Если порт 3000 занят:
```bash
# Найдите что занимает порт
netstat -tlnp | grep ":3000"

# Остановите процесс
pkill -9 <PID>

# Или освободите все порты
pkill -9 node && pkill -9 -f "3000" && pkill -9 -f "ruplatform"
```

### Если nginx не проксирует:
```bash
# Проверьте конфигурацию
sudo nginx -t

# Перезагрузите nginx
sudo systemctl reload nginx

# Проверьте логи nginx
sudo tail -f /var/log/nginx/ruplatform_error.log
```

## 🧪 ПРОВЕРКА РЕЗУЛЬТАТА

### В консоли сервера:
```bash
# ✅ ДОЛЖНЫ РАБОТАТЬ:
✓ pm2 status - показывает online
✓ netstat -tlnp | grep ":3000" - показывает LISTEN
✓ curl -I http://localhost:3000/api/experts/1 - 200 OK
✓ curl -I https://soulsynergy.ru/api/experts/1 - 200 OK
✓ sudo nginx -t - конфигурация корректна
✓ sudo systemctl is-active nginx - active
```

### В браузере (Network):
```javascript
// ✅ ДОЛЖНЫ РАБОТАТЬ:
✓ https://soulsynergy.ru/api/experts/1 200 OK
✓ https://soulsynergy.ru/api/users/cities 200 OK
✓ https://soulsynergy.ru/api/experts/search 200 OK

// ❌ НЕ ДОЛЖНО БЫТЬ:
✗ 404 Not Found
✗ Connection refused
✗ Cannot connect to server
```

## 🎯 ОЖИДАЕМЫЙ РЕЗУЛЬТАТ

✅ **Backend запущен** - PM2 показывает online
✅ **Порт 3000 открыт** - netstat показывает LISTEN
✅ **nginx проксирует** - запросы доходят до backend
✅ **API отвечает 200 OK** - все endpoints работают
✅ **В браузере нет 404** - все запросы успешны

**Выполните диагностику - 404 ошибка исчезнет!** 🚀

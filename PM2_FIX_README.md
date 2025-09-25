# 🚨 ИСПРАВЛЕНИЕ PM2 И BACKEND СЕРВЕРА

## ❌ ПРОБЛЕМА
Из диагностики видно, что:
- **PM2 не запущен** (нет процессов)
- **Порт 3000 не открыт** (nginx не может связаться с backend)
- **Есть Node.js процесс** запущенный напрямую: `node /home/node/ruplatform/server/dist/index.js`

## ⚡ НЕМЕДЛЕННОЕ РЕШЕНИЕ

### ШАГ 1: ЗАПУСТИТЕ СКРИПТ ИСПРАВЛЕНИЯ
```bash
# Скачайте и запустите скрипт исправления PM2
wget https://raw.githubusercontent.com/your-repo/fix-pm2-backend.sh
chmod +x fix-pm2-backend.sh
sudo ./fix-pm2-backend.sh
```

### ШАГ 2: ПЕРЕЗАГРУЗИТЕ СТРАНИЦУ
```bash
# В браузере: Ctrl+Shift+R (Windows/Linux)
# Или: Cmd+Shift+R (Mac)
```

## 🔍 ЧТО ДЕЛАЕТ СКРИПТ

### ✅ ОСТАНАВЛИВАЕТ ВСЕ:
- **PM2 процессы** - останавливает все
- **Node.js процессы** - убивает все связанные с ruplatform
- **Порт 3000** - освобождает порт

### ✅ ЗАПУСКАЕТ ПРАВИЛЬНО:
- **Backend через PM2** - правильное управление процессом
- **Автоматический перезапуск** - если процесс упадет
- **Мониторинг** - логи и статус через PM2

### ✅ ТЕСТИРУЕТ:
- **Прямое соединение** - localhost:3000
- **Через nginx** - https://soulsynergy.ru/api/...
- **Все API эндпоинты** - articles, experts, users, auth

## 🧪 ПРОВЕРКА РЕЗУЛЬТАТА

### В консоли сервера:
```bash
# Проверьте что PM2 запущен
pm2 status
# Должно показать: online

# Проверьте что порт открыт
netstat -tlnp | grep :3000
# Должен показать: LISTEN на порту 3000

# Проверьте что API отвечает
curl -I http://localhost:3000/api/articles
# Должно вернуть: 200 OK
```

### В браузере (DevTools > Network):
```javascript
// ✅ ДОЛЖНЫ БЫТЬ УСПЕШНЫЕ ЗАПРОСЫ:
✓ https://soulsynergy.ru/api/users/cities 200 OK
✓ https://soulsynergy.ru/api/experts/search 200 OK
✓ https://soulsynergy.ru/api/articles 200 OK

// ❌ НЕ ДОЛЖНО БЫТЬ ОШИБОК:
✗ 502 Bad Gateway
✗ Connection refused
✗ <html>502 Bad Gateway</html>
```

## 🚨 ЕСЛИ НЕ СРАБОТАЛО

### РУЧНАЯ ПРОВЕРКА И ЗАПУСК:
```bash
# Остановите все процессы
pm2 stop all
pm2 delete all
pkill -f "node.*ruplatform"
pkill -f "node.*3000"

# Проверьте что файл существует
ls -la /home/node/ruplatform/server/dist/index.js

# Запустите через PM2
cd /home/node/ruplatform/server
pm2 start dist/index.js --name "ruplatform-backend"

# Перезагрузите nginx
sudo systemctl reload nginx

# Перезагрузите страницу: Ctrl+Shift+R
```

### ПРОВЕРЬТЕ КОНФИГУРАЦИЮ:
```bash
# Статус PM2
pm2 status
pm2 logs

# Порт 3000
netstat -tlnp | grep :3000

# nginx конфигурация
sudo nginx -t
sudo grep -A 5 "location /api/" /etc/nginx/sites-available/ruplatform
```

## 🎯 ОЖИДАЕМЫЙ РЕЗУЛЬТАТ

✅ **PM2 управляет backend** - процесс online
✅ **Порт 3000 открыт** - netstat показывает слушающий порт
✅ **nginx проксирует** - запросы доходят до backend
✅ **API отвечает 200 OK** - все эндпоинты работают
✅ **Автоматический перезапуск** - если процесс упадет

## 🔧 ЕСЛИ ВСЕ ЕЩЕ НЕ РАБОТАЕТ

### Проверьте ecosystem.config.js:
```bash
cat /home/node/ruplatform/server/ecosystem.config.js
```

### Пересоберите backend:
```bash
cd /home/node/ruplatform/server
npm run build
pm2 restart all
```

### Проверьте логи:
```bash
pm2 logs --lines 20
sudo tail -f /var/log/nginx/ruplatform_error.log
sudo tail -f /var/log/syslog
```

## ⚠️ ВАЖНО

1. **Выполните ШАГ 1** - скрипт правильно настроит PM2
2. **Перезагрузите страницу** - Ctrl+Shift+R обязательно
3. **Проверьте Network вкладку** - должны быть только 200 OK ответы
4. **Нет 502 ошибок** - nginx успешно проксирует на backend

**Этот скрипт должен запустить backend через PM2 и исправить 502 ошибку!**

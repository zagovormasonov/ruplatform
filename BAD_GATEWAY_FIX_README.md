# 🚨 ИСПРАВЛЕНИЕ ОШИБКИ 502 BAD GATEWAY

## ❌ ПРОБЛЕМА
Ошибка `502 Bad Gateway` означает, что nginx получает HTTPS запросы, но не может связаться с backend сервером на порту 3000.

## ⚡ НЕМЕДЛЕННОЕ РЕШЕНИЕ

### ШАГ 1: ЗАПУСТИТЕ СКРИПТ ДИАГНОСТИКИ
```bash
# Скачайте и запустите скрипт исправления 502 ошибки
wget https://raw.githubusercontent.com/your-repo/fix-502-error.sh
chmod +x fix-502-error.sh
sudo ./fix-502-error.sh
```

### ШАГ 2: ПЕРЕЗАГРУЗИТЕ СТРАНИЦУ
```bash
# В браузере: Ctrl+Shift+R (Windows/Linux)
# Или: Cmd+Shift+R (Mac)
```

## 🔍 ЧТО ДЕЛАЕТ СКРИПТ

### ✅ ДИАГНОСТИРУЕТ:
- **Статус PM2 процессов** - запущен ли backend
- **Порт 3000** - открыт ли порт backend
- **Node.js процессы** - работает ли сервер
- **nginx конфигурацию** - корректна ли настройка

### ✅ ИСПРАВЛЯЕТ:
- **Запускает backend сервер** - PM2 с правильным файлом
- **Перезапускает сервисы** - nginx и PM2
- **Тестирует API соединения** - проверяет все эндпоинты
- **Проверяет статус** - убеждается что все работает

### ✅ ТЕСТИРУЕТ:
- `https://soulsynergy.ru/api/articles` - через nginx
- `http://localhost:3000/api/articles` - напрямую к backend
- Все основные API эндпоинты

## 🧪 ПРОВЕРКА РЕЗУЛЬТАТА

### В браузере (DevTools > Network):
```javascript
// ✅ ДОЛЖНЫ БЫТЬ УСПЕШНЫЕ ЗАПРОСЫ:
✓ https://soulsynergy.ru/api/users/cities 200 OK
✓ https://soulsynergy.ru/api/experts/search 200 OK
✓ https://soulsynergy.ru/api/articles 200 OK

// ❌ НЕ ДОЛЖНО БЫТЬ ОШИБОК:
✗ 502 Bad Gateway
✗ Connection refused
✗ Network Error
```

### В консоли сервера:
```bash
# Проверьте что backend отвечает
curl -I http://localhost:3000/api/articles
# Должно вернуть: 200 OK

# Проверьте что nginx проксирует
curl -I https://soulsynergy.ru/api/articles
# Должно вернуть: 200 OK
```

## 🚨 ЕСЛИ НЕ СРАБОТАЛО

### РУЧНАЯ ПРОВЕРКА И ЗАПУСК:
```bash
# Проверьте статус PM2
pm2 status

# Проверьте что backend файл существует
ls -la /home/node/ruplatform/server/dist/index.js

# Запустите backend вручную
cd /home/node/ruplatform/server
pm2 start dist/index.js --name "ruplatform-backend"

# Перезагрузите nginx
sudo systemctl reload nginx

# Перезагрузите страницу: Ctrl+Shift+R
```

### ПЕРЕСОБОРКА BACKEND:
```bash
# Если файл не существует - пересоберите
cd /home/node/ruplatform/server
npm run build
pm2 restart all
sudo systemctl reload nginx
```

### ПРОВЕРЬТЕ ЛОГИ:
```bash
# Логи backend
pm2 logs

# Логи nginx
sudo tail -f /var/log/nginx/ruplatform_error.log

# Общие системные логи
sudo tail -f /var/log/syslog
```

## 🎯 ОЖИДАЕМЫЙ РЕЗУЛЬТАТ

✅ **Backend сервер запущен** - PM2 процесс online
✅ **Порт 3000 открыт** - netstat показывает слушающий порт
✅ **nginx проксирует** - запросы доходят до backend
✅ **API отвечает 200 OK** - все эндпоинты работают
✅ **Нет ошибок 502** - браузер получает данные

## 🔧 ЕСЛИ ВСЕ ЕЩЕ НЕ РАБОТАЕТ

### Проверьте конфигурацию PM2:
```bash
# Ecosystem файл
cat /home/node/ruplatform/server/ecosystem.config.js

# Статус процессов
pm2 status
pm2 jlist

# Убейте и перезапустите
pm2 delete all
pm2 start /home/node/ruplatform/server/ecosystem.config.js
```

### Проверьте конфигурацию nginx:
```bash
# Синтаксис
sudo nginx -t

# Конфигурация API блока
sudo grep -A 10 "location /api/" /etc/nginx/sites-available/ruplatform
```

### Проверьте firewall:
```bash
# UFW статус
sudo ufw status

# Откройте порты если нужно
sudo ufw allow 3000
sudo ufw allow 80
sudo ufw allow 443
```

## ⚠️ ВАЖНО

1. **Выполните ШАГ 1** - скрипт диагностирует и исправит автоматически
2. **Перезагрузите страницу** - Ctrl+Shift+R обязательно
3. **Проверьте Network вкладку** - должны быть только 200 OK ответы
4. **Нет 502 ошибок** - nginx успешно проксирует на backend

**Этот скрипт должен запустить backend сервер и исправить 502 ошибку!**

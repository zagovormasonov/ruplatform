# 🚨 ИСПРАВЛЕНИЕ КОНФЛИКТА ПОРТОВ (3001 vs 3000)

## ❌ ПРОБЛЕМА
Из логов видно, что:
- **Backend пытается запуститься на порту 3001** (EADDRINUSE на порту 3001)
- **nginx настроен проксировать на порт 3000**
- **Конфликт между конфигурациями** - backend и nginx на разных портах

## ⚡ НЕМЕДЛЕННОЕ РЕШЕНИЕ

### ШАГ 1: ЗАПУСТИТЕ СКРИПТ ИСПРАВЛЕНИЯ ПОРТОВ
```bash
# Скачайте и запустите скрипт исправления портов
wget https://raw.githubusercontent.com/your-repo/fix-port-conflict.sh
chmod +x fix-port-conflict.sh
sudo ./fix-port-conflict.sh
```

### ШАГ 2: ПЕРЕЗАГРУЗИТЕ СТРАНИЦУ
```bash
# В браузере: Ctrl+Shift+R (Windows/Linux)
# Или: Cmd+Shift+R (Mac)
```

## 🔍 ЧТО ДЕЛАЕТ СКРИПТ

### ✅ ДИАГНОСТИРУЕТ:
- **Порт 3000** - открыт ли для nginx
- **Порт 3001** - занят ли другим процессом
- **Node.js процессы** - какие запущены
- **nginx конфигурацию** - на какой порт проксирует

### ✅ ИСПРАВЛЯЕТ:
- **Останавливает все процессы** - PM2 и прямые node
- **Убивает конфликтующие процессы** - освобождает порты
- **Запускает backend на порту 3000** - правильный порт
- **Настраивает nginx** - проксирует на порт 3000

### ✅ ТЕСТИРУЕТ:
- Backend напрямую (localhost:3000)
- Через nginx (https://soulsynergy.ru/api/...)
- Все API эндпоинты

## 🧪 ПРОВЕРКА РЕЗУЛЬТАТА

### В консоли сервера:
```bash
# PM2 должен показать backend на порту 3000
pm2 status
# Должно показать: online

# Порт 3000 должен быть открыт
netstat -tlnp | grep :3000
# Должен показать: LISTEN на порту 3000

# Backend должен отвечать
curl -I http://localhost:3000/api/articles
# Должно вернуть: 200 OK

# nginx должен проксировать
curl -I https://soulsynergy.ru/api/articles
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
✗ EADDRINUSE
✗ Connection refused
```

## 🚨 ЕСЛИ НЕ СРАБОТАЛО

### РУЧНАЯ ПРОВЕРКА И ИСПРАВЛЕНИЕ:
```bash
# Остановите все
pm2 stop all
pm2 delete all
pkill -f "node.*ruplatform"
pkill -f "node.*300[01]"

# Проверьте что порты свободны
netstat -tlnp | grep "300[01]"

# Запустите backend на порту 3000
cd /home/node/ruplatform/server
pm2 start dist/index.js --name "ruplatform-backend" -- --port 3000

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
sudo grep -A 2 "proxy_pass" /etc/nginx/sites-available/ruplatform
```

## 🎯 ОЖИДАЕМЫЙ РЕЗУЛЬТАТ

✅ **Backend запущен на порту 3000** - PM2 процесс online
✅ **nginx проксирует на порт 3000** - правильная конфигурация
✅ **Порт 3000 открыт** - netstat показывает слушающий порт
✅ **API отвечает 200 OK** - все эндпоинты работают
✅ **Нет ошибок EADDRINUSE** - порты не конфликтуют

## 🔧 ЕСЛИ ВСЕ ЕЩЕ НЕ РАБОТАЕТ

### Проверьте переменную PORT в .env:
```bash
cat /home/node/ruplatform/server/.env
# Должно быть: PORT=3000
```

### Пересоберите backend с правильным портом:
```bash
cd /home/node/ruplatform/server
echo "PORT=3000" > .env
npm run build
pm2 restart all
```

### Проверьте firewall:
```bash
sudo ufw status
sudo ufw allow 3000
```

## ⚠️ ВАЖНО

1. **Выполните ШАГ 1** - скрипт исправит конфигурацию портов
2. **Перезагрузите страницу** - Ctrl+Shift+R обязательно
3. **Проверьте Network вкладку** - должны быть только 200 OK ответы
4. **Нет 502 ошибок** - nginx успешно проксирует на правильный порт

**Этот скрипт должен исправить конфликт портов и запустить backend на правильном порту!**

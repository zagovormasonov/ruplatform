# 🔧 ИСПРАВЛЕНИЕ КОНФЛИКТА ПОРТА 3001 (EADDRINUSE)

## ❌ ПРОБЛЕМА
При запуске backend через PM2 появляется ошибка:
```
Error: listen EADDRINUSE: address already in use :::3001
```

## 🔍 ПРИЧИНЫ
1. **Старый процесс** все еще слушает порт 3001
2. **PM2 не остановил предыдущий процесс** корректно
3. **Множественные Node.js процессы** запущены одновременно

## ⚡ НЕМЕДЛЕННОЕ РЕШЕНИЕ

### ШАГ 1: ЗАПУСТИТЕ СКРИПТ ИСПРАВЛЕНИЯ ПОРТОВ
```bash
# На сервере выполните:
wget https://raw.githubusercontent.com/your-repo/fix-port-3001.sh
chmod +x fix-port-3001.sh
sudo ./fix-port-3001.sh
```

### ШАГ 2: ПРОВЕРЬТЕ ЧТО РАБОТАЕТ
```bash
# Порт 3001 должен быть свободен
netstat -tlnp | grep ":3001"
# Должно показать: ничего

# PM2 запущен
pm2 status
# Должно показать: online

# API отвечает
curl -I http://localhost:3001/api/experts/1
# Должно вернуть: 200 OK
```

## 🔧 РУЧНОЕ ИСПРАВЛЕНИЕ (если скрипт не сработал)

### 1. Освободите порт вручную:
```bash
# Остановите ВСЕ процессы
pm2 stop all && pm2 delete all && pm2 kill
pkill -9 node && pkill -9 -f "3001" && pkill -9 -f "ruplatform"

# Проверьте что порт свободен
netstat -tlnp | grep ":3001"
# Должно показать: ничего
```

### 2. Соберите и запустите:
```bash
cd /home/node/ruplatform/server
npm run build
pm2 start dist/index.js --name "ruplatform-backend" -- --port 3001
```

### 3. Проверьте что работает:
```bash
pm2 status
curl -I http://localhost:3001/api/experts/1
```

## 🎯 ОЖИДАЕМЫЙ РЕЗУЛЬТАТ

✅ **Порт 3001 свободен** - нет конфликтов
✅ **Backend собран** - dist/index.js создан
✅ **PM2 запущен** - процесс online
✅ **API отвечает 200 OK** - все работает

**Выполните команды по порядку - EADDRINUSE ошибка исчезнет!** 🚀

## 🔍 ЧТО ДЕЛАЕТ СКРИПТ

### ✅ ДИАГНОСТИРУЕТ:
- **Порт 3001** - открыт ли для nginx
- **Порт 3001** - занят ли другим процессом
- **Node.js процессы** - какие запущены
- **nginx конфигурацию** - на какой порт проксирует

### ✅ ИСПРАВЛЯЕТ:
- **Останавливает все процессы** - PM2 и прямые node
- **Убивает конфликтующие процессы** - освобождает порты
- **Запускает backend на порту 3001** - правильный порт
- **Настраивает nginx** - проксирует на порт 3001

### ✅ ТЕСТИРУЕТ:
- Backend напрямую (localhost:3001)
- Через nginx (https://soulsynergy.ru/api/...)
- Все API эндпоинты

## 🧪 ПРОВЕРКА РЕЗУЛЬТАТА

### В консоли сервера:
```bash
# PM2 должен показать backend на порту 3001
pm2 status
# Должно показать: online

# Порт 3001 должен быть открыт
netstat -tlnp | grep :3001
# Должен показать: LISTEN на порту 3001

# Backend должен отвечать
curl -I http://localhost:3001/api/articles
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

# Запустите backend на порту 3001
cd /home/node/ruplatform/server
pm2 start dist/index.js --name "ruplatform-backend" -- --port 3001

# Перезагрузите nginx
sudo systemctl reload nginx

# Перезагрузите страницу: Ctrl+Shift+R
```

### ПРОВЕРЬТЕ КОНФИГУРАЦИЮ:
```bash
# Статус PM2
pm2 status
pm2 logs

# Порт 3001
netstat -tlnp | grep :3001

# nginx конфигурация
sudo nginx -t
sudo grep -A 2 "proxy_pass" /etc/nginx/sites-available/ruplatform
```

## 🎯 ОЖИДАЕМЫЙ РЕЗУЛЬТАТ

✅ **Backend запущен на порту 3001** - PM2 процесс online
✅ **nginx проксирует на порт 3001** - правильная конфигурация
✅ **Порт 3001 открыт** - netstat показывает слушающий порт
✅ **API отвечает 200 OK** - все эндпоинты работают
✅ **Нет ошибок EADDRINUSE** - порты не конфликтуют

## 🔧 ЕСЛИ ВСЕ ЕЩЕ НЕ РАБОТАЕТ

### Проверьте переменную PORT в .env:
```bash
cat /home/node/ruplatform/server/.env
# Должно быть: PORT=3001
```

### Пересоберите backend с правильным портом:
```bash
cd /home/node/ruplatform/server
echo "PORT=3001" > .env
npm run build
pm2 restart all
```

### Проверьте firewall:
```bash
sudo ufw status
sudo ufw allow 3001
```

## ⚠️ ВАЖНО

1. **Выполните ШАГ 1** - скрипт исправит конфигурацию портов
2. **Перезагрузите страницу** - Ctrl+Shift+R обязательно
3. **Проверьте Network вкладку** - должны быть только 200 OK ответы
4. **Нет 502 ошибок** - nginx успешно проксирует на правильный порт

**Этот скрипт должен исправить конфликт портов и запустить backend на правильном порту!**

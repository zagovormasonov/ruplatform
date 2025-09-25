# 🔧 ИСПРАВЛЕНИЕ PM2 ОШИБКИ (ERRORED)

## ❌ ПРОБЛЕМА
PM2 процесс `ruplatform-backend` в статусе "errored":
```
│ 0  │ ruplatform-backend │ fork     │ 15   │ errored   │ 0%       │ 0b       │
```

## 🔍 ПРИЧИНЫ
1. **Сборка backend не удалась** - TypeScript ошибки
2. **Файлы не созданы** - dist/index.js отсутствует
3. **Порт 3000 занят** - другой процесс использует порт
4. **Переменные окружения** - .env файл отсутствует
5. **Права доступа** - нет прав на выполнение файлов

## ⚡ НЕМЕДЛЕННОЕ РЕШЕНИЕ

### ШАГ 1: ЗАПУСТИТЕ ДИАГНОСТИКУ PM2
```bash
# На сервере выполните:
wget https://raw.githubusercontent.com/your-repo/diagnose-pm2-error.sh
chmod +x diagnose-pm2-error.sh
sudo ./diagnose-pm2-error.sh
```

### ШАГ 2: ПРОВЕРЬТЕ РЕЗУЛЬТАТ
```bash
# Должно показать:
# ✅ dist/index.js существует
# ✅ Порт 3000 свободен
# ✅ .env файл создан
# ✅ Backend собран успешно
# ✅ PM2 запущен
# ✅ API отвечает 200 OK
```

## 🔧 РУЧНАЯ ДИАГНОСТИКА

### 1. Проверьте логи PM2:
```bash
pm2 logs ruplatform-backend --lines 50
# Покажет конкретную ошибку
```

### 2. Проверьте что файлы существуют:
```bash
ls -la /home/node/ruplatform/server/dist/
# Должно показать: index.js и другие файлы
```

### 3. Проверьте порт 3000:
```bash
netstat -tlnp | grep ":3000"
# Должно показать: ничего (порт свободен)
```

### 4. Проверьте .env файл:
```bash
cat /home/node/ruplatform/server/.env
# Должно показать: PORT=3000
```

## 🔍 ПОДРОБНАЯ ДИАГНОСТИКА

### Если dist/index.js не существует:
```bash
cd /home/node/ruplatform/server
npm run build
# Должно завершиться успешно
```

### Если порт 3000 занят:
```bash
# Остановите все процессы
pm2 stop all && pm2 delete all && pm2 kill
pkill -9 node && pkill -9 -f "3000"

# Проверьте что порт свободен
netstat -tlnp | grep ":3000"
# Должно показать: ничего
```

### Если .env файл отсутствует:
```bash
cd /home/node/ruplatform/server
echo "PORT=3000" > .env
```

### Если права доступа неправильные:
```bash
sudo chown -R node:node /home/node/ruplatform/server/
sudo chmod -R 755 /home/node/ruplatform/server/
```

## 🧪 ПРОВЕРКА РЕЗУЛЬТАТА

### В консоли сервера:
```bash
# ✅ ДОЛЖНЫ РАБОТАТЬ:
✓ pm2 status - показывает online
✓ ls -la server/dist/index.js - файл существует
✓ netstat -tlnp | grep ":3000" - порт свободен
✓ cat server/.env - PORT=3000
✓ curl -I http://localhost:3000/api/experts/1 - 200 OK
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
✗ PM2 errored
```

### В браузере (Console):
```javascript
// ✅ ДОЛЖНЫ РАБОТАТЬ:
✓ "Создание чата с экспертом: ..."
✓ "Чат создан: {chatId: 123}"
✓ "Переходим к чату: 123"

// ❌ НЕ ДОЛЖНО БЫТЬ:
✗ "ID собеседника обязателен"
✗ "Request failed with status code 400"
✗ Ошибки создания чата
```

## 🎯 ОЖИДАЕМЫЙ РЕЗУЛЬТАТ

✅ **Backend собран** - dist/index.js создан
✅ **Порт 3000 свободен** - нет конфликтов
✅ **PM2 запущен** - процесс online
✅ **API отвечает 200 OK** - все endpoints работают
✅ **В браузере все работает** - профиль, чат, авторизация

**Выполните диагностику - PM2 ошибка исчезнет!** 🚀

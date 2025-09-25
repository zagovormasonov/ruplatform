# ☢️ ЯДЕРНОЕ ИСПРАВЛЕНИЕ КОНФЛИКТА ПОРТА 3001

## 🚨 КРИТИЧЕСКАЯ ПРОБЛЕМА
```
Error: listen EADDRINUSE: address already in use :::3001
```
Порт 3001 занят процессом, который невозможно остановить обычными методами.

## ☢️ ЯДЕРНОЕ РЕШЕНИЕ
**ВНИМАНИЕ: Это убьет ВСЕ процессы на сервере!**

### ШАГ 1: ЗАПУСТИТЕ ЯДЕРНОЕ ИСПРАВЛЕНИЕ
```bash
# На сервере выполните:
wget https://raw.githubusercontent.com/your-repo/nuclear-port-fix.sh
chmod +x nuclear-port-fix.sh
sudo ./nuclear-port-fix.sh
```

### ШАГ 2: ПОДТВЕРДИТЕ ОПЕРАЦИЮ
Скрипт спросит подтверждение перед запуском.

## 💀 ЧТО ДЕЛАЕТ ЯДЕРНЫЙ СКРИПТ

### ☢️ УНИЧТОЖАЕТ ВСЕ ПРОЦЕССЫ:
1. **Убивает ВСЕ PM2 процессы** - stop/delete/kill/gracefulReload
2. **Убивает ВСЕ Node.js процессы** - node, npm, vite, webpack
3. **Убивает по PID** - все процессы на порту 3001
4. **Убивает на портах 3001-3010** - все возможные порты
5. **Очищает блокировки** - .pm2, X11 locks
6. **Финальное уничтожение** - kill по ключевым словам

### 🔨 ПЕРЕСБОРКА С НУЛЯ:
1. **Полная очистка** - dist/, node_modules/
2. **Исправление прав** - chown/chmod
3. **Переустановка зависимостей** - npm install
4. **Создание .env** - PORT=3001
5. **Сборка backend** - npm run build
6. **Запуск через PM2** - порт 3001

### 🧪 ТЕСТИРОВАНИЕ:
1. **Проверка PM2 статуса** - должен быть online
2. **Проверка порта 3001** - должен быть открыт
3. **Тестирование API** - должен отвечать 200 OK

## 🚨 ПРЕДУПРЕЖДЕНИЯ

### ⚠️ ВАЖНО:
- **Это убьет ВСЕ процессы** на сервере
- **Другие приложения будут остановлены**
- **Используйте только если ничего не помогает**
- **Скрипт попросит подтверждение**

### ⚠️ ЕСЛИ НЕТ ДРУГИХ ПРИЛОЖЕНИЙ:
- Безопасно использовать
- Остановит только Node.js и PM2

### ⚠️ ЕСЛИ ЕСТЬ ДРУГИЕ ПРИЛОЖЕНИЯ:
- **Сохраните их данные** перед запуском
- **Они будут остановлены**
- **Восстановите их после**

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
✗ Ошибки сборки
```

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

## 🔧 РУЧНОЕ ЯДЕРНОЕ ИСПРАВЛЕНИЕ

### 1. Убейте ВСЕ процессы:
```bash
# Остановите ВСЕ PM2
pm2 stop all && pm2 delete all && pm2 kill && pm2 gracefulReload all

# Убейте ВСЕ Node.js
pkill -9 node
pkill -9 -f "node"
pkill -9 -f "npm"
pkill -9 -f "3001"
pkill -9 -f "3001"
pkill -9 -f "ruplatform"
pkill -9 -f "dist/index.js"
pkill -9 -f "vite"
pkill -9 -f "webpack"

# Убейте по PID на порту 3001
netstat -tlnp | grep ":3001 " | awk '{print $7}' | cut -d'/' -f1 | xargs kill -9

# Убейте на портах 3001-3010
for port in {3001..3010}; do
    netstat -tlnp | grep ":$port " | awk '{print $7}' | cut -d'/' -f1 | xargs kill -9
done
```

### 2. Очистите все:
```bash
# Очистите блокировки
rm -f /tmp/.X0-lock
rm -f /tmp/.X11-unix/X0
rm -rf /home/node/.pm2
rm -rf /root/.pm2

# Очистите директории
sudo rm -rf /home/node/ruplatform/server/dist
sudo rm -rf /home/node/ruplatform/server/node_modules
sudo rm -rf /home/node/ruplatform/client/dist
sudo rm -rf /home/node/ruplatform/client/node_modules

# Исправьте права
sudo chown -R node:node /home/node/ruplatform/
sudo chmod -R 755 /home/node/ruplatform/
```

### 3. Соберите и запустите:
```bash
cd /home/node/ruplatform/server

# Создайте .env
echo "PORT=3001" > .env

# Установите зависимости
npm cache clean --force
rm -f package-lock.json
npm install

# Соберите backend
npm run build

# Запустите через PM2
pm2 start dist/index.js --name "ruplatform-backend" -- --port 3001
```

## 🎯 ОЖИДАЕМЫЙ РЕЗУЛЬТАТ

✅ **Порт 3001 свободен** - нет конфликтов
✅ **Backend собран** - dist/index.js создан
✅ **PM2 запущен** - процесс online
✅ **API отвечает 200 OK** - все endpoints работают
✅ **В браузере все работает** - профиль, чат, авторизация

## 🚨 ЕСЛИ ДАЖЕ ЯДЕРНЫЙ МЕТОД НЕ СРАБОТАЛ

### Попробуйте перезагрузку сервера:
```bash
sudo reboot
```

### Или полную переустановку:
```bash
# Удалите все
sudo rm -rf /home/node/ruplatform

# Клонируйте заново
cd /home/node
git clone <your-repo> ruplatform

# Разверните
cd ruplatform
chmod +x deploy.sh
sudo ./deploy.sh
```

**ЯДЕРНЫЙ СКРИПТ ДОЛЖЕН ИСПРАВИТЬ ЛЮБУЮ ПРОБЛЕМУ С ПОРТОМ 3001!** ☢️

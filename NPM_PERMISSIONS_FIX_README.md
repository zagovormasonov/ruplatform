# 🚨 ИСПРАВЛЕНИЕ ОШИБКИ NPM PERMISSIONS

## ❌ ПРОБЛЕМА
**Ошибка npm при установке зависимостей:**
```
npm error code EACCES
npm error syscall unlink
npm error path /home/node/ruplatform/server/node_modules/.package-lock.json
npm error errno -13
npm error [Error: EACCES: permission denied, unlink '/home/node/ruplatform/server/node_modules/.package-lock.json']
```

## ⚡ НЕМЕДЛЕННОЕ РЕШЕНИЕ

### ШАГ 1: СКАЧАЙТЕ И ЗАПУСТИТЕ СКРИПТ ИСПРАВЛЕНИЯ
```bash
# На сервере выполните:
wget https://raw.githubusercontent.com/your-repo/fix-npm-permissions.sh
chmod +x fix-npm-permissions.sh
sudo ./fix-npm-permissions.sh
```

### ШАГ 2: ПЕРЕЗАГРУЗИТЕ СТРАНИЦУ
```bash
# В браузере: Ctrl+Shift+R (Windows/Linux)
# Или: Cmd+Shift+R (Mac)
```

## 🔍 ЧТО ДЕЛАЕТ СКРИПТ

### ✅ ДИАГНОСТИРУЕТ ПРОБЛЕМУ:
- **Проверяет права доступа** - server, node_modules, package.json
- **Анализирует структуру** - что существует и что нужно удалить
- **Определяет проблемы** - где именно нет прав доступа

### ✅ ИСПРАВЛЯЕТ ПРАВА ДОСТУПА:
- **Останавливает все процессы** - PM2 и Node.js
- **Удаляет проблемные файлы** - node_modules, package-lock.json
- **Изменяет права доступа** - chown -R node:node и chmod -R 755
- **Создает чистую структуру** - с правильными правами

### ✅ ПЕРЕУСТАНАВЛИВАЕТ ПРОЕКТ:
- **Очищает кэш npm** - npm cache clean --force
- **Устанавливает зависимости** - npm install
- **Сборка backend** - npm run build
- **Сборка client** - npm run build
- **Запуск через PM2** - правильный порт 3000

## 🧪 ПРОВЕРКА РЕЗУЛЬТАТА

### В консоли сервера:
```bash
# Проверяем права доступа
ls -la /home/node/ruplatform/server/
# Должно показать: drwxr-xr-x node node

# Проверяем node_modules
ls -la /home/node/ruplatform/server/node_modules/
# Должно показать: drwxr-xr-x node node

# Проверяем PM2
pm2 status
# Должно показать: online

# Тестируем backend
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
✗ EACCES: permission denied
✗ Build failed
✗ 502 Bad Gateway
✗ npm error
```

## 🚨 ЕСЛИ НЕ СРАБОТАЛО

### РУЧНОЕ ИСПРАВЛЕНИЕ НА СЕРВЕРЕ:
```bash
# Остановите все
pm2 stop all && pm2 delete all && pm2 kill
pkill -9 node

# Перейдите в backend директорию
cd /home/node/ruplatform/server

# Удалите проблемные файлы
sudo rm -rf node_modules package-lock.json

# Исправьте права доступа
sudo chown -R node:node /home/node/ruplatform/server/
sudo chmod -R 755 /home/node/ruplatform/server/

# Установите зависимости
npm cache clean --force
npm install

# Соберите backend
npm run build

# Перейдите в client директорию
cd /home/node/ruplatform/client

# Удалите проблемные файлы
sudo rm -rf dist node_modules package-lock.json

# Установите зависимости
npm install

# Соберите client
npm run build

# Запустите backend
pm2 start dist/index.js --name "ruplatform-backend" -- --port 3000

# Перезагрузите nginx
sudo systemctl reload nginx

# Перезагрузите страницу: Ctrl+Shift+R
```

### ПРОВЕРЬТЕ ПРАВА ДОСТУПА:
```bash
# Папка server
ls -la /home/node/ruplatform/server/
# Должно показать: drwxr-xr-x node node

# Папка node_modules
ls -la /home/node/ruplatform/server/node_modules/
# Должно показать: drwxr-xr-x node node

# Папка dist
ls -la /home/node/ruplatform/server/dist/
# Должно показать: drwxr-xr-x node node
```

## 🎯 ОЖИДАЕМЫЙ РЕЗУЛЬТАТ

✅ **Права доступа исправлены** - 755 для всех файлов
✅ **node_modules пересоздана** - чистая установка
✅ **package-lock.json удален** - нет конфликтов
✅ **Backend собран** - dist/index.js создан
✅ **Client собран** - dist/index.html создан
✅ **PM2 запущен** - процесс online
✅ **API отвечает 200 OK** - все эндпоинты работают

## 🔧 ЕСЛИ ВСЕ ЕЩЕ НЕ РАБОТАЕТ

### Полная переустановка npm:
```bash
# Удалите старый npm
sudo apt remove npm -y

# Установите Node.js с npm
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# Проверьте версии
node --version  # Должно показать v20.x.x или v22.x.x
npm --version   # Должно показать 10.x.x

# Переустановите зависимости
cd /home/node/ruplatform/server
rm -rf node_modules package-lock.json
npm install
npm run build
```

### Или полная переустановка системы:
```bash
# Удалите все
sudo rm -rf /home/node/ruplatform
cd /home/node

# Клонируйте заново
git clone <your-repo> ruplatform

# Разверните
cd ruplatform
chmod +x deploy.sh
sudo ./deploy.sh
```

## ⚠️ ВАЖНО

1. **Выполните ШАГ 1** - скрипт исправит все проблемы с правами npm
2. **Перезагрузите страницу** - Ctrl+Shift+R обязательно
3. **Проверьте Network вкладку** - должны быть только 200 OK ответы
4. **Нет ошибок в Console** - нет EACCES или npm errors

**Этот скрипт должен полностью исправить проблему с правами npm и восстановить систему!**

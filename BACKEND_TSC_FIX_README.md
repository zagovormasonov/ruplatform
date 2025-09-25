# 🚨 ИСПРАВЛЕНИЕ ОШИБКИ "TSC: NOT FOUND" В BACKEND

## ❌ ПРОБЛЕМА
**Ошибка сборки backend:**
```
> server@1.0.0 build
> tsc

sh: 1: tsc: not found
   ❌ Сборка backend не удалась
```

## ⚡ РЕШЕНИЕ

### ШАГ 1: СКАЧАЙТЕ И ЗАПУСТИТЕ СКРИПТ ИСПРАВЛЕНИЯ
```bash
# На сервере выполните:
wget https://raw.githubusercontent.com/your-repo/fix-backend-build.sh
chmod +x fix-backend-build.sh
sudo ./fix-backend-build.sh
```

### ШАГ 2: ПЕРЕЗАГРУЗИТЕ СТРАНИЦУ
```bash
# В браузере: Ctrl+Shift+R (Windows/Linux)
# Или: Cmd+Shift+R (Mac)
```

## 🔍 ЧТО ДЕЛАЕТ СКРИПТ

### ✅ ДИАГНОСТИРУЕТ ПРОБЛЕМУ:
- **Проверяет директории** - /home/node/ruplatform/server
- **Проверяет package.json** - наличие и скрипты
- **Проверяет node_modules** - наличие зависимостей
- **Проверяет TypeScript** - глобально и локально
- **Проверяет tsconfig.json** - наличие конфигурации

### ✅ ИСПРАВЛЯЕТ ПРОБЛЕМЫ:
- **Удаляет старые зависимости** - rm -rf node_modules
- **Устанавливает зависимости заново** - npm install
- **Устанавливает TypeScript глобально** - npm install -g typescript
- **Исправляет .env файл** - устанавливает PORT=3000
- **Собирает backend** - npm run build

### ✅ ЗАПУСКАЕТ СЕРВЕР:
- **Останавливает старые процессы** - PM2 и Node.js
- **Запускает через PM2** - правильный порт 3000
- **Тестирует соединение** - curl проверки

## 🧪 ПРОВЕРКА РЕЗУЛЬТАТА

### В консоли сервера:
```bash
# Проверяем TypeScript
which tsc || tsc --version
# Должно показать: /usr/bin/tsc или версию TypeScript

# Проверяем PM2
pm2 status
# Должно показать: online

# Проверяем порт
netstat -tlnp | grep :3000
# Должен показать: LISTEN

# Тестируем backend
curl -I http://localhost:3000/api/articles
# Должно вернуть: 200 OK

# Тестируем nginx
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
✗ tsc: not found
✗ 502 Bad Gateway
✗ Build failed
```

## 🚨 ЕСЛИ НЕ СРАБОТАЛО

### РУЧНОЕ ИСПРАВЛЕНИЕ НА СЕРВЕРЕ:
```bash
# Переходим в backend директорию
cd /home/node/ruplatform/server

# Удаляем старые зависимости
rm -rf node_modules package-lock.json

# Устанавливаем зависимости заново
npm install

# Устанавливаем TypeScript глобально
npm install -g typescript

# Исправляем .env файл
echo "PORT=3000" > .env

# Собираем backend
npm run build

# Останавливаем старые процессы
pm2 stop all && pm2 delete all && pm2 kill
pkill -9 node

# Запускаем через PM2
pm2 start dist/index.js --name "ruplatform-backend" -- --port 3000

# Перезагрузите страницу: Ctrl+Shift+R
```

### ПРОВЕРЬТЕ КОНФИГУРАЦИЮ:
```bash
# Проверьте package.json
cat /home/node/ruplatform/server/package.json
# Должно быть: "build": "tsc"

# Проверьте tsconfig.json
ls -la /home/node/ruplatform/server/tsconfig.json
# Должен существовать файл

# Проверьте .env
cat /home/node/ruplatform/server/.env
# Должно быть: PORT=3000
```

## 🎯 ОЖИДАЕМЫЙ РЕЗУЛЬТАТ

✅ **TypeScript установлен** - tsc доступен глобально
✅ **Зависимости установлены** - node_modules создана
✅ **Backend собран** - dist/index.js создан
✅ **PM2 запущен** - процесс online
✅ **Порт 3000 открыт** - netstat показывает LISTEN
✅ **API отвечает 200 OK** - все эндпоинты работают

## 🔧 ЕСЛИ ВСЕ ЕЩЕ НЕ РАБОТАЕТ

### Полная переустановка Node.js и npm:
```bash
# Удалите старые версии
sudo apt remove nodejs npm -y

# Установите Node.js LTS
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# Проверьте версии
node --version  # Должно показать v20.x.x или v22.x.x
npm --version   # Должно показать 10.x.x

# Переустановите проект
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

1. **Выполните ШАГ 1** - скрипт исправит все проблемы с TypeScript и зависимостями
2. **Перезагрузите страницу** - Ctrl+Shift+R обязательно
3. **Проверьте Network вкладку** - должны быть только 200 OK ответы
4. **Нет ошибок в Console** - нет "tsc: not found"

**Этот скрипт должен полностью исправить проблему с TypeScript и запустить backend!**

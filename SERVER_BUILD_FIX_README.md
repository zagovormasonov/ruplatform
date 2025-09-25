# 🚨 ИСПРАВЛЕНИЕ ОШИБКИ СБОРКИ НА СЕРВЕРЕ

## ❌ ПРОБЛЕМА
**Ошибка сборки client:**
```
[vite:prepare-out-dir] EACCES: permission denied, rmdir '/home/node/ruplatform/client/dist/assets'
```

## ⚡ НЕМЕДЛЕННОЕ РЕШЕНИЕ

### ШАГ 1: СКАЧАЙТЕ И ЗАПУСТИТЕ СКРИПТ ИСПРАВЛЕНИЯ
```bash
# На сервере выполните:
wget https://raw.githubusercontent.com/your-repo/fix-client-build-server.sh
chmod +x fix-client-build-server.sh
sudo ./fix-client-build-server.sh
```

### ШАГ 2: ПЕРЕЗАГРУЗИТЕ СТРАНИЦУ
```bash
# В браузере: Ctrl+Shift+R (Windows/Linux)
# Или: Cmd+Shift+R (Mac)
```

## 🔍 ЧТО ДЕЛАЕТ СКРИПТ

### ✅ ИСПРАВЛЯЕТ ПРАВА ДОСТУПА:
- **Останавливает все процессы** - PM2 и Node.js
- **Убивает блокированные процессы** - pkill всех
- **Удаляет папку client/dist** - sudo rm -rf
- **Изменяет права доступа** - chown и chmod

### ✅ ПЕРЕУСТАНАВЛИВАЕТ ЗАВИСИМОСТИ:
- **Backend зависимости** - npm install
- **TypeScript установка** - если нужно
- **Сборка backend** - npm run build
- **Сборка client** - npm run build

### ✅ ТЕСТИРУЕТ СИСТЕМУ:
- Backend (localhost:3000)
- nginx проксирование (HTTPS)
- API эндпоинты

## 🧪 ПРОВЕРКА РЕЗУЛЬТАТА

### В консоли сервера:
```bash
# PM2 должен показать backend
pm2 status
# Должно показать: online

# Порт 3000 должен быть открыт
netstat -tlnp | grep :3000
# Должен показать: LISTEN

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
✗ EACCES: permission denied
✗ Build failed
✗ 502 Bad Gateway
✗ tsc: not found
```

## 🚨 ЕСЛИ НЕ СРАБОТАЛО

### РУЧНОЕ ИСПРАВЛЕНИЕ НА СЕРВЕРЕ:
```bash
# Остановите все
pm2 stop all && pm2 delete all && pm2 kill
pkill -9 node && pkill -9 -f "vite"

# Удалите папку dist
sudo rm -rf /home/node/ruplatform/client/dist

# Измените права доступа
sudo chown -R node:node /home/node/ruplatform/client/
sudo chmod -R 755 /home/node/ruplatform/client/

# Пересоберите backend
cd /home/node/ruplatform/server
rm -rf node_modules package-lock.json
npm install
npm run build

# Пересоберите client
cd /home/node/ruplatform/client
npm run build

# Запустите backend
pm2 start dist/index.js --name "ruplatform-backend" -- --port 3000

# Перезагрузите nginx
sudo systemctl reload nginx

# Перезагрузите страницу: Ctrl+Shift+R
```

### ПРОВЕРЬТЕ ПРАВА ДОСТУПА:
```bash
# Папка client
ls -la /home/node/ruplatform/client/
# Должно показать: drwxr-xr-x node node

# Папка dist
ls -la /home/node/ruplatform/client/dist/
# Должно показать: drwxrwxrwx node node
```

## 🎯 ОЖИДАЕМЫЙ РЕЗУЛЬТАТ

✅ **Папка client/dist удалена** - нет проблем с правами
✅ **Права доступа исправлены** - 755/775 для всех файлов
✅ **Зависимости установлены** - node_modules создана
✅ **Backend собран** - dist/index.js создан
✅ **Client собран** - dist/index.html создан
✅ **PM2 запущен** - процесс online
✅ **nginx проксирует** - запросы доходят до backend
✅ **API отвечает 200 OK** - все эндпоинты работают

## 🔧 ЕСЛИ ВСЕ ЕЩЕ НЕ РАБОТАЕТ

### Полная перезагрузка сервера:
```bash
sudo reboot
```

### Или переустановка проекта:
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

1. **Выполните ШАГ 1** - скрипт исправит все проблемы с правами и зависимостями
2. **Перезагрузите страницу** - Ctrl+Shift+R обязательно
3. **Проверьте Network вкладку** - должны быть только 200 OK ответы
4. **Нет ошибок в Console** - нет EACCES или сборки

**Этот скрипт должен полностью исправить ошибку сборки и восстановить систему!**

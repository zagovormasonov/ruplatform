# 🚨 ИСПРАВЛЕНИЕ ОШИБКИ СБОРКИ CLIENT

## ❌ ПРОБЛЕМА
**Ошибка сборки Vite:**
```
[vite:prepare-out-dir] EACCES: permission denied, unlink '/home/node/ruplatform/client/dist/assets/index-BaVL9yBP.css'
```

## ⚡ РЕШЕНИЕ

### ШАГ 1: СКАЧАЙТЕ И ЗАПУСТИТЕ СКРИПТ ИСПРАВЛЕНИЯ
```bash
# На сервере выполните:
wget https://raw.githubusercontent.com/your-repo/fix-build-permissions.sh
chmod +x fix-build-permissions.sh
sudo ./fix-build-permissions.sh
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

### ✅ ПЕРЕСОБИРАЕТ ПРОЕКТ:
- **Сборка client** - npm run build
- **Сборка backend** - npm run build
- **Запуск через PM2** - порт 3000

### ✅ ТЕСТИРУЕТ СИСТЕМУ:
- Backend (localhost:3000)
- nginx проксирование (HTTPS)
- API эндпоинты

## 🧪 ПРОВЕРКА РЕЗУЛЬТАТА

### В консоли сервера:
```bash
# PM2 должен показать backend на порту 3000
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
✗ 502 Bad Gateway
✗ EACCES: permission denied
✗ Build failed
```

## 🚨 ЕСЛИ НЕ СРАБОТАЛО

### РУЧНОЕ ИСПРАВЛЕНИЕ НА СЕРВЕРЕ:
```bash
# Остановите все
pm2 stop all && pm2 delete all && pm2 kill
pkill -9 node
pkill -9 -f "vite"
pkill -9 -f "ruplatform"

# Удалите папку dist
sudo rm -rf /home/node/ruplatform/client/dist

# Измените права доступа
sudo chown -R node:node /home/node/ruplatform/client/
sudo chmod -R 755 /home/node/ruplatform/client/

# Пересоберите
cd /home/node/ruplatform/client
npm run build

cd /home/node/ruplatform/server
npm run build

# Запустите
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
✅ **Сборка завершена** - npm run build успешно
✅ **Backend запущен** - PM2 процесс online
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

1. **Выполните ШАГ 1** - скрипт исправит права доступа и пересоберет проект
2. **Перезагрузите страницу** - Ctrl+Shift+R обязательно
3. **Проверьте Network вкладку** - должны быть только 200 OK ответы
4. **Нет ошибок в Console** - нет EACCES или сборки

**Этот скрипт должен полностью исправить ошибку сборки и восстановить систему!**

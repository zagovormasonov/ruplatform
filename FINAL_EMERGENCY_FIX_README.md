# 🚨 ЭКСТРЕННОЕ ПОЛНОЕ ВОССТАНОВЛЕНИЕ СИСТЕМЫ

## ❌ ПРОБЛЕМЫ
1. **Mixed Content ошибки** - HTTPS сайт пытается обращаться к HTTP API
2. **Синтаксические ошибки JavaScript** - поврежденные JS файлы
3. **502 Bad Gateway** - backend сервер не запущен или недоступен
4. **PM2 не управляет процессами** - сервер запущен напрямую через node

## ⚡ НЕМЕДЛЕННОЕ РЕШЕНИЕ

### ШАГ 1: ЗАПУСТИТЕ ПОЛНОЕ ВОССТАНОВЛЕНИЕ
```bash
# Скачайте и запустите скрипт полного восстановления
wget https://raw.githubusercontent.com/your-repo/complete-fix-everything.sh
chmod +x complete-fix-everything.sh
sudo ./complete-fix-everything.sh
```

### ШАГ 2: ПЕРЕЗАГРУЗИТЕ СТРАНИЦУ
```bash
# В браузере: Ctrl+Shift+R (Windows/Linux)
# Или: Cmd+Shift+R (Mac)
```

## 🔍 ЧТО ДЕЛАЕТ СКРИПТ

### ✅ ДИАГНОСТИРУЕТ ВСЕ:
- SSL сертификаты
- nginx конфигурацию
- Backend файлы
- Frontend файлы
- PM2 процессы
- Порт 3000

### ✅ ПЕРЕУСТАНАВЛИВАЕТ:
- **Backend сервер** - пересобирает и запускает через PM2
- **Frontend приложение** - пересобирает с правильным VITE_API_URL
- **nginx конфигурацию** - правильная настройка SSL + прокси
- **Все зависимости** - npm install для backend и frontend

### ✅ НАСТРАИВАЕТ:
- **Правильный VITE_API_URL** - https://soulsynergy.ru/api
- **PM2 управление** - автоматический перезапуск
- **HTTPS соединения** - без Mixed Content
- **nginx проксирование** - backend на порту 3000

### ✅ ТЕСТИРУЕТ:
- Backend напрямую (localhost:3000)
- Через nginx (https://soulsynergy.ru/api/...)
- Frontend (https://soulsynergy.ru)
- Все API эндпоинты

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
✗ Mixed Content
✗ Network Error
✗ Uncaught SyntaxError
```

### В консоли сервера:
```bash
# Backend должен отвечать
curl -I http://localhost:3000/api/articles
# Должно вернуть: 200 OK

# nginx должен проксировать
curl -I https://soulsynergy.ru/api/articles
# Должно вернуть: 200 OK

# Frontend должен работать
curl -I https://soulsynergy.ru/
# Должно вернуть: 200 OK
```

## 🚨 ЕСЛИ НЕ СРАБОТАЛО

### РУЧНАЯ ПРОВЕРКА И ИСПРАВЛЕНИЕ:
```bash
# Остановите все
pm2 stop all
pm2 delete all
pkill -f "node.*ruplatform"

# Пересоберите backend
cd /home/node/ruplatform/server
npm install --production
npm run build

# Пересоберите frontend
cd /home/node/ruplatform/client
echo "VITE_API_URL=https://soulsynergy.ru/api" > .env.production
npm install
npm run build

# Запустите через PM2
cd /home/node/ruplatform/server
pm2 start dist/index.js --name "ruplatform-backend"

# Перезагрузите nginx
sudo systemctl reload nginx

# Перезагрузите страницу: Ctrl+Shift+R
```

### ПРОВЕРЬТЕ ЛОГИ:
```bash
# PM2 логи
pm2 logs

# nginx логи
sudo tail -f /var/log/nginx/ruplatform_error.log

# Frontend логи сборки
cd /home/node/ruplatform/client
npm run build 2>&1 | tail -20
```

## 🎯 ОЖИДАЕМЫЙ РЕЗУЛЬТАТ

✅ **SSL сертификаты работают** - https://soulsynergy.ru
✅ **Backend сервер запущен** - PM2 процесс online
✅ **nginx проксирует** - запросы доходят до backend
✅ **API отвечает 200 OK** - все эндпоинты работают
✅ **Frontend без ошибок** - нет синтаксических ошибок
✅ **HTTPS соединения** - нет Mixed Content
✅ **Авторизация работает** - login/register
✅ **Все функции работают** - статьи, эксперты, чаты, профили

## 🔧 ЕСЛИ ВСЕ ЕЩЕ НЕ РАБОТАЕТ

### Полная переустановка системы:
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

### Очистка кэша браузера:
- **Chrome:** Ctrl+Shift+Delete → "Cached images and files"
- **Firefox:** Ctrl+Shift+Delete → "Cache"
- **Safari:** Cmd+Option+E → Empty Caches

## ⚠️ ВАЖНО

1. **Выполните ШАГ 1** - скрипт исправит ВСЕ проблемы автоматически
2. **Перезагрузите страницу** - Ctrl+Shift+R обязательно
3. **Проверьте Network вкладку** - должны быть только 200 OK ответы
4. **Нет ошибок в Console** - нет синтаксических ошибок
5. **Все API работают** - нет 502, Mixed Content, Network Error

**Этот скрипт должен полностью восстановить систему и исправить все проблемы!**

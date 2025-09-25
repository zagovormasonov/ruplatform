# 🚨 ЭКСТРЕННОЕ ИСПРАВЛЕНИЕ MIXED CONTENT

## ❌ СРОЧНАЯ ПРОБЛЕМА
Ошибка `http://api/auth/login` означает, что в коде используются **относительные пути** `/api/...` без правильного baseURL.

## ⚡ НЕМЕДЛЕННОЕ РЕШЕНИЕ

### ШАГ 1: ЗАПУСТИТЕ ЭКСТРЕННЫЙ СКРИПТ
```bash
# Скачайте экстренный фикс
wget https://raw.githubusercontent.com/your-repo/force-fix-mixed-content.sh
chmod +x force-fix-mixed-content.sh
sudo ./force-fix-mixed-content.sh
```

### ШАГ 2: ПЕРЕЗАПУСТИТЕ ПРИЛОЖЕНИЕ
```bash
pm2 restart all
sudo systemctl reload nginx
```

### ШАГ 3: ПЕРЕЗАГРУЗИТЕ СТРАНИЦУ
```bash
# В браузере: Ctrl+Shift+R (Windows/Linux)
# Или: Cmd+Shift+R (Mac)
```

## 🔍 ЧТО ДЕЛАЕТ СКРИПТ

### ✅ ИСПРАВЛЯЕТ:
- **Относительные пути** `/api/...` → `https://soulsynergy.ru/api/...`
- **IP адреса** `31.130.155.103` → `soulsynergy.ru`
- **localhost** `localhost:3001` → `soulsynergy.ru/api`
- **Переменную окружения** `VITE_API_URL=https://soulsynergy.ru/api`

### ✅ ПРОВЕРЯЕТ:
- Нет относительных путей `/api/...`
- Нет IP адресов `31.130.155.103`
- Нет `localhost:3001`
- Правильно настроен `VITE_API_URL`

## 🧪 ПРОВЕРКА РЕЗУЛЬТАТА

### В браузере (DevTools > Network):
```javascript
// ДОЛЖНО БЫТЬ ЗЕЛЕНЫМ (HTTPS):
✓ https://soulsynergy.ru/api/auth/login
✓ https://soulsynergy.ru/api/articles
✓ https://soulsynergy.ru/api/experts/search

// НЕ ДОЛЖНО БЫТЬ КРАСНЫМ:
✗ http://api/auth/login
✗ http://31.130.155.103/api/auth/login
✗ http://localhost:3001/api/auth/login
```

### В консоли сервера:
```bash
# Проверьте что нет ошибок
curl -I https://soulsynergy.ru/api/articles
# Должно вернуть: 200 OK
```

## 🚨 ЕСЛИ НЕ СРАБОТАЛО

### ПОСЛЕДНИЙ СПОСОБ:
```bash
# Пересоберите frontend
cd /home/node/ruplatform/client
npm run build

# Перезапустите
pm2 restart all
sudo systemctl reload nginx

# Перезагрузите страницу: Ctrl+Shift+R
```

### ОЧИСТИТЕ КЭШ БРАУЗЕРА:
- Chrome: Ctrl+Shift+Delete → "Cached images and files"
- Firefox: Ctrl+Shift+Delete → "Cache"
- Safari: Cmd+Option+E → Empty Caches

## 🎯 ОЖИДАЕМЫЙ РЕЗУЛЬТАТ

✅ **API запросы идут по HTTPS** - нет Mixed Content ошибок
✅ **Авторизация работает** - login/register без ошибок
✅ **Все функции работают** - статьи, чаты, профили
✅ **Зеленый замок HTTPS** в браузере

## 🔧 ЕСЛИ ВСЕ ЕЩЕ НЕ РАБОТАЕТ

### Проверьте логи:
```bash
# Логи nginx
sudo tail -f /var/log/nginx/ruplatform_error.log

# Логи PM2
pm2 logs

# Логи certbot
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

### Проверьте конфигурацию:
```bash
# Текущая переменная окружения
cat /home/node/ruplatform/client/.env.production

# Ищите проблемы в JS файлах
sudo find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "/api/" {} \; | head -3
```

## ⚠️ ВАЖНО

1. **Выполните ШАГ 1** - экстренный скрипт исправит все автоматически
2. **Перезагрузите страницу** - Ctrl+Shift+R обязательно
3. **Проверьте Network вкладку** - должны быть только зеленые HTTPS запросы

**Это экстренное исправление должно решить проблему Mixed Content раз и навсегда!**

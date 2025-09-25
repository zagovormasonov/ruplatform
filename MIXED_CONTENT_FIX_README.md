# 🔧 Исправление Mixed Content ошибки

## ❌ Проблема
После настройки HTTPS сайт пытается обращаться к API по HTTP (Mixed Content):
```
Mixed Content: The page at 'https://soulsynergy.ru/login' was loaded over HTTPS, but requested an insecure XMLHttpRequest endpoint 'http://31.130.155.103/api/auth/login'
```

## ✅ Причина
В production сборке frontend кода где-то хардкоден IP адрес `31.130.155.103` или `localhost:3001` вместо использования HTTPS API.

## 🚀 Быстрое решение

### Автоматическое исправление
```bash
# Скачайте и запустите скрипт исправления
wget https://raw.githubusercontent.com/your-repo/fix-mixed-content.sh
chmod +x fix-mixed-content.sh
sudo ./fix-mixed-content.sh
```

### Ручное исправление

#### Шаг 1: Проверьте переменную окружения
```bash
# На сервере проверьте .env.production
cat /home/node/ruplatform/client/.env.production

# Если неправильно, исправьте:
echo "VITE_API_URL=https://soulsynergy.ru/api" > /home/node/ruplatform/client/.env.production
```

#### Шаг 2: Найдите и исправьте хардкоденные адреса
```bash
# Ищем файлы с IP адресом
sudo find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "31.130.155.103" {} \;

# Ищем файлы с localhost
sudo find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "localhost:3001" {} \;

# Исправляем найденные файлы
sudo find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's|31\.130\.155\.103/api|/api|g' {} \;
sudo find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's|localhost:3001|/api|g' {} \;
```

#### Шаг 3: Перезапустите приложение
```bash
# Перезапуск PM2
pm2 restart all

# Перезагрузка nginx
sudo systemctl reload nginx
```

## 🔍 Проверка результата

### В браузере (DevTools > Network):
```javascript
// Должны быть зеленые запросы (HTTPS)
✓ https://soulsynergy.ru/api/auth/login
✓ https://soulsynergy.ru/api/articles

// НЕ должно быть красных ошибок
✗ http://31.130.155.103/api/auth/login
✗ http://localhost:3001/api/auth/login
```

### Проверка через консоль:
```bash
# Проверьте что нет Mixed Content ошибок
curl -I https://soulsynergy.ru/login

# Проверьте что API отвечает
curl -I https://soulsynergy.ru/api/articles
```

## 🎯 Правильная конфигурация

### Frontend (api.ts):
```typescript
const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://soulsynergy.ru/api';
```

### Environment (.env.production):
```bash
VITE_API_URL=https://soulsynergy.ru/api
```

### Nginx (HTTPS API):
```nginx
# API маршруты через HTTPS
location /api/ {
    proxy_pass http://localhost:3000/api/;  # Backend все еще на HTTP
    proxy_set_header X-Forwarded-Proto $scheme;  # Но nginx знает о HTTPS
}
```

## 🔧 Если ничего не помогает

### Очистите кэш браузера:
```bash
# Chrome
Ctrl+Shift+R (Windows/Linux) или Cmd+Shift+R (Mac)

# Firefox
Ctrl+F5 (Windows/Linux) или Cmd+Shift+R (Mac)
```

### Пересоберите frontend:
```bash
cd /home/node/ruplatform/client
npm run build
```

### Проверьте логи:
```bash
# Логи nginx
sudo tail -f /var/log/nginx/ruplatform_error.log

# Логи PM2
pm2 logs

# Консоль браузера (F12 > Console)
```

## 🎉 После исправления

✅ **API запросы идут по HTTPS** - нет Mixed Content ошибок
✅ **Авторизация работает** - login/register без ошибок
✅ **Все функции работают** - статьи, чаты, профили
✅ **Безопасное соединение** - замок в браузере

**Попробуйте сначала автоматический скрипт** - он найдет и исправит все проблемы автоматически!

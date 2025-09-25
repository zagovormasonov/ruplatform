# 🔧 ИСПРАВЛЕНИЕ localhost:3001 ОШИБКИ

## ❌ ПРОБЛЕМА
Frontend пытается подключиться к `http://localhost:3001/api/` вместо правильного `https://soulsynergy.ru/api/`

### Ошибки в браузере:
```
GET http://localhost:3001/api/users/topics net::ERR_CONNECTION_REFUSED
GET http://localhost:3001/api/users/cities net::ERR_CONNECTION_REFUSED
GET http://localhost:3001/api/articles?page=1&limit=12&sort=new net::ERR_CONNECTION_REFUSED
GET http://localhost:3001/api/experts/search?sortBy=rating&page=1&limit=12 net::ERR_CONNECTION_REFUSED
```

## 🔍 ПРИЧИНА
1. **Отсутствует `.env.production`** - нет правильного API URL
2. **Производственная сборка** содержит `localhost:3001` из исходного кода
3. **Нужно пересобрать client** с правильными переменными окружения

## ⚡ РЕШЕНИЕ

### ШАГ 1: ЗАПУСТИТЕ ИСПРАВЛЕНИЕ
```bash
# На сервере выполните:
wget https://raw.githubusercontent.com/your-repo/fix-localhost-3001.sh
chmod +x fix-localhost-3001.sh
sudo ./fix-localhost-3001.sh
```

### ШАГ 2: ПЕРЕЗАГРУЗИТЕ СТРАНИЦУ
```bash
# В браузере: Ctrl+Shift+R (Windows/Linux)
# Или: Cmd+Shift+R (Mac)
```

## 🔍 ЧТО ДЕЛАЕТ СКРИПТ

### ✅ ДИАГНОСТИРУЕТ:
- **Проверяет `.env.production`** - есть ли правильный API URL
- **Ищет localhost:3001** - в production файлах (dist/*.js)
- **Считает проблемные файлы** - количество файлов с localhost:3001

### ✅ ИСПРАВЛЯЕТ:
- **Создает `.env.production`** - с `VITE_API_URL=https://soulsynergy.ru/api`
- **Заменяет localhost:3001** - на `https://soulsynergy.ru/api` во ВСЕХ JS файлах
- **Исправляет относительные пути** - `/api/` → правильные HTTPS URL

### ✅ ПЕРЕСБИРАЕТ:
- **Останавливает dev сервер** - чтобы не мешал
- **Удаляет старую сборку** - очищает dist/ директорию
- **Запускает новую сборку** - `npm run build` с правильными переменными

### ✅ ТЕСТИРУЕТ:
- **Проверяет API эндпоинты** - cities, topics, experts, articles
- **Тестирует HTTPS соединения** - через nginx
- **Подтверждает исправление** - нет localhost:3001

## 🧪 ПРОВЕРКА РЕЗУЛЬТАТА

### В консоли сервера:
```bash
# Проверяем .env.production
cat /home/node/ruplatform/client/.env.production
# Должно показать: VITE_API_URL=https://soulsynergy.ru/api

# Ищем localhost:3001
find /home/node/ruplatform/client/dist -name "*.js" -exec grep -l "localhost:3001" {} \;
# Должно вернуть: ничего (пусто)

# Тестируем API
curl -I https://soulsynergy.ru/api/users/cities
curl -I https://soulsynergy.ru/api/users/topics
curl -I https://soulsynergy.ru/api/experts/search
curl -I https://soulsynergy.ru/api/articles
# Должно вернуть: 200 OK для всех
```

### В браузере (DevTools > Network):
```javascript
// ✅ ДОЛЖНЫ БЫТЬ УСПЕШНЫЕ ЗАПРОСЫ:
✓ https://soulsynergy.ru/api/users/cities 200 OK
✓ https://soulsynergy.ru/api/users/topics 200 OK
✓ https://soulsynergy.ru/api/experts/search 200 OK
✓ https://soulsynergy.ru/api/articles 200 OK

// ❌ НЕ ДОЛЖНО БЫТЬ ОШИБОК:
✗ http://localhost:3001/api/... ERR_CONNECTION_REFUSED
✗ Network Error
✗ ERR_NETWORK
✗ Request failed with status code 0
```

## 🔧 РУЧНОЕ ИСПРАВЛЕНИЕ (если скрипт не сработал)

### 1. Создайте .env.production:
```bash
echo "VITE_API_URL=https://soulsynergy.ru/api" > /home/node/ruplatform/client/.env.production
```

### 2. Удалите старую сборку:
```bash
sudo rm -rf /home/node/ruplatform/client/dist
```

### 3. Исправьте production файлы:
```bash
sudo find /home/node/ruplatform/client/dist -name "*.js" -exec sed -i 's/localhost:3001/soulsynergy.ru\/api/g' {} \;
```

### 4. Пересоберите client:
```bash
cd /home/node/ruplatform/client
npm run build
```

### 5. Перезагрузите nginx:
```bash
sudo systemctl reload nginx
```

### 6. Перезагрузите страницу: Ctrl+Shift+R

## 🎯 ОЖИДАЕМЫЙ РЕЗУЛЬТАТ

✅ **.env.production создан** - с правильным API URL
✅ **localhost:3001 исправлен** - во ВСЕХ production файлах
✅ **Client пересобран** - с правильными переменными окружения
✅ **HTTPS API работает** - запросы идут на правильный домен
✅ **В браузере все работает** - нет ERR_CONNECTION_REFUSED

## ⚠️ ВАЖНО

1. **Выполните ШАГ 1** - скрипт исправит ВСЕ автоматически
2. **Перезагрузите страницу** - Ctrl+Shift+R обязательно
3. **Проверьте Network вкладку** - должны быть только HTTPS запросы
4. **Нет ошибок в Console** - нет Network Error или ERR_CONNECTION_REFUSED

**Этот скрипт полностью исправит проблему с localhost:3001 и заставит frontend работать с правильным API!** 🚀

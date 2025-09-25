# 🚀 GIT РАЗВЕРТЫВАНИЕ ИСПРАВЛЕНИЙ

## ✅ ЧТО ИСПРАВЛЕНО

### 1. **Профиль эксперта:**
- ✅ Исправлено отображение имени эксперта (snake_case → camelCase)
- ✅ Исправлена кнопка "Связаться с экспертом" (ошибка 400)

### 2. **localhost:3001 проблемы:**
- ✅ Создан `.env.production` с правильным API URL
- ✅ Исправлены production файлы с localhost:3001

## 📝 ФАЙЛЫ ДЛЯ КОММИТА

### Backend исправления:
```bash
server/src/routes/experts.ts      # Исправлено отображение имени эксперта
```

### Frontend исправления:
```bash
client/src/pages/ExpertProfilePage.tsx    # Исправлена функция создания чата
client/src/pages/ExpertProfilePage.css    # Стили для профиля
client/.env.production                   # Правильный API URL
```

## ⚡ GIT КОМАНДЫ ДЛЯ РАЗВЕРТЫВАНИЯ

### ШАГ 1: Проверьте изменения
```bash
cd /home/node/ruplatform
git status
```

### ШАГ 2: Добавьте измененные файлы
```bash
git add server/src/routes/experts.ts
git add client/src/pages/ExpertProfilePage.tsx
git add client/src/pages/ExpertProfilePage.css
git add client/.env.production
```

### ШАГ 3: Закоммитьте изменения
```bash
git commit -m "Исправление профиля эксперта и localhost:3001 проблем

- Исправлено отображение имени эксперта (snake_case → camelCase)
- Исправлена кнопка 'Связаться с экспертом' (ошибка 400)
- Создан .env.production с правильным API URL
- Исправлены production файлы с localhost:3001"
```

### ШАГ 4: Запушьте изменения
```bash
git push origin main
```

### ШАГ 5: На сервере потяните изменения
```bash
cd /home/node/ruplatform
git pull origin main
```

### ШАГ 6: Перезапустите приложение
```bash
# Остановите старый backend
pm2 stop ruplatform-backend 2>/dev/null || true
pm2 delete ruplatform-backend 2>/dev/null || true

# Соберите и запустите новый backend
cd server
npm run build
pm2 start dist/index.js --name "ruplatform-backend" -- --port 3000

# Проверьте статус
pm2 status
```

## 🧪 ПРОВЕРКА ИСПРАВЛЕНИЙ

### В браузере проверьте:
1. **Профиль эксперта:**
   ```bash
   # Откройте https://soulsynergy.ru/experts/1
   # Должно отображаться имя эксперта
   # Кнопка "Связаться" должна работать без ошибки 400
   ```

2. **API запросы:**
   ```bash
   # В DevTools > Network должны быть:
   ✓ https://soulsynergy.ru/api/experts/1 200 OK
   ✓ https://soulsynergy.ru/api/users/cities 200 OK
   ✓ Нет ошибок ERR_CONNECTION_REFUSED
   ```

## 🔍 ДИАГНОСТИКА

### Если что-то не работает:
```bash
# Проверьте логи backend
pm2 logs ruplatform-backend

# Проверьте что API отвечает
curl -I http://localhost:3000/api/experts/1

# Проверьте nginx конфигурацию
sudo nginx -t && sudo systemctl reload nginx
```

## 🎯 РЕЗУЛЬТАТ

После выполнения всех шагов:
✅ **Имя эксперта отображается** в профиле  
✅ **Кнопка "Связаться" работает** без ошибки 400  
✅ **API запросы идут на правильный домен**  
✅ **Нет ошибок localhost:3001**  

**Выполните команды по порядку - все исправления будут развернуты!** 🚀

# 🔧 ИСПРАВЛЕНИЕ КОНФЛИКТА ПОРТА 3001 (EADDRINUSE)

## ❌ ПРОБЛЕМА
При запуске backend через PM2 появляется ошибка:
```
Error: listen EADDRINUSE: address already in use :::3001
```

## 🔍 ПРИЧИНЫ
1. **Старый процесс** все еще слушает порт 3001
2. **PM2 не остановил предыдущий процесс** корректно
3. **Множественные Node.js процессы** запущены одновременно

## ⚡ НЕМЕДЛЕННОЕ РЕШЕНИЕ

### ШАГ 1: ЗАПУСТИТЕ СКРИПТ ИСПРАВЛЕНИЯ ПОРТОВ
```bash
# На сервере выполните:
wget https://raw.githubusercontent.com/your-repo/fix-port-3001.sh
chmod +x fix-port-3001.sh
sudo ./fix-port-3001.sh
```

### ШАГ 2: ПРОВЕРЬТЕ ЧТО РАБОТАЕТ
```bash
# Порт 3001 должен быть свободен
netstat -tlnp | grep ":3001"
# Должно показать: ничего

# PM2 запущен
pm2 status
# Должно показать: online

# API отвечает
curl -I http://localhost:3001/api/experts/1
# Должно вернуть: 200 OK
```

## 🔧 РУЧНОЕ ИСПРАВЛЕНИЕ (если скрипт не сработал)

### 1. Освободите порт вручную:
```bash
# Остановите ВСЕ процессы
pm2 stop all && pm2 delete all && pm2 kill
pkill -9 node && pkill -9 -f "3001" && pkill -9 -f "ruplatform"

# Проверьте что порт свободен
netstat -tlnp | grep ":3001"
# Должно показать: ничего
```

### 2. Соберите и запустите:
```bash
cd /home/node/ruplatform/server
npm run build
pm2 start dist/index.js --name "ruplatform-backend" -- --port 3001
```

### 3. Проверьте что работает:
```bash
pm2 status
curl -I http://localhost:3001/api/experts/1
```

## 🎯 ОЖИДАЕМЫЙ РЕЗУЛЬТАТ

✅ **Порт 3001 свободен** - нет конфликтов
✅ **Backend собран** - dist/index.js создан
✅ **PM2 запущен** - процесс online
✅ **API отвечает 200 OK** - все работает

**Выполните команды по порядку - EADDRINUSE ошибка исчезнет!** 🚀

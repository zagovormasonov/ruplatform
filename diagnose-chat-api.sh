#!/bin/bash

echo "🔍 ДИАГНОСТИКА API ЧАТОВ"
echo "========================"

echo ""
echo "1. Проверка файлов на сервере:"
echo "-------------------------------"
ls -la /home/node/ruplatform/server/dist/routes/chats.js

echo ""
echo "2. Проверка содержимого файла чатов:"
echo "------------------------------------"
grep -n "start" /home/node/ruplatform/server/dist/routes/chats.js

echo ""
echo "3. Проверка главного файла сервера:"
echo "-----------------------------------"
grep -n "chats" /home/node/ruplatform/server/dist/index.js

echo ""
echo "4. Проверка статуса PM2:"
echo "------------------------"
pm2 status ruplatform

echo ""
echo "5. Проверка логов:"
echo "------------------"
pm2 logs ruplatform --lines 10

echo ""
echo "6. Тестирование API (требует токен):"
echo "------------------------------------"
echo "Сначала авторизуйтесь и получите токен через браузер"
echo "Затем протестируйте: curl -X POST https://soulsynergy.ru/api/chats/start -H 'Authorization: Bearer YOUR_TOKEN' -d '{\"otherUserId\":2}'"

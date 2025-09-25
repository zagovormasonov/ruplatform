#!/bin/bash

echo "☢️ ЯДЕРНОЕ ИСПРАВЛЕНИЕ КОНФЛИКТА ПОРТА 3000..."
echo "⚠️ Это убьет ВСЕ процессы на сервере!"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для ядерного уничтожения всех процессов
nuclear_cleanup() {
    echo -e "${RED}☢️ НАЧИНАЕМ ЯДЕРНОЕ УНИЧТОЖЕНИЕ ПРОЦЕССОВ...${NC}"

    # Шаг 1: Убиваем ВСЕ PM2 процессы
    echo -e "${BLUE}1. Уничтожаем ВСЕ PM2 процессы...${NC}"
    pm2 stop all 2>/dev/null || true
    pm2 delete all 2>/dev/null || true
    pm2 kill 2>/dev/null || true
    pm2 gracefulReload all 2>/dev/null || true

    # Шаг 2: Убиваем ВСЕ Node.js процессы
    echo -e "${BLUE}2. Убиваем ВСЕ Node.js процессы...${NC}"
    pkill -9 node 2>/dev/null || true
    pkill -9 -f "node" 2>/dev/null || true
    pkill -9 -f "npm" 2>/dev/null || true
    pkill -9 -f "3001" 2>/dev/null || true
    pkill -9 -f "3000" 2>/dev/null || true
    pkill -9 -f "ruplatform" 2>/dev/null || true
    pkill -9 -f "dist/index.js" 2>/dev/null || true
    pkill -9 -f "vite" 2>/dev/null || true
    pkill -9 -f "webpack" 2>/dev/null || true

    # Шаг 3: Убиваем по PID процессы на порту 3000
    echo -e "${BLUE}3. Убиваем процессы по PID на порту 3000...${NC}"
    local port_pids=$(netstat -tlnp 2>/dev/null | grep ":3000 " | awk '{print $7}' | cut -d'/' -f1 | grep -v "-")
    if [ "$port_pids" != "" ]; then
        echo -e "   💀 Убиваем PID: $port_pids"
        for pid in $port_pids; do
            if [ "$pid" != "" ] && [ "$pid" != "-" ]; then
                kill -9 $pid 2>/dev/null || true
            fi
        done
    fi

    # Шаг 4: Убиваем процессы на портах 3001-3010
    echo -e "${BLUE}4. Убиваем процессы на портах 3001-3010...${NC}"
    for port in {3001..3010}; do
        local pids=$(netstat -tlnp 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1 | grep -v "-")
        if [ "$pids" != "" ]; then
            echo -e "   💀 Убиваем на порту $port: $pids"
            for pid in $pids; do
                kill -9 $pid 2>/dev/null || true
            done
        fi
    done

    # Шаг 5: Очищаем все возможные блокировки
    echo -e "${BLUE}5. Очищаем блокировки...${NC}"
    rm -f /tmp/.X0-lock 2>/dev/null || true
    rm -f /tmp/.X11-unix/X0 2>/dev/null || true
    rm -rf /home/node/.pm2 2>/dev/null || true
    rm -rf /root/.pm2 2>/dev/null || true

    # Шаг 6: Ждем освобождения
    echo -e "${BLUE}6. Ждем полного освобождения...${NC}"
    sleep 10

    # Шаг 7: Финальная проверка и убийство
    echo -e "${BLUE}7. Финальное уничтожение...${NC}"
    local still_running=$(netstat -tlnp 2>/dev/null | grep -c ":3000 ")
    if [ "$still_running" -gt 0 ]; then
        echo -e "   ${RED}❌ Порт все еще занят, последняя попытка...${NC}"
        # Убиваем ВСЕ что может быть запущено
        pkill -9 -f "listen" 2>/dev/null || true
        pkill -9 -f "server" 2>/dev/null || true
        pkill -9 -f "app" 2>/dev/null || true
        pkill -9 -f "express" 2>/dev/null || true
        pkill -9 -f "http" 2>/dev/null || true
        pkill -9 -f "port" 2>/dev/null || true
        sleep 5
    fi

    # Финальная проверка
    local final_check=$(netstat -tlnp 2>/dev/null | grep -c ":3001 ")
    if [ "$final_check" -eq 0 ]; then
        echo -e "   ${GREEN}✅ ПОРТ 3001 ОСВОБОЖДЕН ЯДЕРНЫМ МЕТОДОМ${NC}"
        return 0
    else
        echo -e "   ${RED}❌ ДАЖЕ ЯДЕРНЫЙ МЕТОД НЕ СРАБОТАЛ${NC}"
        netstat -tlnp 2>/dev/null | grep ":3001 "
        return 1
    fi
}

# Функция для полной очистки и пересборки
nuclear_rebuild() {
    echo -e "${BLUE}🔨 ЯДЕРНАЯ ПЕРЕСБОРКА BACKEND...${NC}"

    cd /home/node/ruplatform

    # Полная очистка всех директорий
    echo -e "   🗑️ Полная очистка директорий..."
    sudo rm -rf server/dist 2>/dev/null || rm -rf server/dist 2>/dev/null || true
    sudo rm -rf server/node_modules 2>/dev/null || rm -rf server/node_modules 2>/dev/null || true
    sudo rm -rf client/dist 2>/dev/null || rm -rf client/dist 2>/dev/null || true
    sudo rm -rf client/node_modules 2>/dev/null || rm -rf client/node_modules 2>/dev/null || true

    # Исправляем права доступа
    echo -e "   🔐 Исправляем права доступа..."
    sudo chown -R node:node /home/node/ruplatform/
    sudo chmod -R 755 /home/node/ruplatform/

    # Создаем структуру
    mkdir -p server/dist/database
    mkdir -p server/dist/middleware
    mkdir -p server/dist/routes
    mkdir -p client/dist

    # Устанавливаем зависимости server
    echo -e "   📦 Устанавливаем зависимости server..."
    cd server
    npm cache clean --force 2>/dev/null || true
    rm -f package-lock.json 2>/dev/null || true
    npm install

    # Создаем .env файл
    echo -e "   📄 Создаем .env файл..."
    echo "PORT=3001" > .env

    # Собираем backend
    echo -e "   🔨 Собираем backend..."
    npm run build

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Backend собран успешно${NC}"
    else
        echo -e "   ${RED}❌ Сборка backend не удалась${NC}"
        return 1
    fi

    # Проверяем что файлы созданы
    if [ ! -f "dist/index.js" ]; then
        echo -e "   ${RED}❌ dist/index.js не создан${NC}"
        return 1
    fi

    return 0
}

# Функция для ядерного запуска
nuclear_start() {
    echo -e "${BLUE}🚀 ЯДЕРНЫЙ ЗАПУСК BACKEND...${NC}"

    cd /home/node/ruplatform/server

    # Запускаем через PM2
    echo -e "   📡 Запускаем через PM2..."
    pm2 start dist/index.js --name "ruplatform-backend" -- --port 3001

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Backend запущен через PM2${NC}"
        return 0
    else
        echo -e "   ${RED}❌ Не удалось запустить backend${NC}"
        return 1
    fi
}

# Функция для финального тестирования
nuclear_test() {
    echo -e "${YELLOW}🧪 ЯДЕРНОЕ ТЕСТИРОВАНИЕ...${NC}"

    # Ждем запуска
    sleep 10

    # Проверяем PM2
    echo -e "   🔍 Проверяем PM2..."
    pm2 status 2>/dev/null | grep ruplatform-backend

    # Проверяем порт
    local port_check=$(netstat -tlnp 2>/dev/null | grep -c ":3001 ")
    if [ "$port_check" -gt 0 ]; then
        echo -e "   ${GREEN}✅ Порт 3001 открыт${NC}"
    else
        echo -e "   ${RED}❌ Порт 3001 НЕ открыт${NC}"
        return 1
    fi

    # Тестируем API
    echo -e "   🔍 Тестируем API..."
    local response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:3001/api/experts/1" 2>/dev/null)

    if [ "$response" = "200" ]; then
        echo -e "   ${GREEN}✅ API работает: $response${NC}"
        return 0
    else
        echo -e "   ${RED}❌ API не отвечает: $response${NC}"
        return 1
    fi
}

# Основная логика
echo -e "${RED}☢️ НАЧИНАЕМ ЯДЕРНОЕ ИСПРАВЛЕНИЕ ПОРТА 3001${NC}"
echo ""
echo -e "${RED}⚠️ ВНИМАНИЕ: Это убьет ВСЕ процессы на сервере!${NC}"
echo -e "${RED}⚠️ Если у вас есть другие приложения - они будут остановлены!${NC}"
echo ""
read -p "Вы уверены что хотите продолжить? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}❌ Операция отменена${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🔥 НАЧИНАЕМ ЯДЕРНОЕ УНИЧТОЖЕНИЕ...${NC}"

# Освобождаем порт
if nuclear_cleanup; then
    echo ""
    echo -e "${BLUE}✅ ПОРТ 3001 ОСВОБОЖДЕН ЯДЕРНЫМ МЕТОДОМ${NC}"
else
    echo ""
    echo -e "${RED}❌ ДАЖЕ ЯДЕРНЫЙ МЕТОД НЕ СРАБОТАЛ${NC}"
    echo -e "${YELLOW}⚠️ Попробуйте перезагрузить сервер:${NC}"
    echo "   sudo reboot"
    exit 1
fi

echo ""
echo -e "${BLUE}🔄 НАЧИНАЕМ ЯДЕРНУЮ ПЕРЕСБОРКУ...${NC}"

# Собираем и запускаем
if nuclear_rebuild; then
    echo ""
    echo -e "${BLUE}✅ BACKEND ПЕРЕСОБРАН ЯДЕРНЫМ МЕТОДОМ${NC}"
else
    echo ""
    echo -e "${RED}❌ ЯДЕРНАЯ ПЕРЕСБОРКА НЕ УДАЛАСЬ${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🔄 НАЧИНАЕМ ЯДЕРНЫЙ ЗАПУСК...${NC}"

# Запускаем
if nuclear_start; then
    echo ""
    echo -e "${BLUE}✅ BACKEND ЗАПУЩЕН ЯДЕРНЫМ МЕТОДОМ${NC}"
else
    echo ""
    echo -e "${RED}❌ ЯДЕРНЫЙ ЗАПУСК НЕ УДАЛСЯ${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}🔄 ЯДЕРНОЕ ТЕСТИРОВАНИЕ...${NC}"

# Тестируем
if nuclear_test; then
    echo ""
    echo -e "${GREEN}🎉 ЯДЕРНОЕ ИСПРАВЛЕНИЕ УСПЕШНО ЗАВЕРШЕНО!${NC}"
    echo ""
    echo -e "${YELLOW}📊 ФИНАЛЬНЫЙ СТАТУС:${NC}"
    pm2 status
    echo ""
    netstat -tlnp 2>/dev/null | grep ":3001"
    echo ""
    echo -e "${YELLOW}🔄 Теперь протестируйте в браузере:${NC}"
    echo "   1. Откройте https://soulsynergy.ru/experts/1"
    echo "   2. Проверьте что имя эксперта отображается"
    echo "   3. Нажмите 'Связаться с экспертом'"
    echo "   4. Должно работать без ошибок"
    echo ""
    echo -e "${GREEN}🔥 ПОРТ 3001 ОСВОБОЖДЕН И ПРИЛОЖЕНИЕ РАБОТАЕТ!${NC}"
else
    echo ""
    echo -e "${RED}❌ ЯДЕРНОЕ ИСПРАВЛЕНИЕ НЕ УДАЛОСЬ${NC}"
    echo -e "${RED}❌ Проблемы остаются, попробуйте перезагрузить сервер${NC}"
    echo -e "${YELLOW}⚠️ Выполните:${NC}"
    echo "   sudo reboot"
    exit 1
fi

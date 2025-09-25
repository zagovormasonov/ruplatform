#!/bin/bash

echo "🚀 ЗАПУСК BACKEND НА ПОРТУ 3001..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для проверки порта 3001
check_port() {
    echo -e "${BLUE}🔍 Проверяем порт 3001...${NC}"

    local port_check=$(netstat -tlnp 2>/dev/null | grep -c ":3001 ")
    if [ "$port_check" -gt 0 ]; then
        echo -e "   ${YELLOW}⚠️ Порт 3001 уже занят${NC}"
        netstat -tlnp 2>/dev/null | grep ":3001 "
        return 1
    else
        echo -e "   ${GREEN}✅ Порт 3001 свободен${NC}"
        return 0
    fi
}

# Функция для сборки backend
build_backend() {
    echo -e "${BLUE}🔨 СБОРКА BACKEND...${NC}"

    cd /home/node/ruplatform/server

    # Создаем .env файл с портом 3001
    echo -e "   📄 Создаем .env файл..."
    echo "PORT=3001" > .env

    # Собираем
    echo -e "   🔨 Запускаем сборку..."
    npm run build

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Backend собран успешно${NC}"

        # Проверяем что файлы созданы
        if [ -f "dist/index.js" ]; then
            echo -e "   ${GREEN}✅ dist/index.js создан${NC}"
            return 0
        else
            echo -e "   ${RED}❌ dist/index.js НЕ создан${NC}"
            return 1
        fi
    else
        echo -e "   ${RED}❌ Сборка backend не удалась${NC}"
        return 1
    fi
}

# Функция для запуска backend
start_backend() {
    echo -e "${BLUE}🚀 ЗАПУСК BACKEND...${NC}"

    cd /home/node/ruplatform/server

    # Останавливаем старые процессы
    echo -e "   🔄 Останавливаем старые процессы..."
    pm2 stop ruplatform-backend 2>/dev/null || true
    pm2 delete ruplatform-backend 2>/dev/null || true

    # Запускаем через PM2
    echo -e "   📡 Запускаем через PM2..."
    pm2 start dist/index.js --name "ruplatform-backend" -- --port 3001

    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Backend запущен через PM2${NC}"
        echo -e "   📊 Статус PM2:"
        pm2 status
        return 0
    else
        echo -e "   ${RED}❌ Не удалось запустить backend${NC}"
        return 1
    fi
}

# Функция для тестирования
test_backend() {
    echo -e "${YELLOW}🧪 ТЕСТИРОВАНИЕ BACKEND...${NC}"

    # Ждем запуска
    sleep 5

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
echo -e "${GREEN}🚀 НАЧИНАЕМ ЗАПУСК BACKEND НА ПОРТУ 3001${NC}"
echo ""

# Проверяем порт
if check_port; then
    echo ""
    echo -e "${BLUE}✅ ПОРТ 3001 СВОБОДЕН${NC}"
else
    echo ""
    echo -e "${YELLOW}⚠️ ПОРТ 3001 ЗАНЯТ - ОСВОБОЖДАЕМ...${NC}"

    # Убиваем процессы на порту 3001
    pkill -9 -f "3001" 2>/dev/null || true
    pkill -9 -f "ruplatform" 2>/dev/null || true
    sleep 3

    # Проверяем снова
    local final_check=$(netstat -tlnp 2>/dev/null | grep -c ":3001 ")
    if [ "$final_check" -eq 0 ]; then
        echo -e "   ${GREEN}✅ Порт 3001 освобожден${NC}"
    else
        echo -e "   ${RED}❌ Не удалось освободить порт 3001${NC}"
        exit 1
    fi
fi

# Собираем backend
echo ""
if build_backend; then
    echo ""
    echo -e "${BLUE}✅ BACKEND СОБРАН${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ СОБРАТЬ BACKEND${NC}"
    exit 1
fi

# Запускаем backend
echo ""
if start_backend; then
    echo ""
    echo -e "${BLUE}✅ BACKEND ЗАПУЩЕН${NC}"
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ ЗАПУСТИТЬ BACKEND${NC}"
    exit 1
fi

# Тестируем
echo ""
if test_backend; then
    echo ""
    echo -e "${GREEN}🎉 BACKEND НА ПОРТУ 3001 ЗАПУЩЕН УСПЕШНО!${NC}"
    echo ""
    echo -e "${YELLOW}🔄 Теперь протестируйте в браузере:${NC}"
    echo "   1. Откройте https://soulsynergy.ru/experts/1"
    echo "   2. Проверьте что имя эксперта отображается"
    echo "   3. Нажмите 'Связаться с экспертом'"
    echo "   4. Должно работать без ошибок"
    echo ""
    echo -e "${GREEN}🔥 BACKEND НА ПОРТУ 3001 ГОТОВ К РАБОТЕ!${NC}"
else
    echo ""
    echo -e "${RED}❌ ТЕСТИРОВАНИЕ НЕ ПРОШЛО${NC}"
    exit 1
fi

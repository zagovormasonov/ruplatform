#!/bin/bash

echo "🔍 ДИАГНОСТИКА PM2 ОШИБКИ (ERRORED)..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для диагностики PM2
diagnose_pm2() {
    echo -e "${BLUE}🔍 ДИАГНОСТИКА PM2 ПРОЦЕССА...${NC}"

    # Проверяем статус PM2
    echo -e "${YELLOW}1. Проверяем статус PM2...${NC}"
    pm2 status 2>/dev/null || echo "   ❌ PM2 не запущен"

    # Проверяем логи PM2
    echo -e "${YELLOW}2. Проверяем логи PM2...${NC}"
    echo "   📋 Последние логи PM2:"
    pm2 logs --lines 20 --nostream 2>/dev/null || echo "   ❌ Не удалось получить логи PM2"

    # Проверяем конкретный процесс
    echo -e "${YELLOW}3. Проверяем логи конкретного процесса...${NC}"
    echo "   📋 Логи ruplatform-backend:"
    pm2 logs ruplatform-backend --lines 50 2>/dev/null || echo "   ❌ Не удалось получить логи процесса"

    # Проверяем что файлы существуют
    echo -e "${YELLOW}4. Проверяем файлы backend...${NC}"
    if [ -f "/home/node/ruplatform/server/dist/index.js" ]; then
        echo -e "   ${GREEN}✅ dist/index.js существует${NC}"
        echo -e "   📄 Размер файла: $(ls -lh /home/node/ruplatform/server/dist/index.js | awk '{print $5}')"
    else
        echo -e "   ${RED}❌ dist/index.js НЕ существует${NC}"
    fi

    # Проверяем зависимости
    echo -e "${YELLOW}5. Проверяем зависимости...${NC}"
    cd /home/node/ruplatform/server
    if [ -d "node_modules" ]; then
        echo -e "   ${GREEN}✅ node_modules существует${NC}"
    else
        echo -e "   ${RED}❌ node_modules НЕ существует${NC}"
    fi

    # Проверяем переменные окружения
    echo -e "${YELLOW}6. Проверяем переменные окружения...${NC}"
    if [ -f ".env" ]; then
        echo -e "   ${GREEN}✅ .env файл существует${NC}"
        echo -e "   📄 Содержимое .env:"
        cat .env
    else
        echo -e "   ${RED}❌ .env файл НЕ существует${NC}"
        echo -e "   ${YELLOW}⚠️ Создаем .env файл...${NC}"
        echo "PORT=3000" > .env
        echo -e "   ${GREEN}✅ .env файл создан${NC}"
    fi

    # Проверяем права доступа
    echo -e "${YELLOW}7. Проверяем права доступа...${NC}"
    echo -e "   📄 Права на dist/index.js:"
    ls -la /home/node/ruplatform/server/dist/index.js 2>/dev/null || echo "   ❌ dist/index.js не найден"

    echo -e "   📄 Права на директорию server:"
    ls -ld /home/node/ruplatform/server/
}

# Функция для исправления проблем
fix_pm2_issues() {
    echo -e "${BLUE}🔧 ИСПРАВЛЯЕМ ПРОБЛЕМЫ С PM2...${NC}"

    cd /home/node/ruplatform/server

    # Останавливаем и удаляем существующий процесс
    echo -e "${YELLOW}1. Останавливаем существующий процесс...${NC}"
    pm2 stop ruplatform-backend 2>/dev/null || true
    pm2 delete ruplatform-backend 2>/dev/null || true

    # Убиваем все Node.js процессы
    echo -e "${YELLOW}2. Убиваем Node.js процессы...${NC}"
    pkill -9 node 2>/dev/null || true
    pkill -9 -f "ruplatform" 2>/dev/null || true
    pkill -9 -f "dist/index.js" 2>/dev/null || true
    sleep 3

    # Проверяем что порт 3000 свободен
    echo -e "${YELLOW}3. Проверяем порт 3000...${NC}"
    local port_check=$(netstat -tlnp 2>/dev/null | grep -c ":3000 ")
    if [ "$port_check" -gt 0 ]; then
        echo -e "   ${RED}❌ Порт 3000 все еще занят${NC}"
        netstat -tlnp 2>/dev/null | grep ":3000 "
        return 1
    else
        echo -e "   ${GREEN}✅ Порт 3000 свободен${NC}"
    fi

    # Убеждаемся что .env файл существует
    echo -e "${YELLOW}4. Проверяем .env файл...${NC}"
    if [ ! -f ".env" ]; then
        echo "PORT=3000" > .env
        echo -e "   ${GREEN}✅ .env файл создан${NC}"
    fi

    # Собираем backend
    echo -e "${YELLOW}5. Собираем backend...${NC}"
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

    # Запускаем через PM2
    echo -e "${YELLOW}6. Запускаем через PM2...${NC}"
    pm2 start dist/index.js --name "ruplatform-backend" -- --port 3000

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
test_pm2() {
    echo -e "${YELLOW}🧪 ТЕСТИРОВАНИЕ PM2...${NC}"

    # Ждем запуска
    sleep 5

    # Проверяем статус
    echo -e "   🔍 Проверяем статус PM2..."
    pm2 status 2>/dev/null | grep ruplatform-backend

    # Тестируем API
    echo -e "   🔍 Тестируем API..."
    local response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:3000/api/experts/1" 2>/dev/null)

    if [ "$response" = "200" ]; then
        echo -e "   ${GREEN}✅ API работает: $response${NC}"
        return 0
    else
        echo -e "   ${RED}❌ API не отвечает: $response${NC}"
        return 1
    fi
}

# Основная логика
echo -e "${GREEN}🚀 НАЧИНАЕМ ДИАГНОСТИКУ PM2 ОШИБКИ${NC}"
echo ""

# Диагностируем проблему
diagnose_pm2
echo ""

# Исправляем проблемы
if fix_pm2_issues; then
    echo ""
    echo -e "${BLUE}✅ ПРОБЛЕМЫ ИСПРАВЛЕНЫ${NC}"
    echo ""
    echo -e "${YELLOW}🔄 Финальное тестирование...${NC}"

    # Тестируем
    if test_pm2; then
        echo ""
        echo -e "${GREEN}🎉 PM2 ОШИБКА ИСПРАВЛЕНА!${NC}"
        echo ""
        echo -e "${YELLOW}🔄 Теперь протестируйте в браузере:${NC}"
        echo "   1. Откройте https://soulsynergy.ru/experts/1"
        echo "   2. Проверьте что имя эксперта отображается"
        echo "   3. Нажмите 'Связаться с экспертом'"
        echo "   4. Должно работать без ошибок"
        echo ""
        echo -e "${GREEN}🔥 PM2 ПРОЦЕСС РАБОТАЕТ КОРРЕКТНО!${NC}"
    else
        echo ""
        echo -e "${RED}❌ ПРОБЛЕМЫ ОСТАЛИСЬ${NC}"
        exit 1
    fi
else
    echo ""
    echo -e "${RED}❌ НЕ УДАЛОСЬ ИСПРАВИТЬ ПРОБЛЕМЫ${NC}"
    echo -e "${YELLOW}⚠️ Попробуйте вручную:${NC}"
    echo "   cd /home/node/ruplatform/server"
    echo "   npm run build"
    echo "   pm2 start dist/index.js --name 'ruplatform-backend' -- --port 3000"
    exit 1
fi

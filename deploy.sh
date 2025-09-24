#!/bin/bash

# 🚀 Скрипт деплоя платформы духовных мастеров на Timeweb Cloud

echo "🚀 Начинаем деплой платформы духовных мастеров..."

# Проверка Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js не найден. Установите Node.js версии 18 или выше"
    exit 1
fi

echo "✅ Node.js найден: $(node --version)"

# Проверка PM2
if ! command -v pm2 &> /dev/null; then
    echo "📦 Устанавливаем PM2..."
    npm install -g pm2
fi

# Переход в директорию проекта
cd /var/www/ruplatform || { echo "❌ Папка проекта не найдена"; exit 1; }

echo "📦 Устанавливаем зависимости..."

# Установка корневых зависимостей
npm install

# Установка серверных зависимостей
cd server
npm install

# Сборка сервера
echo "🔨 Собираем сервер..."
npm run build

# Инициализация БД (если нужно)
if [ ! -f "db_initialized" ]; then
    echo "🗄️ Инициализируем базу данных..."
    node init-db.js
    touch db_initialized
fi

# Переход к клиенту
cd ../client

# Установка клиентских зависимостей
npm install

# Сборка клиента
echo "🔨 Собираем клиент..."
npm run build

# Возвращаемся к серверу
cd ../server

# Создание директории для логов
mkdir -p logs

# Запуск с PM2
echo "🚀 Запускаем сервер с PM2..."
pm2 start ecosystem.config.js --env production

# Сохранение конфигурации PM2
pm2 save

echo "✅ Деплой завершен!"
echo "🌐 Сайт доступен по адресу: https://yourdomain.ru"
echo "📊 Мониторинг сервера: pm2 monit"
echo "📋 Логи сервера: pm2 logs ruplatform-api"

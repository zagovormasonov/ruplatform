# Платформа Духовных Мастеров

Современная веб-платформа для поиска экспертов в области духовных практик, парапсихологии, астрологии и других направлений. Построена на React + TypeScript (фронтенд) и Node.js + Express + PostgreSQL (бэкенд).

## Функциональность

### Основные возможности:
- 👤 **Авторизация и регистрация** с выбором роли (пользователь/эксперт)
- 🔍 **Поиск экспертов** по 30+ тематикам (Таро, Астрология, Рейки, и др.)
- 📍 **Фильтрация по городам РФ** и типу услуг (онлайн/офлайн)
- 👨‍🎓 **Профили экспертов** с услугами, отзывами и рейтингом
- 📝 **Система статей** с возможностью создания и редактирования
- 💬 **Чаты в реальном времени** на Socket.IO
- 📱 **Адаптивный дизайн** для мобильных устройств

### Тематики:
Регресс, Парапсихология, Расстановки, Хьюман дизайн, МАК карты, Таро, Руны, Карты Ленорман, Астрология, Нумерология, Тетахилинг, Космоэнергетика, Рейки, Шаманизм, Славянские практики, Звукотерапия, Целительство, Женские практики, Йога, Гвоздестояние, Тантра практики, Нутрициология, Ароматерапия, Квантовая психология, Медитация, Нейрографика, Мандалы, Литотерапия, Кинезиология.

## Технологический стек

### Фронтенд:
- ⚛️ React 18 + TypeScript
- 🏗️ Vite (сборщик)
- 🎨 Ant Design (UI библиотека)
- 🌐 React Router (навигация)
- 🔗 Axios (HTTP клиент)
- 💬 Socket.IO Client (чаты)

### Бэкенд:
- 🟢 Node.js + Express + TypeScript
- 🗄️ PostgreSQL (база данных)
- 🔐 JWT (аутентификация)
- 🔒 bcryptjs (хеширование паролей)
- 💬 Socket.IO (WebSocket)
- 🛡️ Helmet, CORS (безопасность)

## Структура проекта

```
RuPlatform/
├── client/                 # React приложение
│   ├── src/
│   │   ├── components/     # Компоненты
│   │   ├── pages/         # Страницы
│   │   ├── contexts/      # React контексты
│   │   ├── services/      # API сервисы
│   │   ├── types/         # TypeScript типы
│   │   └── utils/         # Утилиты
│   └── package.json
├── server/                # Node.js сервер
│   ├── src/
│   │   ├── controllers/   # Контроллеры
│   │   ├── routes/        # Маршруты API
│   │   ├── middleware/    # Middleware
│   │   ├── database/      # База данных
│   │   └── models/        # Модели данных
│   └── package.json
└── package.json          # Корневой package.json
```

## Установка и запуск

### Предварительные требования:
- Node.js (версия 16+)
- PostgreSQL
- npm или yarn

### 1. Клонирование репозитория:
```bash
git clone <repository-url>
cd RuPlatform
```

### 2. Установка зависимостей:
```bash
# Установка зависимостей для всего проекта
npm run install:all

# Или по отдельности:
npm install
cd client && npm install
cd ../server && npm install
```

### 3. Настройка базы данных:

1. Создайте базу данных PostgreSQL
2. Выполните SQL схему из файла `server/src/database/schema.sql`
3. Настройте переменные окружения в `server/.env`:

```env
DATABASE_URL=postgresql://username:password@host:port/database
JWT_SECRET=your_jwt_secret_key
PORT=3001
NODE_ENV=development
```

### 4. Запуск приложения:

#### Режим разработки (оба сервера одновременно):
```bash
npm run dev
```

#### Или запуск по отдельности:
```bash
# Сервер (порт 3001)
npm run server:dev

# Клиент (порт 5173)
npm run client:dev
```

### 5. Сборка для продакшена:
```bash
# Сборка клиента
npm run client:build

# Сборка сервера
npm run server:build
```

## API Endpoints

### Аутентификация:
- `POST /api/auth/login` - Авторизация
- `POST /api/auth/register` - Регистрация
- `GET /api/auth/verify` - Проверка токена

### Пользователи:
- `GET /api/users/profile` - Получение профиля
- `PUT /api/users/profile` - Обновление профиля
- `GET /api/users/cities` - Список городов
- `GET /api/users/topics` - Список тематик

### Эксперты:
- `GET /api/experts/search` - Поиск экспертов
- `GET /api/experts/:id` - Профиль эксперта
- `GET /api/experts/profile/me` - Мой профиль эксперта
- `PUT /api/experts/profile` - Обновление профиля эксперта
- `POST /api/experts/services` - Создание услуги
- `GET /api/experts/services/my` - Мои услуги

### Статьи:
- `GET /api/articles` - Список статей
- `GET /api/articles/:id` - Статья по ID
- `POST /api/articles` - Создание статьи
- `PUT /api/articles/:id` - Обновление статьи
- `DELETE /api/articles/:id` - Удаление статьи

### Чаты:
- `GET /api/chats` - Список чатов
- `POST /api/chats/start` - Создание чата
- `GET /api/chats/:id/messages` - Сообщения чата
- `POST /api/chats/:id/messages` - Отправка сообщения

## База данных

Приложение использует PostgreSQL с следующими основными таблицами:
- `users` - Пользователи
- `expert_profiles` - Профили экспертов
- `topics` - Тематики
- `cities` - Города РФ
- `services` - Услуги экспертов
- `articles` - Статьи
- `chats` - Чаты
- `messages` - Сообщения
- `reviews` - Отзывы

## Развертывание

### Timeweb Cloud:
1. Создайте сервер на Timeweb Cloud
2. Установите Node.js и PostgreSQL
3. Склонируйте репозиторий
4. Установите зависимости
5. Настройте переменные окружения
6. Запустите приложение через PM2:

```bash
npm install -g pm2
pm2 start server/dist/index.js --name "spiritual-platform"
```

### Nginx конфигурация:
```nginx
server {
    listen 80;
    server_name your-domain.com;

    # Frontend
    location / {
        root /path/to/client/dist;
        try_files $uri $uri/ /index.html;
    }

    # API
    location /api {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # Socket.IO
    location /socket.io {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Дизайн

Приложение использует минималистичный дизайн в стиле Apple с:
- 🎨 Светлой темой Ant Design
- 📐 Скругленными углами и мягкими тенями
- 🔵 Основным цветом #6366f1 (Indigo)
- 📱 Полной адаптивностью для мобильных устройств
- ⚡ Плавными анимациями и переходами

## Лицензия

Все права защищены. Платформа Духовных Мастеров © 2024.

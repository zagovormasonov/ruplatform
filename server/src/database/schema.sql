-- Создание таблиц для платформы духовных мастеров

-- Типы пользователей
CREATE TYPE user_role AS ENUM ('user', 'expert');
CREATE TYPE service_type AS ENUM ('online', 'offline');

-- Таблица пользователей
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role user_role DEFAULT 'user',
    avatar_url VARCHAR(500),
    phone VARCHAR(20),
    city VARCHAR(100),
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Таблица тематик
CREATE TABLE topics (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Вставка тематик
INSERT INTO topics (name, description) VALUES
    ('Регресс', 'Регрессивная терапия'),
    ('Парапсихология', 'Изучение паранормальных явлений'),
    ('Расстановки', 'Семейные и системные расстановки'),
    ('Хьюман дизайн', 'Система самопознания Human Design'),
    ('МАК карты', 'Метафорические ассоциативные карты'),
    ('Таро', 'Гадание на картах Таро'),
    ('Руны', 'Рунические практики'),
    ('Карты Ленорман', 'Гадание на картах Ленорман'),
    ('Астрология', 'Астрологические консультации'),
    ('Нумерология', 'Нумерологический анализ'),
    ('Тетахилинг', 'Техника исцеления Theta Healing'),
    ('Космоэнергетика', 'Космоэнергетические практики'),
    ('Рейки', 'Система исцеления Рейки'),
    ('Шаманизм', 'Шаманские практики'),
    ('Славянские практики', 'Традиционные славянские практики'),
    ('Звукотерапия', 'Лечение звуком'),
    ('Целительство', 'Энергетическое целительство'),
    ('Женские практики', 'Практики для женщин'),
    ('Йога', 'Йога и медитация'),
    ('Гвоздестояние', 'Практика стояния на гвоздях'),
    ('Тантра практики', 'Тантрические практики'),
    ('Нутрициология', 'Консультации по питанию'),
    ('Ароматерапия', 'Лечение ароматами'),
    ('Квантовая психология', 'Квантовые методы психологии'),
    ('Медитация', 'Медитативные практики'),
    ('Нейрографика', 'Творческий метод нейрографика'),
    ('Мандалы', 'Работа с мандалами'),
    ('Литотерапия', 'Лечение камнями'),
    ('Кинезиология', 'Кинезиологические практики');

-- Таблица городов РФ (основные)
CREATE TABLE cities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    region VARCHAR(100)
);

-- Вставка основных городов РФ
INSERT INTO cities (name, region) VALUES
    ('Москва', 'Москва'),
    ('Санкт-Петербург', 'Ленинградская область'),
    ('Новосибирск', 'Новосибирская область'),
    ('Екатеринбург', 'Свердловская область'),
    ('Нижний Новгород', 'Нижегородская область'),
    ('Казань', 'Республика Татарстан'),
    ('Челябинск', 'Челябинская область'),
    ('Омск', 'Омская область'),
    ('Самара', 'Самарская область'),
    ('Ростов-на-Дону', 'Ростовская область'),
    ('Уфа', 'Республика Башкортостан'),
    ('Красноярск', 'Красноярский край'),
    ('Воронеж', 'Воронежская область'),
    ('Пермь', 'Пермский край'),
    ('Волгоград', 'Волгоградская область');

-- Таблица профилей экспертов
CREATE TABLE expert_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    bio TEXT,
    experience_years INTEGER,
    education TEXT,
    certificates TEXT,
    rating DECIMAL(3,2) DEFAULT 0.00,
    reviews_count INTEGER DEFAULT 0,
    city_id INTEGER REFERENCES cities(id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Связь экспертов с тематиками (многие ко многим)
CREATE TABLE expert_topics (
    id SERIAL PRIMARY KEY,
    expert_id INTEGER REFERENCES expert_profiles(id) ON DELETE CASCADE,
    topic_id INTEGER REFERENCES topics(id) ON DELETE CASCADE,
    UNIQUE(expert_id, topic_id)
);

-- Таблица услуг экспертов
CREATE TABLE services (
    id SERIAL PRIMARY KEY,
    expert_id INTEGER REFERENCES expert_profiles(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(10,2),
    duration_minutes INTEGER,
    service_type service_type NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Таблица статей
CREATE TABLE articles (
    id SERIAL PRIMARY KEY,
    author_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(300) NOT NULL,
    content TEXT NOT NULL,
    excerpt TEXT,
    cover_image VARCHAR(500),
    views_count INTEGER DEFAULT 0,
    likes_count INTEGER DEFAULT 0,
    is_published BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Таблица изображений для статей
CREATE TABLE article_images (
    id SERIAL PRIMARY KEY,
    article_id INTEGER REFERENCES articles(id) ON DELETE CASCADE,
    image_url VARCHAR(500) NOT NULL,
    alt_text VARCHAR(200),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Таблица чатов
CREATE TABLE chats (
    id SERIAL PRIMARY KEY,
    user1_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    user2_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    last_message TEXT,
    last_message_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user1_id, user2_id)
);

-- Таблица сообщений
CREATE TABLE messages (
    id SERIAL PRIMARY KEY,
    chat_id INTEGER REFERENCES chats(id) ON DELETE CASCADE,
    sender_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Таблица отзывов
CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    expert_id INTEGER REFERENCES expert_profiles(id) ON DELETE CASCADE,
    reviewer_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(expert_id, reviewer_id)
);

-- Индексы для оптимизации
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_expert_profiles_user_id ON expert_profiles(user_id);
CREATE INDEX idx_expert_profiles_city_id ON expert_profiles(city_id);
CREATE INDEX idx_expert_profiles_rating ON expert_profiles(rating);
CREATE INDEX idx_expert_topics_expert_id ON expert_topics(expert_id);
CREATE INDEX idx_expert_topics_topic_id ON expert_topics(topic_id);
CREATE INDEX idx_services_expert_id ON services(expert_id);
CREATE INDEX idx_articles_author_id ON articles(author_id);
CREATE INDEX idx_articles_published ON articles(is_published);
CREATE INDEX idx_chats_users ON chats(user1_id, user2_id);
CREATE INDEX idx_messages_chat_id ON messages(chat_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);
CREATE INDEX idx_reviews_expert_id ON reviews(expert_id);

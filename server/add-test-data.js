const { Pool } = require('pg');

// Подключение к базе данных
const pool = new Pool({
  connectionString: 'postgresql://gen_user:OCS(ifoR||A5$~@40e0a3b39459bee0b2e47359.twc1.net:5432/default_db',
  ssl: {
    rejectUnauthorized: false
  }
});

async function addTestData() {
  try {
    console.log('🔧 Spiritual Platform: Добавление тестовых данных...');
    
    const client = await pool.connect();
    
    // Добавляем тестовых пользователей-экспертов
    const user1 = await client.query(`
      INSERT INTO users (email, password_hash, first_name, last_name, role, city, phone)
      VALUES ('anna@example.com', '$2b$10$hash1', 'Анна', 'Смирнова', 'expert', 'Москва', '+7 (999) 123-45-67')
      ON CONFLICT (email) DO UPDATE SET 
        first_name = EXCLUDED.first_name,
        last_name = EXCLUDED.last_name
      RETURNING id
    `);

    const user2 = await client.query(`
      INSERT INTO users (email, password_hash, first_name, last_name, role, city, phone)
      VALUES ('mikhail@example.com', '$2b$10$hash2', 'Михаил', 'Петров', 'expert', 'Санкт-Петербург', '+7 (999) 234-56-78')
      ON CONFLICT (email) DO UPDATE SET 
        first_name = EXCLUDED.first_name,
        last_name = EXCLUDED.last_name
      RETURNING id
    `);

    const user3 = await client.query(`
      INSERT INTO users (email, password_hash, first_name, last_name, role, city, phone)
      VALUES ('elena@example.com', '$2b$10$hash3', 'Елена', 'Васильева', 'expert', 'Новосибирск', '+7 (999) 345-67-89')
      ON CONFLICT (email) DO UPDATE SET 
        first_name = EXCLUDED.first_name,
        last_name = EXCLUDED.last_name
      RETURNING id
    `);

    console.log('✅ Пользователи созданы');

    // Получаем ID городов
    const moscowCity = await client.query(`SELECT id FROM cities WHERE name = 'Москва'`);
    const spbCity = await client.query(`SELECT id FROM cities WHERE name = 'Санкт-Петербург'`);
    const novosCity = await client.query(`SELECT id FROM cities WHERE name = 'Новосибирск'`);

    // Создаем профили экспертов
    let expert1, expert2, expert3;
    
    try {
      expert1 = await client.query(`
        INSERT INTO expert_profiles (user_id, bio, rating, reviews_count, city_id, is_active)
        VALUES ($1, 'Таролог с 10-летним стажем. Помогаю разобраться в сложных жизненных ситуациях.', 4.8, 124, $2, true)
        RETURNING id
      `, [user1.rows[0].id, moscowCity.rows[0]?.id]);
    } catch (e) {
      expert1 = await client.query(`SELECT id FROM expert_profiles WHERE user_id = $1`, [user1.rows[0].id]);
    }

    try {
      expert2 = await client.query(`
        INSERT INTO expert_profiles (user_id, bio, rating, reviews_count, city_id, is_active)
        VALUES ($1, 'Специалист по медитации и духовному развитию. Провожу сеансы рейки.', 4.9, 89, $2, true)
        RETURNING id
      `, [user2.rows[0].id, spbCity.rows[0]?.id]);
    } catch (e) {
      expert2 = await client.query(`SELECT id FROM expert_profiles WHERE user_id = $1`, [user2.rows[0].id]);
    }

    try {
      expert3 = await client.query(`
        INSERT INTO expert_profiles (user_id, bio, rating, reviews_count, city_id, is_active)
        VALUES ($1, 'Астролог и нумеролог. Составляю персональные гороскопы и расчеты.', 4.7, 156, $2, true)
        RETURNING id
      `, [user3.rows[0].id, novosCity.rows[0]?.id]);
    } catch (e) {
      expert3 = await client.query(`SELECT id FROM expert_profiles WHERE user_id = $1`, [user3.rows[0].id]);
    }

    console.log('✅ Профили экспертов созданы');

    // Получаем ID тематик
    const taroTopic = await client.query(`SELECT id FROM topics WHERE name = 'Таро'`);
    const astroTopic = await client.query(`SELECT id FROM topics WHERE name = 'Астрология'`);
    const reikiTopic = await client.query(`SELECT id FROM topics WHERE name = 'Рейки'`);
    const meditationTopic = await client.query(`SELECT id FROM topics WHERE name = 'Медитация'`);
    const numeroTopic = await client.query(`SELECT id FROM topics WHERE name = 'Нумерология'`);

    // Связываем экспертов с тематиками
    if (taroTopic.rows[0] && astroTopic.rows[0]) {
      try {
        await client.query(`
          INSERT INTO expert_topics (expert_id, topic_id) 
          VALUES ($1, $2), ($1, $3)
        `, [expert1.rows[0].id, taroTopic.rows[0].id, astroTopic.rows[0].id]);
      } catch (e) { /* Игнорируем дубликаты */ }
    }

    if (reikiTopic.rows[0] && meditationTopic.rows[0]) {
      try {
        await client.query(`
          INSERT INTO expert_topics (expert_id, topic_id) 
          VALUES ($1, $2), ($1, $3)
        `, [expert2.rows[0].id, reikiTopic.rows[0].id, meditationTopic.rows[0].id]);
      } catch (e) { /* Игнорируем дубликаты */ }
    }

    if (astroTopic.rows[0] && numeroTopic.rows[0]) {
      try {
        await client.query(`
          INSERT INTO expert_topics (expert_id, topic_id) 
          VALUES ($1, $2), ($1, $3)
        `, [expert3.rows[0].id, astroTopic.rows[0].id, numeroTopic.rows[0].id]);
      } catch (e) { /* Игнорируем дубликаты */ }
    }

    console.log('✅ Тематики связаны с экспертами');

    // Добавляем услуги
    try {
      await client.query(`
        INSERT INTO services (expert_id, title, description, price, duration_minutes, service_type, is_active)
        VALUES 
          ($1, 'Расклад Таро', 'Подробное толкование карт Таро для понимания ситуации', 2000, 60, 'online', true),
          ($1, 'Персональный гороскоп', 'Составление индивидуального астрологического прогноза', 3000, 90, 'online', true),
          ($2, 'Сеанс Рейки', 'Исцеление и гармонизация энергетических центров', 3500, 90, 'offline', true),
          ($2, 'Групповая медитация', 'Коллективная практика медитации для начинающих', 1500, 60, 'offline', true),
          ($3, 'Нумерологический анализ', 'Расчет персональных чисел и их значений', 2500, 75, 'online', true),
          ($3, 'Консультация астролога', 'Разбор астрологической карты и прогноз', 4000, 120, 'online', true)
      `, [expert1.rows[0].id, expert2.rows[0].id, expert3.rows[0].id]);
    } catch (e) {
      console.log('Услуги уже существуют, пропускаем...');
    }

    console.log('✅ Услуги добавлены');

    client.release();
    
    console.log('🎉 Spiritual Platform: Тестовые данные успешно добавлены!');
    console.log('📊 Добавлено:');
    console.log('   - 3 эксперта (Анна, Михаил, Елена)');
    console.log('   - Связи с тематиками');
    console.log('   - 6 услуг');
    console.log('🔗 Теперь поиск экспертов будет показывать реальные данные!');
  } catch (error) {
    console.error('❌ Spiritual Platform: Ошибка добавления тестовых данных:', error);
  } finally {
    await pool.end();
  }
}

addTestData();

const { Pool } = require('pg');

// Подключение к базе данных
const pool = new Pool({
  connectionString: 'postgresql://gen_user:OCS(ifoR||A5$~@40e0a3b39459bee0b2e47359.twc1.net:5432/default_db',
  ssl: {
    rejectUnauthorized: false
  }
});

async function addOmskExpert() {
  try {
    console.log('🔧 Spiritual Platform: Добавление эксперта в Омск...');
    
    const client = await pool.connect();
    
    // Добавляем пользователя-эксперта в Омск
    const user = await client.query(`
      INSERT INTO users (email, password_hash, first_name, last_name, role, city, phone)
      VALUES ('dmitry@example.com', '$2b$10$hash4', 'Дмитрий', 'Кузнецов', 'expert', 'Омск', '+7 (999) 456-78-90')
      ON CONFLICT (email) DO UPDATE SET 
        first_name = EXCLUDED.first_name,
        last_name = EXCLUDED.last_name,
        city = EXCLUDED.city
      RETURNING id
    `);

    console.log('✅ Пользователь создан');

    // Получаем ID города Омск
    const omskCity = await client.query(`SELECT id FROM cities WHERE name = 'Омск'`);

    if (!omskCity.rows[0]) {
      console.log('❌ Город Омск не найден в БД');
      client.release();
      return;
    }

    // Создаем профиль эксперта
    let expert;
    try {
      expert = await client.query(`
        INSERT INTO expert_profiles (user_id, bio, rating, reviews_count, city_id, is_active)
        VALUES ($1, 'Специалист по нумерологии и кинезиологии. Помогаю найти ваш жизненный путь через числа.', 4.6, 67, $2, true)
        RETURNING id
      `, [user.rows[0].id, omskCity.rows[0].id]);
    } catch (e) {
      expert = await client.query(`SELECT id FROM expert_profiles WHERE user_id = $1`, [user.rows[0].id]);
    }

    console.log('✅ Профиль эксперта создан');

    // Получаем ID тематик
    const numeroTopic = await client.query(`SELECT id FROM topics WHERE name = 'Нумерология'`);
    const kinesTopic = await client.query(`SELECT id FROM topics WHERE name = 'Кинезиология'`);

    // Связываем эксперта с тематиками
    if (numeroTopic.rows[0] && kinesTopic.rows[0]) {
      try {
        await client.query(`
          INSERT INTO expert_topics (expert_id, topic_id) 
          VALUES ($1, $2), ($1, $3)
        `, [expert.rows[0].id, numeroTopic.rows[0].id, kinesTopic.rows[0].id]);
      } catch (e) { /* Игнорируем дубликаты */ }
    }

    console.log('✅ Тематики связаны с экспертом');

    // Добавляем услуги
    try {
      await client.query(`
        INSERT INTO services (expert_id, title, description, price, duration_minutes, service_type, is_active)
        VALUES 
          ($1, 'Нумерологический расчет', 'Персональный расчет чисел судьбы и совместимости', 1800, 60, 'online', true),
          ($1, 'Кинезиологическая коррекция', 'Работа с мышечными тестами и энергетикой', 2800, 90, 'offline', true)
      `, [expert.rows[0].id]);
    } catch (e) {
      console.log('Услуги уже существуют, пропускаем...');
    }

    console.log('✅ Услуги добавлены');

    client.release();
    
    console.log('🎉 Spiritual Platform: Эксперт в Омске успешно добавлен!');
    console.log('📊 Добавлено:');
    console.log('   - Дмитрий Кузнецов (Омск)');
    console.log('   - Тематики: Нумерология, Кинезиология');
    console.log('   - 2 услуги (онлайн и офлайн)');
    console.log('🔍 Теперь поиск по городу "Омск" найдет эксперта!');
  } catch (error) {
    console.error('❌ Spiritual Platform: Ошибка добавления эксперта:', error);
  } finally {
    await pool.end();
  }
}

addOmskExpert();

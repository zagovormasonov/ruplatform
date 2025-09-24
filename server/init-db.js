const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

// Подключение к базе данных
const pool = new Pool({
  connectionString: 'postgresql://gen_user:OCS(ifoR||A5$~@40e0a3b39459bee0b2e47359.twc1.net:5432/default_db',
  ssl: {
    rejectUnauthorized: false
  }
});

async function initDatabase() {
  try {
    console.log('🔧 Spiritual Platform: Инициализация базы данных...');
    
    // Читаем SQL схему
    const schemaPath = path.join(__dirname, 'src', 'database', 'schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf8');
    
    // Выполняем SQL запросы
    await pool.query(schema);
    
    console.log('✅ Spiritual Platform: База данных успешно инициализирована!');
    console.log('📊 Созданы таблицы:');
    console.log('   - users (пользователи)');
    console.log('   - expert_profiles (профили экспертов)');
    console.log('   - topics (30 тематик)');
    console.log('   - cities (города РФ)');
    console.log('   - services (услуги экспертов)');
    console.log('   - articles (статьи)');
    console.log('   - chats (чаты)');
    console.log('   - messages (сообщения)');
    console.log('   - reviews (отзывы)');
    
  } catch (error) {
    console.error('❌ Spiritual Platform: Ошибка инициализации БД:', error);
  } finally {
    await pool.end();
  }
}

initDatabase();

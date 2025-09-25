import express from 'express';
import pool from '../database/connection';
import { authenticateToken, AuthRequest, requireRole } from '../middleware/auth';

const router = express.Router();

// Поиск экспертов с фильтрами
router.get('/search', async (req, res) => {
  try {
    const { topics, city, serviceType, search, sortBy = 'rating', page = 1, limit = 12 } = req.query;
    const offset = (Number(page) - 1) * Number(limit);
    
    console.log('Spiritual Platform: Поиск экспертов с параметрами:', {
      topics, city, serviceType, search, sortBy, page, limit
    });

    let query = `
      SELECT DISTINCT ep.id,
             u.id as "userId",
             u.first_name,
             u.last_name,
             u.avatar_url as "avatarUrl",
             ep.bio,
             ep.rating,
             ep.reviews_count as "reviewsCount",
             ep.created_at,
             c.name as "cityName",
             c.region,
             array_agg(DISTINCT t.name) as topics,
             array_agg(DISTINCT s.title) as services
      FROM expert_profiles ep
      JOIN users u ON ep.user_id = u.id
      LEFT JOIN cities c ON ep.city_id = c.id
      LEFT JOIN expert_topics et ON ep.id = et.expert_id
      LEFT JOIN topics t ON et.topic_id = t.id
      LEFT JOIN services s ON ep.id = s.expert_id AND s.is_active = true
      WHERE ep.is_active = true
    `;

    const queryParams: any[] = [];
    let paramIndex = 1;

    // Фильтр по тематикам
    if (topics) {
      const topicArray = Array.isArray(topics) ? topics : [topics];
      query += ` AND t.name = ANY($${paramIndex})`;
      queryParams.push(topicArray);
      paramIndex++;
    }

    // Фильтр по городу
    if (city) {
      query += ` AND c.name = $${paramIndex}`;
      queryParams.push(city);
      paramIndex++;
    }

    // Фильтр по типу услуг
    if (serviceType) {
      query += ` AND s.service_type = $${paramIndex}`;
      queryParams.push(serviceType);
      paramIndex++;
    }

    // Поиск по имени
    if (search) {
      query += ` AND (u.first_name ILIKE $${paramIndex} OR u.last_name ILIKE $${paramIndex})`;
      queryParams.push(`%${search}%`);
      paramIndex++;
    }

    query += `
      GROUP BY ep.id, u.id, u.first_name, u.last_name, u.avatar_url, ep.bio, ep.rating, ep.reviews_count, ep.created_at, c.name, c.region
    `;

    // Добавляем сортировку
    switch (sortBy) {
      case 'reviews':
        query += ` ORDER BY ep.reviews_count DESC, ep.rating DESC`;
        break;
      case 'price_low':
        query += ` ORDER BY ep.rating DESC`; // Упрощенная сортировка
        break;
      case 'price_high':
        query += ` ORDER BY ep.rating DESC`; // Упрощенная сортировка
        break;
      case 'newest':
        query += ` ORDER BY ep.created_at DESC`;
        break;
      case 'rating':
      default:
        query += ` ORDER BY ep.rating DESC, ep.reviews_count DESC`;
        break;
    }

    query += ` LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    
    

    queryParams.push(Number(limit), offset);

    const result = await pool.query(query, queryParams);

    // Получение детальной информации об услугах для каждого эксперта
    const expertsWithServices = await Promise.all(result.rows.map(async (expert) => {
      const servicesResult = await pool.query(`
        SELECT id, title, description, price, duration_minutes as "durationMinutes",
               service_type as "serviceType", is_active as "isActive"
        FROM services
        WHERE expert_id = $1 AND is_active = true
      `, [expert.id]);

      // Преобразуем snake_case в camelCase для совместимости с фронтендом
      const transformedExpert = {
        ...expert,
        firstName: expert.first_name,
        lastName: expert.last_name,
        cityName: expert.city_name,
        services: servicesResult.rows
      };

      delete transformedExpert.first_name;
      delete transformedExpert.last_name;
      delete transformedExpert.city_name;

      return transformedExpert;
    }));

    // Подсчет общего количества
    let countQuery = `
      SELECT COUNT(DISTINCT ep.id) as total
      FROM expert_profiles ep
      JOIN users u ON ep.user_id = u.id
      LEFT JOIN cities c ON ep.city_id = c.id
      LEFT JOIN expert_topics et ON ep.id = et.expert_id
      LEFT JOIN topics t ON et.topic_id = t.id
      LEFT JOIN services s ON ep.id = s.expert_id AND s.is_active = true
      WHERE ep.is_active = true
    `;

    const countParams: any[] = [];
    let countParamIndex = 1;

    if (topics) {
      const topicArray = Array.isArray(topics) ? topics : [topics];
      countQuery += ` AND t.name = ANY($${countParamIndex})`;
      countParams.push(topicArray);
      countParamIndex++;
    }

    if (city) {
      countQuery += ` AND c.name = $${countParamIndex}`;
      countParams.push(city);
      countParamIndex++;
    }

    if (serviceType) {
      countQuery += ` AND s.service_type = $${countParamIndex}`;
      countParams.push(serviceType);
      countParamIndex++;
    }

    if (search) {
      countQuery += ` AND (u.first_name ILIKE $${countParamIndex} OR u.last_name ILIKE $${countParamIndex})`;
      countParams.push(`%${search}%`);
      countParamIndex++;
    }

    const countResult = await pool.query(countQuery, countParams);
    const total = parseInt(countResult.rows[0].total);

    res.json({
      experts: expertsWithServices,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total,
        totalPages: Math.ceil(total / Number(limit))
      }
    });
  } catch (error) {
    console.error('Spiritual Platform: Ошибка поиска экспертов:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

// Получение профиля эксперта по ID
router.get('/:id', async (req, res) => {
  try {
    const expertId = req.params.id;

    const expertResult = await pool.query(`
      SELECT ep.*, u.id as "userId", u.first_name, u.last_name, u.email, u.avatar_url, u.phone,
             c.name as city_name, c.region,
             array_agg(DISTINCT t.name) as topics
      FROM expert_profiles ep
      JOIN users u ON ep.user_id = u.id
      LEFT JOIN cities c ON ep.city_id = c.id
      LEFT JOIN expert_topics et ON ep.id = et.expert_id
      LEFT JOIN topics t ON et.topic_id = t.id
      WHERE ep.id = $1 AND ep.is_active = true
      GROUP BY ep.id, u.id, u.first_name, u.last_name, u.email, u.avatar_url, u.phone, c.name, c.region
    `, [expertId]);

    // Преобразуем snake_case в camelCase для совместимости с фронтендом
    const expertData = expertResult.rows[0];
    if (expertData) {
      expertData.firstName = expertData.first_name;
      expertData.lastName = expertData.last_name;
      expertData.cityName = expertData.city_name;
      delete expertData.first_name;
      delete expertData.last_name;
      delete expertData.city_name;
    }

    if (expertResult.rows.length === 0) {
      return res.status(404).json({ error: 'Эксперт не найден' });
    }

    // Получение услуг эксперта
    const servicesResult = await pool.query(`
      SELECT * FROM services 
      WHERE expert_id = $1 AND is_active = true 
      ORDER BY created_at DESC
    `, [expertId]);

    // Получение отзывов
    const reviewsResult = await pool.query(`
      SELECT r.*, u.first_name, u.last_name, u.avatar_url
      FROM reviews r
      JOIN users u ON r.reviewer_id = u.id
      WHERE r.expert_id = $1
      ORDER BY r.created_at DESC
      LIMIT 10
    `, [expertId]);

    const expert = expertData || expertResult.rows[0];
    if (expert) {
      expert.services = servicesResult.rows;
      expert.reviews = reviewsResult.rows;
    }

    res.json(expert);
  } catch (error) {
    console.error('Spiritual Platform: Ошибка получения профиля эксперта:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

// Получение профиля текущего эксперта
router.get('/profile/me', authenticateToken, requireRole('expert'), async (req: AuthRequest, res) => {
  try {
    const userId = req.user?.id;

    const profileResult = await pool.query(`
      SELECT ep.*, u.first_name, u.last_name, u.email, u.avatar_url, u.phone,
             c.name as city_name, c.region
      FROM expert_profiles ep
      JOIN users u ON ep.user_id = u.id
      LEFT JOIN cities c ON ep.city_id = c.id
      WHERE ep.user_id = $1
    `, [userId]);

    if (profileResult.rows.length === 0) {
      return res.status(404).json({ error: 'Профиль эксперта не найден' });
    }

    // Получение тематик эксперта
    const topicsResult = await pool.query(`
      SELECT t.id, t.name
      FROM expert_topics et
      JOIN topics t ON et.topic_id = t.id
      WHERE et.expert_id = $1
    `, [profileResult.rows[0].id]);

    const expertData = profileResult.rows[0];
    expertData.topics = topicsResult.rows;

    res.json(expertData);
  } catch (error) {
    console.error('Spiritual Platform: Ошибка получения профиля эксперта:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

// Обновление профиля эксперта
router.put('/profile', authenticateToken, requireRole('expert'), async (req: AuthRequest, res) => {
  try {
    const userId = req.user?.id;
    const { bio, experienceYears, education, certificates, cityId, topics } = req.body;

    // Получение ID профиля эксперта
    const expertResult = await pool.query(
      'SELECT id FROM expert_profiles WHERE user_id = $1',
      [userId]
    );

    if (expertResult.rows.length === 0) {
      return res.status(404).json({ error: 'Профиль эксперта не найден' });
    }

    const expertId = expertResult.rows[0].id;

    // Обновление профиля эксперта
    await pool.query(`
      UPDATE expert_profiles 
      SET bio = $1, experience_years = $2, education = $3, certificates = $4, city_id = $5, updated_at = NOW()
      WHERE id = $6
    `, [bio, experienceYears, education, certificates, cityId, expertId]);

    // Обновление тематик
    if (topics && Array.isArray(topics)) {
      // Удаление старых тематик
      await pool.query('DELETE FROM expert_topics WHERE expert_id = $1', [expertId]);

      // Добавление новых тематик
      for (const topicId of topics) {
        await pool.query(
          'INSERT INTO expert_topics (expert_id, topic_id) VALUES ($1, $2)',
          [expertId, topicId]
        );
      }
    }

    console.log(`Spiritual Platform: Профиль эксперта обновлен для пользователя ${userId}`);
    res.json({ message: 'Профиль эксперта успешно обновлен' });
  } catch (error) {
    console.error('Spiritual Platform: Ошибка обновления профиля эксперта:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

// Создание услуги
router.post('/services', authenticateToken, requireRole('expert'), async (req: AuthRequest, res) => {
  try {
    const userId = req.user?.id;
    const { title, description, price, durationMinutes, serviceType } = req.body;

    // Получение ID профиля эксперта
    const expertResult = await pool.query(
      'SELECT id FROM expert_profiles WHERE user_id = $1',
      [userId]
    );

    if (expertResult.rows.length === 0) {
      return res.status(404).json({ error: 'Профиль эксперта не найден' });
    }

    const expertId = expertResult.rows[0].id;

    const result = await pool.query(`
      INSERT INTO services (expert_id, title, description, price, duration_minutes, service_type)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *
    `, [expertId, title, description, price, durationMinutes, serviceType]);

    console.log(`Spiritual Platform: Новая услуга создана экспертом ${userId}`);
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Spiritual Platform: Ошибка создания услуги:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

// Получение услуг эксперта
router.get('/services/my', authenticateToken, requireRole('expert'), async (req: AuthRequest, res) => {
  try {
    const userId = req.user?.id;

    const expertResult = await pool.query(
      'SELECT id FROM expert_profiles WHERE user_id = $1',
      [userId]
    );

    if (expertResult.rows.length === 0) {
      return res.status(404).json({ error: 'Профиль эксперта не найден' });
    }

    const expertId = expertResult.rows[0].id;

    const result = await pool.query(`
      SELECT * FROM services 
      WHERE expert_id = $1 
      ORDER BY created_at DESC
    `, [expertId]);

    res.json(result.rows);
  } catch (error) {
    console.error('Spiritual Platform: Ошибка получения услуг:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

// Обновление услуги
router.put('/services/:id', authenticateToken, requireRole('expert'), async (req: AuthRequest, res) => {
  try {
    const userId = req.user?.id;
    const serviceId = req.params.id;
    const { title, description, price, durationMinutes, serviceType, isActive } = req.body;

    // Проверка принадлежности услуги эксперту
    const serviceResult = await pool.query(`
      SELECT s.id FROM services s
      JOIN expert_profiles ep ON s.expert_id = ep.id
      WHERE s.id = $1 AND ep.user_id = $2
    `, [serviceId, userId]);

    if (serviceResult.rows.length === 0) {
      return res.status(404).json({ error: 'Услуга не найдена' });
    }

    const result = await pool.query(`
      UPDATE services 
      SET title = $1, description = $2, price = $3, duration_minutes = $4, 
          service_type = $5, is_active = $6, updated_at = NOW()
      WHERE id = $7
      RETURNING *
    `, [title, description, price, durationMinutes, serviceType, isActive, serviceId]);

    console.log(`Spiritual Platform: Услуга обновлена экспертом ${userId}`);
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Spiritual Platform: Ошибка обновления услуги:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

// Удаление услуги
router.delete('/services/:id', authenticateToken, requireRole('expert'), async (req: AuthRequest, res) => {
  try {
    const userId = req.user?.id;
    const serviceId = req.params.id;

    // Проверка принадлежности услуги эксперту
    const serviceResult = await pool.query(`
      SELECT s.id FROM services s
      JOIN expert_profiles ep ON s.expert_id = ep.id
      WHERE s.id = $1 AND ep.user_id = $2
    `, [serviceId, userId]);

    if (serviceResult.rows.length === 0) {
      return res.status(404).json({ error: 'Услуга не найдена' });
    }

    await pool.query('DELETE FROM services WHERE id = $1', [serviceId]);

    console.log(`Spiritual Platform: Услуга удалена экспертом ${userId}`);
    res.json({ message: 'Услуга успешно удалена' });
  } catch (error) {
    console.error('Spiritual Platform: Ошибка удаления услуги:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

export default router;

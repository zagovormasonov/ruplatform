import express from 'express';
import pool from '../database/connection';
import { authenticateToken, AuthRequest } from '../middleware/auth';

const router = express.Router();

// Получение профиля текущего пользователя
router.get('/profile', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const userId = req.user?.id;

    const result = await pool.query(`
      SELECT u.id, u.email, u.first_name, u.last_name, u.role, u.avatar_url, u.phone, u.city,
             c.name as city_name, c.region
      FROM users u
      LEFT JOIN cities c ON u.city = c.name
      WHERE u.id = $1
    `, [userId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Spiritual Platform: Ошибка получения профиля:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

// Обновление профиля пользователя
router.put('/profile', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const userId = req.user?.id;
    const { firstName, lastName, phone, city, avatarUrl } = req.body;

    const result = await pool.query(`
      UPDATE users 
      SET first_name = $1, last_name = $2, phone = $3, city = $4, avatar_url = $5, updated_at = NOW()
      WHERE id = $6
      RETURNING id, email, first_name, last_name, role, avatar_url, phone, city
    `, [firstName, lastName, phone, city, avatarUrl, userId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    console.log(`Spiritual Platform: Профиль обновлен для пользователя ${userId}`);
    res.json({ message: 'Профиль успешно обновлен', user: result.rows[0] });
  } catch (error) {
    console.error('Spiritual Platform: Ошибка обновления профиля:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

// Получение списка городов
router.get('/cities', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM cities ORDER BY name');
    res.json(result.rows);
  } catch (error) {
    console.error('Spiritual Platform: Ошибка получения городов:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

// Получение списка тематик
router.get('/topics', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM topics ORDER BY name');
    res.json(result.rows);
  } catch (error) {
    console.error('Spiritual Platform: Ошибка получения тематик:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

export default router;

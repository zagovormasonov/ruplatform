import express from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import pool from '../database/connection';

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'spiritual_masters_platform_jwt_secret_key_2024';

// Регистрация
router.post('/register', async (req, res) => {
  try {
    const { email, password, firstName, lastName, role = 'user' } = req.body;

    // Валидация
    if (!email || !password || !firstName || !lastName) {
      return res.status(400).json({ error: 'Все поля обязательны' });
    }

    if (password.length < 6) {
      return res.status(400).json({ error: 'Пароль должен содержать минимум 6 символов' });
    }

    // Проверка на существующего пользователя
    const existingUser = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
    if (existingUser.rows.length > 0) {
      return res.status(400).json({ error: 'Пользователь с таким email уже существует' });
    }

    // Хэширование пароля
    const saltRounds = 12;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Создание пользователя
    const result = await pool.query(
      'INSERT INTO users (email, password_hash, first_name, last_name, role) VALUES ($1, $2, $3, $4, $5) RETURNING id, email, first_name, last_name, role',
      [email, hashedPassword, firstName, lastName, role]
    );

    const user = result.rows[0];

    // Если пользователь эксперт, создаем профиль эксперта
    if (role === 'expert') {
      await pool.query(
        'INSERT INTO expert_profiles (user_id) VALUES ($1)',
        [user.id]
      );
    }

    // Создание JWT токена
    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: '7d' } // 7 дней вместо 24 часов
    );

    console.log(`Spiritual Platform: Новый пользователь зарегистрирован: ${email}`);

    res.status(201).json({
      message: 'Пользователь успешно зарегистрирован',
      token,
      user: {
        id: user.id,
        email: user.email,
        firstName: user.first_name,
        lastName: user.last_name,
        role: user.role
      }
    });
  } catch (error) {
    console.error('Spiritual Platform: Ошибка регистрации:', error);
    res.status(500).json({ error: 'Ошибка сервера при регистрации' });
  }
});

// Авторизация
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email и пароль обязательны' });
    }

    // Поиск пользователя
    const result = await pool.query(
      'SELECT id, email, password_hash, first_name, last_name, role FROM users WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Неверный email или пароль' });
    }

    const user = result.rows[0];

    // Проверка пароля
    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Неверный email или пароль' });
    }

    // Создание JWT токена
    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: '7d' } // 7 дней вместо 24 часов
    );

    console.log(`Spiritual Platform: Пользователь авторизован: ${email}`);

    res.json({
      message: 'Успешная авторизация',
      token,
      user: {
        id: user.id,
        email: user.email,
        firstName: user.first_name,
        lastName: user.last_name,
        role: user.role
      }
    });
  } catch (error) {
    console.error('Spiritual Platform: Ошибка авторизации:', error);
    res.status(500).json({ error: 'Ошибка сервера при авторизации' });
  }
});

// Проверка токена
router.get('/verify', async (req, res) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
      return res.status(401).json({ error: 'Токен не предоставлен' });
    }

    const decoded = jwt.verify(token, JWT_SECRET) as any;
    
    const result = await pool.query(
      'SELECT id, email, first_name, last_name, role FROM users WHERE id = $1',
      [decoded.id]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Пользователь не найден' });
    }

    const user = result.rows[0];

    res.json({
      user: {
        id: user.id,
        email: user.email,
        firstName: user.first_name,
        lastName: user.last_name,
        role: user.role
      }
    });
  } catch (error) {
    console.error('Spiritual Platform: Ошибка проверки токена:', error);
    res.status(401).json({ error: 'Недействительный токен' });
  }
});

export default router;

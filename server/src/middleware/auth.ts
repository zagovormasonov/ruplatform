import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import pool from '../database/connection';

export interface AuthRequest extends Request {
  user?: {
    id: number;
    email: string;
    role: 'user' | 'expert';
  };
}

export const authenticateToken = async (req: AuthRequest, res: Response, next: NextFunction) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  console.log('Spiritual Platform Auth: Заголовок авторизации:', authHeader);
  console.log('Spiritual Platform Auth: Токен:', token ? 'присутствует' : 'отсутствует');

  if (!token) {
    console.log('Spiritual Platform Auth: Токен не предоставлен');
    return res.status(401).json({ error: 'Токен доступа не предоставлен' });
  }

  try {
    const JWT_SECRET = process.env.JWT_SECRET || 'spiritual_masters_platform_jwt_secret_key_2024';
    console.log('Spiritual Platform Auth: Проверяем токен с секретным ключом');
    const decoded = jwt.verify(token, JWT_SECRET) as any;
    console.log('Spiritual Platform Auth: Токен декодирован:', decoded);

    // Проверяем, существует ли пользователь в БД
    console.log('Spiritual Platform Auth: Проверяем пользователя в БД:', decoded.id);
    const userResult = await pool.query(
      'SELECT id, email, role FROM users WHERE id = $1',
      [decoded.id]
    );

    console.log('Spiritual Platform Auth: Результат запроса пользователя:', userResult.rows.length, 'строк');

    if (userResult.rows.length === 0) {
      console.log('Spiritual Platform Auth: Пользователь не найден в БД');
      return res.status(401).json({ error: 'Пользователь не найден' });
    }

    console.log('Spiritual Platform Auth: Пользователь найден:', userResult.rows[0]);
    req.user = userResult.rows[0];
    console.log('Spiritual Platform Auth: Аутентификация успешна');
    next();
  } catch (error) {
    console.error('Spiritual Platform Auth: Ошибка аутентификации:', error);
    console.error('Spiritual Platform Auth: Детали ошибки:', {
      name: (error as Error).name,
      message: (error as Error).message
    });
    return res.status(403).json({ error: 'Недействительный токен' });
  }
};

export const requireRole = (role: 'user' | 'expert') => {
  return (req: AuthRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Необходима аутентификация' });
    }

    if (req.user.role !== role && req.user.role !== 'expert') {
      return res.status(403).json({ error: 'Недостаточно прав доступа' });
    }

    next();
  };
};

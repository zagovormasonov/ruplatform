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

  if (!token) {
    return res.status(401).json({ error: 'Токен доступа не предоставлен' });
  }

  try {
    const JWT_SECRET = process.env.JWT_SECRET || 'spiritual_masters_platform_jwt_secret_key_2024';
    const decoded = jwt.verify(token, JWT_SECRET) as any;
    
    // Проверяем, существует ли пользователь в БД
    const userResult = await pool.query(
      'SELECT id, email, role FROM users WHERE id = $1',
      [decoded.id]
    );

    if (userResult.rows.length === 0) {
      return res.status(401).json({ error: 'Пользователь не найден' });
    }

    req.user = userResult.rows[0];
    next();
  } catch (error) {
    console.error('Spiritual Platform: Ошибка аутентификации:', error);
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

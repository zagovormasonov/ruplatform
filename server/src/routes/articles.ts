import express from 'express';
import pool from '../database/connection';
import { authenticateToken, AuthRequest } from '../middleware/auth';

const router = express.Router();

// Получение всех опубликованных статей с пагинацией и сортировкой
router.get('/', async (req, res) => {
  try {
    const { page = 1, limit = 12, sort = 'new' } = req.query;
    const offset = (Number(page) - 1) * Number(limit);

    let orderBy = 'a.created_at DESC'; // По умолчанию новые
    if (sort === 'popular') {
      orderBy = 'a.views_count DESC, a.likes_count DESC';
    }

    const result = await pool.query(`
      SELECT a.id, a.title, a.excerpt, a.cover_image, a.views_count, a.likes_count, a.created_at,
             u.first_name, u.last_name, u.avatar_url
      FROM articles a
      JOIN users u ON a.author_id = u.id
      WHERE a.is_published = true
      ORDER BY ${orderBy}
      LIMIT $1 OFFSET $2
    `, [Number(limit), offset]);

    // Подсчет общего количества
    const countResult = await pool.query(
      'SELECT COUNT(*) as total FROM articles WHERE is_published = true'
    );
    const total = parseInt(countResult.rows[0].total);

    res.json({
      articles: result.rows,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total,
        totalPages: Math.ceil(total / Number(limit))
      }
    });
  } catch (error) {
    console.error('Spiritual Platform: Ошибка получения статей:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

// Получение статьи по ID
router.get('/:id', async (req, res) => {
  try {
    const articleId = req.params.id;

    const result = await pool.query(`
      SELECT a.*, u.first_name, u.last_name, u.avatar_url, u.role
      FROM articles a
      JOIN users u ON a.author_id = u.id
      WHERE a.id = $1 AND a.is_published = true
    `, [articleId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Статья не найдена' });
    }

    // Увеличение счетчика просмотров
    await pool.query('UPDATE articles SET views_count = views_count + 1 WHERE id = $1', [articleId]);

    // Получение изображений статьи
    const imagesResult = await pool.query(
      'SELECT * FROM article_images WHERE article_id = $1 ORDER BY created_at',
      [articleId]
    );

    const article = result.rows[0];
    article.images = imagesResult.rows;
    article.views_count += 1; // Обновляем локально для ответа

    res.json(article);
  } catch (error) {
    console.error('Spiritual Platform: Ошибка получения статьи:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

// Получение статей текущего пользователя
router.get('/my/articles', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const userId = req.user?.id;
    const { page = 1, limit = 12 } = req.query;
    const offset = (Number(page) - 1) * Number(limit);

    const result = await pool.query(`
      SELECT a.id, a.title, a.excerpt, a.cover_image, a.views_count, a.likes_count, 
             a.is_published, a.created_at, a.updated_at
      FROM articles a
      WHERE a.author_id = $1
      ORDER BY a.created_at DESC
      LIMIT $2 OFFSET $3
    `, [userId, Number(limit), offset]);

    // Подсчет общего количества
    const countResult = await pool.query(
      'SELECT COUNT(*) as total FROM articles WHERE author_id = $1',
      [userId]
    );
    const total = parseInt(countResult.rows[0].total);

    res.json({
      articles: result.rows,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total,
        totalPages: Math.ceil(total / Number(limit))
      }
    });
  } catch (error) {
    console.error('Spiritual Platform: Ошибка получения статей пользователя:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

// Создание статьи
router.post('/', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const userId = req.user?.id;
    const { title, content, excerpt, coverImage, isPublished = false } = req.body;

    if (!title || !content) {
      return res.status(400).json({ error: 'Заголовок и содержание обязательны' });
    }

    const result = await pool.query(`
      INSERT INTO articles (author_id, title, content, excerpt, cover_image, is_published)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *
    `, [userId, title, content, excerpt, coverImage, isPublished]);

    console.log(`Spiritual Platform: Новая статья создана пользователем ${userId}`);
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Spiritual Platform: Ошибка создания статьи:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

// Обновление статьи
router.put('/:id', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const userId = req.user?.id;
    const articleId = req.params.id;
    const { title, content, excerpt, coverImage, isPublished } = req.body;

    // Проверка принадлежности статьи пользователю
    const articleResult = await pool.query(
      'SELECT id FROM articles WHERE id = $1 AND author_id = $2',
      [articleId, userId]
    );

    if (articleResult.rows.length === 0) {
      return res.status(404).json({ error: 'Статья не найдена' });
    }

    const result = await pool.query(`
      UPDATE articles 
      SET title = $1, content = $2, excerpt = $3, cover_image = $4, 
          is_published = $5, updated_at = NOW()
      WHERE id = $6
      RETURNING *
    `, [title, content, excerpt, coverImage, isPublished, articleId]);

    console.log(`Spiritual Platform: Статья обновлена пользователем ${userId}`);
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Spiritual Platform: Ошибка обновления статьи:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

// Удаление статьи
router.delete('/:id', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const userId = req.user?.id;
    const articleId = req.params.id;

    // Проверка принадлежности статьи пользователю
    const articleResult = await pool.query(
      'SELECT id FROM articles WHERE id = $1 AND author_id = $2',
      [articleId, userId]
    );

    if (articleResult.rows.length === 0) {
      return res.status(404).json({ error: 'Статья не найдена' });
    }

    // Удаление изображений статьи
    await pool.query('DELETE FROM article_images WHERE article_id = $1', [articleId]);
    
    // Удаление статьи
    await pool.query('DELETE FROM articles WHERE id = $1', [articleId]);

    console.log(`Spiritual Platform: Статья удалена пользователем ${userId}`);
    res.json({ message: 'Статья успешно удалена' });
  } catch (error) {
    console.error('Spiritual Platform: Ошибка удаления статьи:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

// Публикация/снятие с публикации статьи
router.patch('/:id/publish', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const userId = req.user?.id;
    const articleId = req.params.id;
    const { isPublished } = req.body;

    // Проверка принадлежности статьи пользователю
    const articleResult = await pool.query(
      'SELECT id FROM articles WHERE id = $1 AND author_id = $2',
      [articleId, userId]
    );

    if (articleResult.rows.length === 0) {
      return res.status(404).json({ error: 'Статья не найдена' });
    }

    await pool.query(
      'UPDATE articles SET is_published = $1, updated_at = NOW() WHERE id = $2',
      [isPublished, articleId]
    );

    const action = isPublished ? 'опубликована' : 'снята с публикации';
    console.log(`Spiritual Platform: Статья ${action} пользователем ${userId}`);
    res.json({ message: `Статья успешно ${action}` });
  } catch (error) {
    console.error('Spiritual Platform: Ошибка изменения публикации статьи:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

// Добавление изображения к статье
router.post('/:id/images', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const userId = req.user?.id;
    const articleId = req.params.id;
    const { imageUrl, altText } = req.body;

    // Проверка принадлежности статьи пользователю
    const articleResult = await pool.query(
      'SELECT id FROM articles WHERE id = $1 AND author_id = $2',
      [articleId, userId]
    );

    if (articleResult.rows.length === 0) {
      return res.status(404).json({ error: 'Статья не найдена' });
    }

    const result = await pool.query(`
      INSERT INTO article_images (article_id, image_url, alt_text)
      VALUES ($1, $2, $3)
      RETURNING *
    `, [articleId, imageUrl, altText]);

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Spiritual Platform: Ошибка добавления изображения:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

// Лайк статьи
router.post('/:id/like', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const articleId = req.params.id;

    await pool.query('UPDATE articles SET likes_count = likes_count + 1 WHERE id = $1', [articleId]);

    res.json({ message: 'Лайк добавлен' });
  } catch (error) {
    console.error('Spiritual Platform: Ошибка добавления лайка:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

export default router;

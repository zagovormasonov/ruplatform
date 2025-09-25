import express from 'express';
import pool from '../database/connection';
import { authenticateToken, AuthRequest } from '../middleware/auth';

const router = express.Router();

// Получение списка чатов пользователя
router.get('/', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const userId = req.user?.id;

    const result = await pool.query(`
      SELECT c.id, c.last_message, c.last_message_at, c.created_at,
             CASE 
               WHEN c.user1_id = $1 THEN u2.first_name || ' ' || u2.last_name
               ELSE u1.first_name || ' ' || u1.last_name
             END as other_user_name,
             CASE 
               WHEN c.user1_id = $1 THEN u2.avatar_url
               ELSE u1.avatar_url
             END as other_user_avatar,
             CASE 
               WHEN c.user1_id = $1 THEN c.user2_id
               ELSE c.user1_id
             END as other_user_id,
             (SELECT COUNT(*) FROM messages m WHERE m.chat_id = c.id AND m.sender_id != $1 AND m.is_read = false) as unread_count
      FROM chats c
      JOIN users u1 ON c.user1_id = u1.id
      JOIN users u2 ON c.user2_id = u2.id
      WHERE c.user1_id = $1 OR c.user2_id = $1
      ORDER BY c.last_message_at DESC NULLS LAST, c.created_at DESC
    `, [userId]);

    res.json(result.rows);
  } catch (error) {
    console.error('Spiritual Platform: Ошибка получения чатов:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

// Создание нового чата или получение существующего
router.post('/start', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const userId = req.user?.id;
    const { otherUserId } = req.body;

    console.log('Spiritual Platform Server: Запрос на создание чата');
    console.log('Spiritual Platform Server: Пользователь:', userId);
    console.log('Spiritual Platform Server: Собеседник:', otherUserId);

    if (!otherUserId) {
      console.log('Spiritual Platform Server: Ошибка - ID собеседника обязателен');
      return res.status(400).json({ error: 'ID собеседника обязателен' });
    }

    if (userId === parseInt(otherUserId)) {
      console.log('Spiritual Platform Server: Ошибка - нельзя создать чат с самим собой');
      return res.status(400).json({ error: 'Нельзя создать чат с самим собой' });
    }

    // Проверка существования собеседника
    console.log('Spiritual Platform Server: Проверяем существование пользователя:', otherUserId);
    const userExists = await pool.query('SELECT id FROM users WHERE id = $1', [otherUserId]);
    if (userExists.rows.length === 0) {
      console.log('Spiritual Platform Server: Ошибка - пользователь не найден:', otherUserId);
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    // Поиск существующего чата
    console.log('Spiritual Platform Server: Ищем существующий чат между пользователями:', userId, 'и', otherUserId);
    let existingChat = await pool.query(`
      SELECT * FROM chats
      WHERE (user1_id = $1 AND user2_id = $2) OR (user1_id = $2 AND user2_id = $1)
    `, [userId, otherUserId]);

    let chat;
    if (existingChat.rows.length > 0) {
      chat = existingChat.rows[0];
      console.log('Spiritual Platform Server: Найден существующий чат:', chat.id);
    } else {
      // Создание нового чата
      console.log('Spiritual Platform Server: Создаем новый чат между пользователями:', userId, 'и', otherUserId);
      const newChatResult = await pool.query(`
        INSERT INTO chats (user1_id, user2_id)
        VALUES ($1, $2)
        RETURNING *
      `, [userId, otherUserId]);
      chat = newChatResult.rows[0];
      console.log('Spiritual Platform Server: Новый чат создан:', chat.id);
    }

    // Получение информации о собеседнике
    console.log('Spiritual Platform Server: Получаем информацию о собеседнике:', otherUserId);
    const otherUserResult = await pool.query(`
      SELECT id, first_name, last_name, avatar_url, role
      FROM users WHERE id = $1
    `, [otherUserId]);

    const response = {
      chatId: chat.id,
      otherUser: otherUserResult.rows[0]
    };

    console.log('Spiritual Platform Server: Отправляем ответ:', response);

    res.json(response);
  } catch (error) {
    console.error('Spiritual Platform: Ошибка создания чата:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

// Получение сообщений чата
router.get('/:chatId/messages', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const userId = req.user?.id;
    const chatId = req.params.chatId;
    const { page = 1, limit = 50 } = req.query;
    const offset = (Number(page) - 1) * Number(limit);

    // Проверка доступа к чату
    const chatAccess = await pool.query(`
      SELECT id FROM chats 
      WHERE id = $1 AND (user1_id = $2 OR user2_id = $2)
    `, [chatId, userId]);

    if (chatAccess.rows.length === 0) {
      return res.status(403).json({ error: 'Доступ к чату запрещен' });
    }

    // Получение сообщений
    const result = await pool.query(`
      SELECT
        m.id,
        m.chat_id,
        m.sender_id,
        m.content,
        m.is_read,
        m.created_at,
        u.first_name,
        u.last_name,
        u.avatar_url,
        u.role
      FROM messages m
      JOIN users u ON m.sender_id = u.id
      WHERE m.chat_id = $1
      ORDER BY m.created_at ASC
    `, [chatId]);

    // Пометка сообщений как прочитанных
    await pool.query(`
      UPDATE messages
      SET is_read = true
      WHERE chat_id = $1 AND sender_id != $2 AND is_read = false
    `, [chatId, userId]);

    // Подсчет общего количества сообщений
    const countResult = await pool.query(
      'SELECT COUNT(*) as total FROM messages WHERE chat_id = $1',
      [chatId]
    );
    const total = parseInt(countResult.rows[0].total);

    // Формируем правильный ответ
    const messages = result.rows.map(row => ({
      id: row.id,
      chatId: row.chat_id,
      senderId: row.sender_id,
      content: row.content,
      isRead: row.is_read,
      createdAt: row.created_at,
      firstName: row.first_name,
      lastName: row.last_name,
      avatarUrl: row.avatar_url
    }));

    console.log('Spiritual Platform Server: Sending messages:', messages);

    res.json({
      messages: messages,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total,
        totalPages: Math.ceil(total / Number(limit))
      }
    });
  } catch (error) {
    console.error('Spiritual Platform: Ошибка получения сообщений:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

// Отправка сообщения (используется также через WebSocket)
router.post('/:chatId/messages', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const userId = req.user?.id;
    const chatId = req.params.chatId;
    const { content } = req.body;

    if (!content || content.trim() === '') {
      return res.status(400).json({ error: 'Содержание сообщения не может быть пустым' });
    }

    // Проверка доступа к чату
    const chatAccess = await pool.query(`
      SELECT id FROM chats 
      WHERE id = $1 AND (user1_id = $2 OR user2_id = $2)
    `, [chatId, userId]);

    if (chatAccess.rows.length === 0) {
      return res.status(403).json({ error: 'Доступ к чату запрещен' });
    }

    // Сохранение сообщения
    const messageResult = await pool.query(`
      INSERT INTO messages (chat_id, sender_id, content)
      VALUES ($1, $2, $3)
      RETURNING *
    `, [chatId, userId, content.trim()]);

    // Обновление последнего сообщения в чате
    await pool.query(`
      UPDATE chats
      SET last_message = $1, last_message_at = NOW()
      WHERE id = $2
    `, [content.trim(), chatId]);

    // Получение информации об отправителе
    const senderResult = await pool.query(`
      SELECT first_name, last_name, avatar_url
      FROM users WHERE id = $1
    `, [userId]);

    const message = {
      id: messageResult.rows[0].id,
      chatId: messageResult.rows[0].chat_id,
      senderId: messageResult.rows[0].sender_id,
      content: messageResult.rows[0].content,
      isRead: messageResult.rows[0].is_read,
      createdAt: messageResult.rows[0].created_at,
      firstName: senderResult.rows[0].first_name,
      lastName: senderResult.rows[0].last_name,
      avatarUrl: senderResult.rows[0].avatar_url
    };

    console.log(`Spiritual Platform: Сообщение отправлено в чат ${chatId} от пользователя ${userId}:`, message);
    res.status(201).json(message);
  } catch (error) {
    console.error('Spiritual Platform: Ошибка отправки сообщения:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

// Получение информации о чате
router.get('/:chatId', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const userId = req.user?.id;
    const chatId = req.params.chatId;

    const result = await pool.query(`
      SELECT c.id, c.created_at,
             CASE 
               WHEN c.user1_id = $1 THEN u2.id
               ELSE u1.id
             END as other_user_id,
             CASE 
               WHEN c.user1_id = $1 THEN u2.first_name || ' ' || u2.last_name
               ELSE u1.first_name || ' ' || u1.last_name
             END as other_user_name,
             CASE 
               WHEN c.user1_id = $1 THEN u2.avatar_url
               ELSE u1.avatar_url
             END as other_user_avatar,
             CASE 
               WHEN c.user1_id = $1 THEN u2.role
               ELSE u1.role
             END as other_user_role
      FROM chats c
      JOIN users u1 ON c.user1_id = u1.id
      JOIN users u2 ON c.user2_id = u2.id
      WHERE c.id = $2 AND (c.user1_id = $1 OR c.user2_id = $1)
    `, [userId, chatId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Чат не найден' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Spiritual Platform: Ошибка получения информации о чате:', error);
    res.status(500).json({ error: 'Ошибка сервера' });
  }
});

export default router;

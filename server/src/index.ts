import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { createServer } from 'http';
import { Server } from 'socket.io';
import pool from './database/connection';

// Import routes
import authRoutes from './routes/auth';
import userRoutes from './routes/users';
import expertRoutes from './routes/experts';
import articleRoutes from './routes/articles';
import chatRoutes from './routes/chats';

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: process.env.CLIENT_URL || "http://localhost:5173",
    methods: ["GET", "POST"]
  }
});

const PORT = process.env.PORT || 3001;

// Middleware
app.use(helmet());
app.use(cors({
  origin: process.env.CLIENT_URL || "http://localhost:5173",
  credentials: true
}));
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/experts', expertRoutes);
app.use('/api/articles', articleRoutes);
app.use('/api/chats', chatRoutes);

// Socket.IO для чатов
const activeUsers = new Map();

io.on('connection', (socket) => {
  console.log('Spiritual Platform: Пользователь подключился:', socket.id);

  socket.on('join_user', (userId) => {
    activeUsers.set(userId, socket.id);
    socket.join(`user_${userId}`);
  });

  socket.on('join_chat', (chatId) => {
    socket.join(`chat_${chatId}`);
    console.log(`Spiritual Platform: Подключение к чату ${chatId}`);
  });

  socket.on('send_message', async (data) => {
    try {
      const { chatId, senderId, content } = data;
      
      // Сохранение сообщения в БД
      const messageResult = await pool.query(
        'INSERT INTO messages (chat_id, sender_id, content) VALUES ($1, $2, $3) RETURNING *',
        [chatId, senderId, content]
      );

      // Обновление последнего сообщения в чате
      await pool.query(
        'UPDATE chats SET last_message = $1, last_message_at = NOW() WHERE id = $2',
        [content, chatId]
      );

      const message = messageResult.rows[0];

      // Получение информации об отправителе
      const senderResult = await pool.query(
        'SELECT first_name, last_name, avatar_url FROM users WHERE id = $1',
        [senderId]
      );

      const sender = senderResult.rows[0];

      // Получение информации о чате для определения получателя
      const chatInfo = await pool.query(
        'SELECT user1_id, user2_id FROM chats WHERE id = $1',
        [chatId]
      );

      if (chatInfo.rows.length > 0) {
        const chat = chatInfo.rows[0];
        const receiverId = chat.user1_id === senderId ? chat.user2_id : chat.user1_id;

        // Отправка уведомления получателю о новом сообщении
        io.to(`user_${receiverId}`).emit('new_message_notification', {
          chatId: chatId,
          senderId: senderId,
          senderName: `${sender.first_name} ${sender.last_name}`,
          senderAvatar: sender.avatar_url,
          message: content,
          createdAt: message.created_at
        });

        // Тестовое уведомление для проверки
        io.to(`user_${receiverId}`).emit('test_notification', {
          test: true,
          message: 'Тестовое уведомление работает!',
          timestamp: new Date().toISOString()
        });
      }

      // Отправка сообщения всем участникам чата
      io.to(`chat_${chatId}`).emit('new_message', {
        id: message.id,
        chatId: message.chat_id,
        senderId: message.sender_id,
        content: message.content,
        isRead: message.is_read,
        createdAt: message.created_at,
        firstName: sender.first_name,
        lastName: sender.last_name,
        avatarUrl: sender.avatar_url
      });

      console.log(`Spiritual Platform: Сообщение отправлено в чат ${chatId} от пользователя ${senderId}:`, {
        id: message.id,
        chatId: message.chat_id,
        senderId: message.sender_id,
        content: message.content,
        isRead: message.is_read,
        createdAt: message.created_at,
        firstName: sender.first_name,
        lastName: sender.last_name,
        avatarUrl: sender.avatar_url
      });
    } catch (error) {
      console.error('Spiritual Platform: Ошибка отправки сообщения:', error);
      socket.emit('message_error', { error: 'Не удалось отправить сообщение' });
    }
  });

  socket.on('disconnect', () => {
    // Удаление пользователя из активных
    for (const [userId, socketId] of activeUsers.entries()) {
      if (socketId === socket.id) {
        activeUsers.delete(userId);
        break;
      }
    }
    console.log('Spiritual Platform: Пользователь отключился:', socket.id);
  });
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', message: 'Платформа духовных мастеров работает' });
});

// Error handling
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('Spiritual Platform: Ошибка сервера:', err);
  res.status(500).json({ error: 'Внутренняя ошибка сервера' });
});

httpServer.listen(PORT, () => {
  console.log(`Spiritual Platform: Сервер запущен на порту ${PORT}`);
});

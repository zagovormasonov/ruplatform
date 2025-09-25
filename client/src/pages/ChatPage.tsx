import React, { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  Row,
  Col,
  Card,
  List,
  Input,
  Button,
  Avatar,
  Typography,
  Empty,
  Spin,
  Badge,
  Divider,
  message
} from 'antd';
import {
  SendOutlined,
  UserOutlined,
  MessageOutlined,
  ArrowLeftOutlined
} from '@ant-design/icons';
import { chatsAPI } from '../services/api';
import { useAuth } from '../contexts/AuthContext';
import { io, Socket } from 'socket.io-client';
import type { Chat, Message } from '../types/index';
import './ChatPage.css';

const { Text, Title } = Typography;
const { TextArea } = Input;

const ChatPage: React.FC = () => {
  const { chatId } = useParams<{ chatId: string }>();
  const navigate = useNavigate();
  const { user } = useAuth();
  
  // Состояние чатов и сообщений
  const [chats, setChats] = useState<Chat[]>([]);
  const [currentChat, setCurrentChat] = useState<Chat | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [newMessage, setNewMessage] = useState('');
  
  // Состояние загрузки
  const [chatsLoading, setChatsLoading] = useState(true);
  const [messagesLoading, setMessagesLoading] = useState(false);
  const [sendingMessage, setSendingMessage] = useState(false);
  
  // Socket.IO
  const [socket, setSocket] = useState<Socket | null>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!user) {
      navigate('/login');
      return;
    }

    // Инициализация Socket.IO
    const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:3001';
    const socketUrl = apiUrl.replace('/api', '');
    console.log('Spiritual Platform: Подключение к Socket.IO:', socketUrl);
    const newSocket = io(socketUrl);
    setSocket(newSocket);

    newSocket.emit('join_user', user.id);

    // Обработка новых сообщений
    newSocket.on('new_message', (message: Message) => {
      console.log('Spiritual Platform: Получено новое сообщение через Socket.IO:', message);
      setMessages(prev => [...prev, {
        id: message.id,
        chatId: message.chatId,
        senderId: message.senderId,
        content: message.content,
        createdAt: message.createdAt,
        isRead: true,
        firstName: message.firstName || '',
        lastName: message.lastName || '',
        avatarUrl: message.avatarUrl
      }]);
      scrollToBottom();
    });

    // Обработка уведомлений о новых сообщениях
    newSocket.on('new_message_notification', (notification: any) => {
      console.log('Spiritual Platform: Получено уведомление о новом сообщении:', notification);

      // Обновляем список чатов для показа индикатора новых сообщений
      loadChats();

      // Показываем уведомление пользователю
      if (Notification.permission === 'granted') {
        new Notification(`Новое сообщение от ${notification.senderName}`, {
          body: notification.message,
          icon: notification.senderAvatar || '/favicon.ico'
        });
      }

      // Показываем сообщение в UI
      message.info(`Новое сообщение от ${notification.senderName}`);
    });

    // Обработка ошибок подключения
    newSocket.on('connect', () => {
      console.log('Spiritual Platform: Socket.IO подключен');
    });

    // Запрос разрешения на уведомления
    if (Notification.permission === 'default') {
      Notification.requestPermission();
    }

    newSocket.on('disconnect', () => {
      console.log('Spiritual Platform: Socket.IO отключен');
    });

    newSocket.on('connect_error', (error) => {
      console.error('Spiritual Platform: Ошибка подключения Socket.IO:', error);
    });

    // Загрузка списка чатов
    loadChats();

    return () => {
      newSocket.close();
    };
  }, [user, navigate]);

  useEffect(() => {
    if (chatId && socket) {
      loadChatMessages(chatId);
      socket.emit('join_chat', chatId);
    }
  }, [chatId, socket]);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const loadChats = async () => {
    try {
      setChatsLoading(true);
      const chatsData = await chatsAPI.getAll();
      setChats(chatsData);
      
      // Если нет выбранного чата, но есть чаты, выбираем первый
      if (!chatId && chatsData.length > 0) {
        navigate(`/chat/${chatsData[0].id}`);
      }
    } catch (error) {
      console.error('Spiritual Platform: Ошибка загрузки чатов:', error);
    } finally {
      setChatsLoading(false);
    }
  };

  const loadChatMessages = async (selectedChatId: string) => {
    try {
      setMessagesLoading(true);

      // Получение информации о чате
      const chatInfo = await chatsAPI.getChatInfo(selectedChatId);
      console.log('Spiritual Platform: Chat info loaded:', chatInfo);
      setCurrentChat(chatInfo);

      // Получение сообщений
      const messagesData = await chatsAPI.getMessages(selectedChatId, {
        page: 1,
        limit: 50
      });

      console.log('Spiritual Platform: Messages loaded from API:', messagesData.messages);

      // Логируем каждое сообщение для отладки
      messagesData.messages.forEach((msg, index) => {
        console.log(`Spiritual Platform: Message ${index}:`, {
          id: msg.id,
          senderId: msg.senderId,
          userId: user?.id,
          isOwn: user ? msg.senderId === user.id : false,
          firstName: msg.firstName,
          lastName: msg.lastName,
          content: msg.content,
          createdAt: msg.createdAt
        });
      });

      setMessages(messagesData.messages);
    } catch (error) {
      console.error('Spiritual Platform: Ошибка загрузки сообщений:', error);
    } finally {
      setMessagesLoading(false);
    }
  };

  const handleSendMessage = async () => {
    if (!newMessage.trim() || !chatId || !user) return;

    try {
      setSendingMessage(true);

      const messageData = {
        chatId: parseInt(chatId),
        senderId: user.id,
        content: newMessage.trim()
      };

      console.log('Spiritual Platform: Отправка сообщения:', messageData);
      console.log('Spiritual Platform: User info:', {
        id: user.id,
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email
      });

      if (socket && socket.connected) {
        // Отправка через Socket.IO
        socket.emit('send_message', messageData);
        console.log('Spiritual Platform: Сообщение отправлено через Socket.IO');
      } else {
        // Fallback: отправка через HTTP API
        console.log('Spiritual Platform: Socket не подключен, используем HTTP API');
        const sentMessage = await chatsAPI.sendMessage(chatId, newMessage.trim());

        console.log('Spiritual Platform: Message sent via HTTP:', sentMessage);

        // Добавляем сообщение в локальный стейт
        const newMsg: Message = {
          id: sentMessage.id,
          chatId: parseInt(chatId),
          senderId: user.id,
          content: newMessage.trim(),
          createdAt: sentMessage.createdAt || new Date().toISOString(),
          isRead: true,
          firstName: user.firstName,
          lastName: user.lastName,
          avatarUrl: user.avatarUrl
        };

        console.log('Spiritual Platform: Adding message to state:', newMsg);

        setMessages(prev => [...prev, newMsg]);
        scrollToBottom();
      }

      setNewMessage('');
    } catch (error) {
      console.error('Spiritual Platform: Ошибка отправки сообщения:', error);
    } finally {
      setSendingMessage(false);
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const formatMessageTime = (dateString: string) => {
    if (!dateString) {
      console.log('Spiritual Platform: dateString is empty');
      return '';
    }

    console.log('Spiritual Platform: Formatting date:', dateString);

    let date: Date;

    // Если дата уже в формате ISO, парсим как есть
    if (dateString.includes('T') || dateString.includes('Z')) {
      date = new Date(dateString);
    } else {
      // Если дата в формате без времени, добавляем время
      date = new Date(dateString + 'T00:00:00');
    }

    console.log('Spiritual Platform: Parsed date:', date);
    console.log('Spiritual Platform: Is valid:', !isNaN(date.getTime()));

    if (isNaN(date.getTime())) {
      console.log('Spiritual Platform: Invalid date, trying alternative parsing');
      // Попробуем другой формат
      const timestamp = Date.parse(dateString);
      if (!isNaN(timestamp)) {
        date = new Date(timestamp);
      } else {
        console.log('Spiritual Platform: Cannot parse date:', dateString);
        return '';
      }
    }

    const now = new Date();
    const diffInHours = (now.getTime() - date.getTime()) / (1000 * 60 * 60);

    console.log('Spiritual Platform: Date difference in hours:', diffInHours);

    if (diffInHours < 24) {
      const timeStr = date.toLocaleTimeString('ru-RU', {
        hour: '2-digit',
        minute: '2-digit'
      });
      console.log('Spiritual Platform: Formatted as today time:', timeStr);
      return timeStr;
    } else if (diffInHours < 24 * 7) {
      const timeStr = date.toLocaleDateString('ru-RU', {
        weekday: 'short',
        hour: '2-digit',
        minute: '2-digit'
      });
      console.log('Spiritual Platform: Formatted as week time:', timeStr);
      return timeStr;
    } else {
      const timeStr = date.toLocaleDateString('ru-RU', {
        day: 'numeric',
        month: 'short',
        hour: '2-digit',
        minute: '2-digit'
      });
      console.log('Spiritual Platform: Formatted as old time:', timeStr);
      return timeStr;
    }
  };

  const handleChatSelect = async (selectedChatId: number) => {
    // Сбрасываем индикатор новых сообщений для выбранного чата
    setChats(prevChats =>
      prevChats.map(chat =>
        chat.id === selectedChatId
          ? { ...chat, hasNewMessage: false }
          : chat
      )
    );

    navigate(`/chat/${selectedChatId}`);
  };

  if (!user) {
    return null;
  }

  return (
    <div className="chat-page">
      <Row gutter={0} className="chat-container">
        {/* Список чатов */}
        <Col xs={24} md={8} lg={6} className="chats-sidebar">
          <Card 
            title={
              <div className="sidebar-header">
                <Button
                  icon={<ArrowLeftOutlined />}
                  type="text"
                  onClick={() => navigate(-1)}
                  className="mobile-back-btn"
                />
                <Title level={5} style={{ margin: 0 }}>Чаты</Title>
              </div>
            }
            className="chats-card"
          >
            {chatsLoading ? (
              <div className="loading-container">
                <Spin />
              </div>
            ) : chats.length === 0 ? (
              <Empty
                image={Empty.PRESENTED_IMAGE_SIMPLE}
                description="У вас пока нет чатов"
              />
            ) : (
              <List
                dataSource={chats}
                renderItem={(chat) => (
                  <List.Item
                    className={`chat-item ${chatId === chat.id.toString() ? 'active' : ''}`}
                    onClick={() => handleChatSelect(chat.id)}
                  >
                    <List.Item.Meta
                      avatar={
                        <div style={{ position: 'relative' }}>
                          <Badge count={chat.unreadCount} size="small">
                            <Avatar
                              src={chat.otherUserAvatar}
                              icon={<UserOutlined />}
                              size={40}
                            />
                          </Badge>
                          {chat.hasNewMessage && (
                            <div
                              style={{
                                position: 'absolute',
                                top: -2,
                                right: -2,
                                width: 12,
                                height: 12,
                                backgroundColor: '#ff4d4f',
                                borderRadius: '50%',
                                border: '2px solid white',
                                zIndex: 10
                              }}
                            />
                          )}
                        </div>
                      }
                      title={
                        <div className="chat-title">
                          <Text strong className="chat-name">
                            {chat.otherUserName}
                          </Text>
                          {chat.lastMessageAt && (
                            <Text className="chat-time">
                              {formatMessageTime(chat.lastMessageAt)}
                            </Text>
                          )}
                        </div>
                      }
                      description={
                        <Text className="chat-last-message" ellipsis>
                          {chat.lastMessage || 'Начните общение'}
                        </Text>
                      }
                    />
                  </List.Item>
                )}
              />
            )}
          </Card>
        </Col>

        {/* Область сообщений */}
        <Col xs={24} md={16} lg={18} className="messages-area">
          {chatId && currentChat ? (
            <Card className="messages-card">
              {/* Заголовок чата */}
              <div className="chat-header">
                <div className="chat-user-info">
                  <Avatar
                    src={currentChat.otherUserAvatar}
                    icon={<UserOutlined />}
                    size={40}
                  />
                  <div className="user-details">
                    <Text strong>{currentChat.otherUserName}</Text>
                    <Text type="secondary" className="user-role">
                      {currentChat.otherUserRole === 'expert' ? 'Эксперт' : 'Пользователь'}
                    </Text>
                  </div>
                </div>
                <div className="chat-info">
                  <Text type="secondary" className="chat-status">
                    {messages.length > 0 ? `${messages.length} сообщений` : 'Нет сообщений'}
                  </Text>
                  <Text type="secondary" className="chat-debug">
                    ID: {currentChat.id}, User1: {currentChat.user1Id}, User2: {currentChat.user2Id}
                  </Text>
                </div>
              </div>

              <Divider style={{ margin: '16px 0' }} />

              {/* Сообщения */}
              <div className="messages-container">
                {messagesLoading ? (
                  <div className="loading-container">
                    <Spin size="large" />
                  </div>
                ) : messages.length === 0 ? (
                  <div className="empty-messages">
                    <MessageOutlined className="empty-icon" />
                    <Text type="secondary">Начните общение с экспертом</Text>
                  </div>
                ) : (
                  <div className="messages-list">
                    {messages.map((message) => {
                      const isOwnMessage = message.senderId === user.id;

                      console.log('Spiritual Platform: Rendering message:', {
                        id: message.id,
                        senderId: message.senderId,
                        userId: user?.id,
                        isOwnMessage,
                        firstName: message.firstName,
                        lastName: message.lastName,
                        content: message.content,
                        createdAt: message.createdAt
                      });

                      return (
                        <div
                          key={message.id}
                          className={`message ${
                            isOwnMessage ? 'own-message' : 'other-message'
                          }`}
                        >
                          {!isOwnMessage && (
                            <Avatar
                              src={message.avatarUrl}
                              icon={<UserOutlined />}
                              size="small"
                              className="message-avatar"
                            />
                          )}
                          <div className="message-content">
                            {!isOwnMessage && (
                              <Text className="message-sender-name">
                                {message.firstName} {message.lastName}
                              </Text>
                            )}
                            <div className="message-bubble">
                              <Text>{message.content}</Text>
                            </div>
                            <Text className="message-time">
                              {formatMessageTime(message.createdAt)}
                            </Text>
                          </div>
                        </div>
                      );
                    })}
                    <div ref={messagesEndRef} />
                  </div>
                )}
              </div>

              {/* Ввод сообщения */}
              <div className="message-input-container">
                <div className="message-input">
                  <TextArea
                    value={newMessage}
                    onChange={(e) => setNewMessage(e.target.value)}
                    onKeyPress={handleKeyPress}
                    placeholder="Введите сообщение..."
                    autoSize={{ minRows: 1, maxRows: 4 }}
                    className="input-field"
                  />
                  <Button
                    type="primary"
                    icon={<SendOutlined />}
                    onClick={handleSendMessage}
                    loading={sendingMessage}
                    disabled={!newMessage.trim()}
                    className="send-button"
                  />
                </div>
              </div>
            </Card>
          ) : (
            <Card className="no-chat-selected">
              <div className="no-chat-content">
                <MessageOutlined className="no-chat-icon" />
                <Title level={4}>Выберите чат</Title>
                <Text type="secondary">
                  Выберите чат из списка слева, чтобы начать общение
                </Text>
              </div>
            </Card>
          )}
        </Col>
      </Row>
    </div>
  );
};

export default ChatPage;
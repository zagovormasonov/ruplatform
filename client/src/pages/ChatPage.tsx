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
  Divider
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
        avatarUrl: message.avatarUrl
      }]);
      scrollToBottom();
    });

    // Обработка ошибок подключения
    newSocket.on('connect', () => {
      console.log('Spiritual Platform: Socket.IO подключен');
    });

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
      setCurrentChat(chatInfo);
      
      // Получение сообщений
      const messagesData = await chatsAPI.getMessages(selectedChatId, {
        page: 1,
        limit: 50
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

      if (socket && socket.connected) {
        // Отправка через Socket.IO
        socket.emit('send_message', messageData);
        console.log('Spiritual Platform: Сообщение отправлено через Socket.IO');
      } else {
        // Fallback: отправка через HTTP API
        console.log('Spiritual Platform: Socket не подключен, используем HTTP API');
        const sentMessage = await chatsAPI.sendMessage(chatId, newMessage.trim());
        
        // Добавляем сообщение в локальный стейт
        const newMsg: Message = {
          id: sentMessage.id,
          chatId: parseInt(chatId),
          senderId: user.id,
          content: newMessage.trim(),
          createdAt: new Date().toISOString(),
          avatarUrl: user.avatarUrl
        };
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
    const date = new Date(dateString);
    const now = new Date();
    const diffInHours = (now.getTime() - date.getTime()) / (1000 * 60 * 60);

    if (diffInHours < 24) {
      return date.toLocaleTimeString('ru-RU', {
        hour: '2-digit',
        minute: '2-digit'
      });
    } else {
      return date.toLocaleDateString('ru-RU', {
        day: 'numeric',
        month: 'short'
      });
    }
  };

  const handleChatSelect = (selectedChatId: number) => {
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
                        <Badge count={chat.unreadCount} size="small">
                          <Avatar
                            src={chat.otherUserAvatar}
                            icon={<UserOutlined />}
                            size={40}
                          />
                        </Badge>
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
                    {messages.map((message) => (
                      <div
                        key={message.id}
                        className={`message ${
                          message.senderId === user.id ? 'own-message' : 'other-message'
                        }`}
                      >
                        {message.senderId !== user.id && (
                          <Avatar
                            src={message.avatarUrl}
                            icon={<UserOutlined />}
                            size="small"
                            className="message-avatar"
                          />
                        )}
                        <div className="message-content">
                          <div className="message-bubble">
                            <Text>{message.content}</Text>
                          </div>
                          <Text className="message-time">
                            {formatMessageTime(message.createdAt)}
                          </Text>
                        </div>
                      </div>
                    ))}
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
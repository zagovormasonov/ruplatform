import React, { createContext, useContext, useState, useEffect } from 'react';
import { io, Socket } from 'socket.io-client';
import { useAuth } from './AuthContext';

interface ChatContextType {
  unreadCount: number;
  setUnreadCount: (count: number) => void;
  socket: Socket | null;
}

const ChatContext = createContext<ChatContextType | undefined>(undefined);

export const useChatContext = () => {
  const context = useContext(ChatContext);
  if (!context) {
    throw new Error('useChatContext must be used within a ChatProvider');
  }
  return context;
};

interface ChatProviderProps {
  children: React.ReactNode;
}

export const ChatProvider: React.FC<ChatProviderProps> = ({ children }) => {
  const { user } = useAuth();
  const [unreadCount, setUnreadCount] = useState(0);
  const [socket, setSocket] = useState<Socket | null>(null);

  useEffect(() => {
    if (!user) {
      setSocket(null);
      setUnreadCount(0);
      return;
    }

    // Инициализация Socket.IO
    const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:3001';
    const socketUrl = apiUrl.replace('/api', '');
    console.log('Spiritual Platform Chat Context: Подключение к Socket.IO:', socketUrl);
    
    const newSocket = io(socketUrl);
    setSocket(newSocket);

    newSocket.emit('join_user', user.id);

    // Обработка новых сообщений для счетчика
    newSocket.on('new_message', (message: any) => {
      // Увеличиваем счетчик только если пользователь не отправитель
      if (message.senderId !== user.id) {
        // Проверяем, находится ли пользователь на странице чата
        const isOnChatPage = window.location.pathname.startsWith('/chat');
        
        if (!isOnChatPage) {
          // Если не на странице чата, увеличиваем счетчик
          setUnreadCount(prev => prev + 1);
        }
      }
    });

    newSocket.on('connect', () => {
      console.log('Spiritual Platform Chat Context: Socket.IO подключен');
    });

    newSocket.on('disconnect', () => {
      console.log('Spiritual Platform Chat Context: Socket.IO отключен');
    });

    return () => {
      newSocket.close();
    };
  }, [user]);

  const value = {
    unreadCount,
    setUnreadCount,
    socket
  };

  return (
    <ChatContext.Provider value={value}>
      {children}
    </ChatContext.Provider>
  );
};

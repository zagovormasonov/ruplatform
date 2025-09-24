import React, { createContext, useContext, useState, useEffect } from 'react';
import type { ReactNode } from 'react';
import type { User, RegisterData } from '../types/user';
import type { AuthContextType } from '../types/index';
import { authAPI } from '../services/api';
import { App } from 'antd';

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

interface AuthProviderProps {
  children: ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [token, setToken] = useState<string | null>(localStorage.getItem('token'));
  const [isLoading, setIsLoading] = useState(true);
  const { message } = App.useApp();

  const login = async (email: string, password: string) => {
    try {
      setIsLoading(true);
      const response = await authAPI.login(email, password);
      setUser(response.user);
      setToken(response.token);
      localStorage.setItem('token', response.token);
      message.success('Успешная авторизация');
    } catch (error: any) {
      const errorMessage = error.response?.data?.error || 'Ошибка авторизации';
      message.error(errorMessage);
      throw error;
    } finally {
      setIsLoading(false);
    }
  };

  const register = async (data: RegisterData) => {
    try {
      setIsLoading(true);
      const response = await authAPI.register(data);
      setUser(response.user);
      setToken(response.token);
      localStorage.setItem('token', response.token);
      message.success('Успешная регистрация');
    } catch (error: any) {
      const errorMessage = error.response?.data?.error || 'Ошибка регистрации';
      message.error(errorMessage);
      throw error;
    } finally {
      setIsLoading(false);
    }
  };

  const logout = () => {
    setUser(null);
    setToken(null);
    localStorage.removeItem('token');
    message.success('Вы вышли из системы');
  };

  const verifyToken = async () => {
    if (!token) {
      setIsLoading(false);
      return;
    }

    try {
      const response = await authAPI.verifyToken();
      setUser(response.user);
      console.log('Spiritual Platform: Токен действителен, пользователь авторизован');
    } catch (error) {
      console.error('Spiritual Platform: Ошибка проверки токена:', error);
      console.log('Spiritual Platform: Токен недействителен, выполняется logout');
      localStorage.removeItem('token');
      setToken(null);
      setUser(null);
    } finally {
      setIsLoading(false);
    }
  };

  // Функция для проверки срока действия токена
  const isTokenExpired = (token: string): boolean => {
    try {
      const payload = JSON.parse(atob(token.split('.')[1]));
      const currentTime = Date.now() / 1000;
      return payload.exp < currentTime;
    } catch (error) {
      return true;
    }
  };

  useEffect(() => {
    verifyToken();
  }, [token]); // Проверяем токен только при его изменении

  // Периодическая проверка токена каждые 30 минут
  useEffect(() => {
    if (!token) return;

    const checkToken = () => {
      if (isTokenExpired(token)) {
        console.log('Spiritual Platform: Токен истек, выполняется logout');
        logout();
      }
    };

    // Проверяем сразу
    checkToken();
    
    // Устанавливаем интервал проверки каждые 30 минут
    const interval = setInterval(checkToken, 30 * 60 * 1000);

    return () => clearInterval(interval);
  }, [token]);

  const value: AuthContextType = {
    user,
    token,
    login,
    register,
    logout,
    isLoading,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

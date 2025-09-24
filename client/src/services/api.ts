import axios from 'axios';
import type { User, RegisterData } from '../types/user';
import type { Article } from '../types/article';
import type { Expert, Topic, City, Chat, Message } from '../types/index';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Interceptor для добавления токена к запросам
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Interceptor для обработки ошибок
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      console.log('Spiritual Platform: Получен 401, токен недействителен');
      localStorage.removeItem('token');
      // Перенаправляем только если не на странице логина
      if (window.location.pathname !== '/login' && window.location.pathname !== '/register') {
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

// Auth API
export const authAPI = {
  login: async (email: string, password: string): Promise<{ user: User; token: string }> => {
    const response = await api.post('/auth/login', { email, password });
    return response.data;
  },

  register: async (data: RegisterData): Promise<{ user: User; token: string }> => {
    const response = await api.post('/auth/register', data);
    return response.data;
  },

  verifyToken: async (): Promise<{ user: User }> => {
    const response = await api.get('/auth/verify');
    return response.data;
  },
};

// Users API
export const usersAPI = {
  getProfile: async (): Promise<User> => {
    const response = await api.get('/users/profile');
    return response.data;
  },

  updateProfile: async (data: Partial<User>): Promise<User> => {
    const response = await api.put('/users/profile', data);
    return response.data.user;
  },

  getCities: async (): Promise<City[]> => {
    const response = await api.get('/users/cities');
    return response.data;
  },

  getTopics: async (): Promise<Topic[]> => {
    const response = await api.get('/users/topics');
    return response.data;
  },
};

// Experts API
export const expertsAPI = {
  search: async (params: {
    topics?: string[];
    city?: string;
    serviceType?: string;
    search?: string;
    sortBy?: string;
    page?: number;
    limit?: number;
  }): Promise<{ experts: Expert[]; pagination: any }> => {
    const response = await api.get('/experts/search', { 
      params,
      paramsSerializer: {
        indexes: null // Это заставит axios использовать формат topics=val1&topics=val2
      }
    });
    return response.data;
  },

  getById: async (id: string): Promise<Expert> => {
    const response = await api.get(`/experts/${id}`);
    return response.data;
  },

  getMyProfile: async (): Promise<Expert> => {
    const response = await api.get('/experts/profile/me');
    return response.data;
  },

  updateProfile: async (data: any): Promise<void> => {
    await api.put('/experts/profile', data);
  },

  createService: async (data: any): Promise<any> => {
    const response = await api.post('/experts/services', data);
    return response.data;
  },

  getMyServices: async (): Promise<any[]> => {
    const response = await api.get('/experts/services/my');
    return response.data;
  },

  updateService: async (id: string, data: any): Promise<any> => {
    const response = await api.put(`/experts/services/${id}`, data);
    return response.data;
  },

  deleteService: async (id: string): Promise<void> => {
    await api.delete(`/experts/services/${id}`);
  },
};

// Articles API
export const articlesAPI = {
  getAll: async (params: {
    page?: number;
    limit?: number;
    sort?: 'new' | 'popular';
  }): Promise<{ articles: Article[]; pagination: any }> => {
    const response = await api.get('/articles', { params });
    return response.data;
  },

  getById: async (id: string): Promise<Article> => {
    const response = await api.get(`/articles/${id}`);
    return response.data;
  },

  getMy: async (params: {
    page?: number;
    limit?: number;
  }): Promise<{ articles: Article[]; pagination: any }> => {
    const response = await api.get('/articles/my/articles', { params });
    return response.data;
  },

  create: async (data: {
    title: string;
    content: string;
    excerpt?: string;
    coverImage?: string;
    isPublished?: boolean;
  }): Promise<Article> => {
    const response = await api.post('/articles', data);
    return response.data;
  },

  update: async (id: string, data: {
    title: string;
    content: string;
    excerpt?: string;
    coverImage?: string;
    isPublished?: boolean;
  }): Promise<Article> => {
    const response = await api.put(`/articles/${id}`, data);
    return response.data;
  },

  delete: async (id: string): Promise<void> => {
    await api.delete(`/articles/${id}`);
  },

  togglePublish: async (id: string, isPublished: boolean): Promise<void> => {
    await api.patch(`/articles/${id}/publish`, { isPublished });
  },

  like: async (id: string): Promise<void> => {
    await api.post(`/articles/${id}/like`);
  },

  addImage: async (id: string, data: {
    imageUrl: string;
    altText?: string;
  }): Promise<any> => {
    const response = await api.post(`/articles/${id}/images`, data);
    return response.data;
  },
};

// Chats API
export const chatsAPI = {
  getAll: async (): Promise<Chat[]> => {
    const response = await api.get('/chats');
    return response.data;
  },

  start: async (otherUserId: number): Promise<{ chatId: number; otherUser: any }> => {
    const response = await api.post('/chats/start', { otherUserId });
    return response.data;
  },

  getMessages: async (chatId: string, params: {
    page?: number;
    limit?: number;
  }): Promise<{ messages: Message[]; pagination: any }> => {
    const response = await api.get(`/chats/${chatId}/messages`, { params });
    return response.data;
  },

  sendMessage: async (chatId: string, content: string): Promise<Message> => {
    const response = await api.post(`/chats/${chatId}/messages`, { content });
    return response.data;
  },

  getChatInfo: async (chatId: string): Promise<any> => {
    const response = await api.get(`/chats/${chatId}`);
    return response.data;
  },
};

export default api;

// Основные интерфейсы для платформы духовных мастеров
import type { User, RegisterData } from './user';

// Реэкспорт для обратной совместимости
export type { User, RegisterData } from './user';
export type { Article } from './article';

export interface AuthContextType {
  user: User | null;
  token: string | null;
  login: (email: string, password: string) => Promise<void>;
  register: (data: RegisterData) => Promise<void>;
  logout: () => void;
  isLoading: boolean;
}

export interface Topic {
  id: number;
  name: string;
  description?: string;
}

export interface City {
  id: number;
  name: string;
  region: string;
}

export interface Service {
  id: number;
  expertId: number;
  title: string;
  description: string;
  price: number;
  durationMinutes: number;
  serviceType: 'online' | 'offline';
  isActive: boolean;
}

export interface Review {
  id: number;
  expertId: number;
  reviewerId: number;
  rating: number;
  comment: string;
  createdAt: string;
  firstName: string;
  lastName: string;
  avatarUrl?: string;
}

export interface Expert {
  id: number;
  firstName: string;
  lastName: string;
  avatarUrl?: string;
  bio?: string;
  rating: number;
  reviewsCount: number;
  cityName?: string;
  region?: string;
  topics: string[];
  services: Service[];
  reviews?: Review[];
}

// Article интерфейс теперь в отдельном файле article.ts

export interface Message {
  id: number;
  chatId: number;
  senderId: number;
  content: string;
  isRead: boolean;
  createdAt: string;
  firstName: string;
  lastName: string;
  avatarUrl?: string;
}

export interface Chat {
  id: number;
  otherUserName: string;
  otherUserAvatar?: string;
  otherUserId: number;
  otherUserRole?: string;
  lastMessage?: string;
  lastMessageAt?: string;
  unreadCount: number;
}
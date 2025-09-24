export interface User {
  id: number;
  email: string;
  firstName: string;
  lastName: string;
  role: 'user' | 'expert';
  avatarUrl?: string;
  phone?: string;
  city?: string;
}

export interface RegisterData {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  role: 'user' | 'expert';
}

export interface Article {
  id: number;
  title: string;
  content: string;
  excerpt?: string;
  coverImage?: string;
  viewsCount: number;
  likesCount: number;
  isPublished: boolean;
  createdAt: string;
  updatedAt: string;
  firstName: string;
  lastName: string;
  avatarUrl?: string;
}

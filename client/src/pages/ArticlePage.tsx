import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  Card,
  Typography,
  Button,
  Avatar,
  Divider,
  Space,
  Spin,
  message
} from 'antd';
import {
  ArrowLeftOutlined,
  HeartOutlined,
  HeartFilled,
  EyeOutlined,
  UserOutlined,
  CalendarOutlined,
  ClockCircleOutlined
} from '@ant-design/icons';
import { articlesAPI } from '../services/api';
import { useAuth } from '../contexts/AuthContext';
import type { Article } from '../types/article';
import './ArticlePage.css';

const { Title, Text, Paragraph } = Typography;

const ArticlePage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user } = useAuth();
  
  const [article, setArticle] = useState<Article | null>(null);
  const [loading, setLoading] = useState(true);
  const [liked, setLiked] = useState(false);

  useEffect(() => {
    if (id) {
      loadArticle(id);
    }
  }, [id]);

  const loadArticle = async (articleId: string) => {
    try {
      setLoading(true);
      const data = await articlesAPI.getById(articleId);
      setArticle(data);
    } catch (error) {
      console.error('Spiritual Platform: Ошибка загрузки статьи:', error);
      message.error('Статья не найдена');
      navigate('/articles');
    } finally {
      setLoading(false);
    }
  };

  const handleLike = async () => {
    if (!user || !article) {
      message.warning('Войдите в систему, чтобы поставить лайк');
      return;
    }

    try {
      await articlesAPI.like(article.id.toString());
      setLiked(!liked);
      setArticle(prev => prev ? {
        ...prev,
        likesCount: liked ? prev.likesCount - 1 : prev.likesCount + 1
      } : null);
    } catch (error) {
      console.error('Spiritual Platform: Ошибка лайка:', error);
      message.error('Не удалось поставить лайк');
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('ru-RU', {
      day: 'numeric',
      month: 'long',
      year: 'numeric'
    });
  };

  const estimateReadingTime = (content: string) => {
    const wordsPerMinute = 200;
    const words = content.split(' ').length;
    const minutes = Math.ceil(words / wordsPerMinute);
    return `${minutes} мин чтения`;
  };

  if (loading) {
    return (
      <div className="loading-container">
        <Spin size="large" />
      </div>
    );
  }

  if (!article) {
    return null;
  }

  return (
    <div className="article-page">
      <div className="article-header">
        <Button
          icon={<ArrowLeftOutlined />}
          onClick={() => navigate(-1)}
          className="back-button"
        >
          Назад
        </Button>
      </div>

      <article className="article-content">
        {article.coverImage && (
          <div className="article-cover">
            <img src={article.coverImage} alt={article.title} />
          </div>
        )}

        <Card className="article-card">
          <div className="article-meta">
            <div className="author-info">
              <Avatar
                src={article.avatarUrl}
                icon={<UserOutlined />}
                size={48}
              />
              <div className="author-details">
                <Text strong className="author-name">
                  {article.firstName} {article.lastName}
                </Text>
                <div className="article-date">
                  <CalendarOutlined />
                  <Text type="secondary">
                    {formatDate(article.createdAt)}
                  </Text>
                </div>
              </div>
            </div>

            <div className="article-stats">
              <Space size="large">
                <div className="stat-item">
                  <EyeOutlined />
                  <Text type="secondary">{article.viewsCount}</Text>
                </div>
                <div className="stat-item">
                  <ClockCircleOutlined />
                  <Text type="secondary">{estimateReadingTime(article.content)}</Text>
                </div>
              </Space>
            </div>
          </div>

          <Divider />

          <div className="article-header-content">
            <Title level={1} className="article-title">
              {article.title}
            </Title>

            {article.excerpt && (
              <Paragraph className="article-excerpt">
                {article.excerpt}
              </Paragraph>
            )}
          </div>

          <div className="article-body">
            {article.content.split('\n').map((paragraph, index) => {
              if (paragraph.trim() === '') return null;
              
              return (
                <Paragraph key={index} className="article-paragraph">
                  {paragraph}
                </Paragraph>
              );
            })}
          </div>

          <Divider />

          <div className="article-actions">
            <div className="like-section">
              <Button
                type={liked ? "primary" : "default"}
                icon={liked ? <HeartFilled /> : <HeartOutlined />}
                onClick={handleLike}
                className="like-button"
              >
                {article.likesCount} {liked ? 'Нравится' : 'Нравится'}
              </Button>
            </div>

            <div className="share-section">
              <Text type="secondary">Понравилась статья? Поделитесь с друзьями!</Text>
            </div>
          </div>
        </Card>

        {/* Карточка автора */}
        <Card className="author-card">
          <div className="author-card-content">
            <Avatar
              src={article.avatarUrl}
              icon={<UserOutlined />}
              size={80}
            />
            <div className="author-card-info">
              <Title level={4}>
                {article.firstName} {article.lastName}
              </Title>
              <Text type="secondary">
                Автор статьи
              </Text>
              <div className="author-actions">
                <Button type="primary" size="small">
                  Посмотреть профиль
                </Button>
                <Button size="small">
                  Написать сообщение
                </Button>
              </div>
            </div>
          </div>
        </Card>
      </article>
    </div>
  );
};

export default ArticlePage;
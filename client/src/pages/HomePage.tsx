import React, { useState, useEffect } from 'react';
import { Card, Button, Typography, Spin, Empty } from 'antd';
import { useNavigate } from 'react-router-dom';
import {
  TeamOutlined,
  FileTextOutlined,
  SearchOutlined,
  EyeOutlined,
  HeartOutlined
} from '@ant-design/icons';
import { articlesAPI } from '../services/api';
import type { Article } from '../types/article';
import './HomePage.css';

const { Title, Paragraph, Text } = Typography;

const HomePage: React.FC = () => {
  const navigate = useNavigate();
  const [articles, setArticles] = useState<Article[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab] = useState('new');

  useEffect(() => {
    loadArticles(activeTab);
  }, [activeTab]);

  const loadArticles = async (sort: string) => {
    try {
      setLoading(true);
      const response = await articlesAPI.getAll({
        page: 1,
        limit: 6,
        sort: sort as 'new' | 'popular'
      });
      setArticles(response.articles);
    } catch (error) {
      console.error('Spiritual Platform: Ошибка загрузки статей:', error);
      // Устанавливаем демо-статьи для показа макета
      const demoArticles: Article[] = [
        {
          id: 1,
          title: 'Введение в Таро: основы для начинающих',
          content: 'Таро — это древняя система гадания...',
          excerpt: 'Узнайте основы работы с картами Таро',
          coverImage: '',
          viewsCount: 1250,
          likesCount: 89,
          isPublished: true,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
          firstName: 'Анна',
          lastName: 'Смирнова',
          avatarUrl: ''
        },
        {
          id: 2,
          title: 'Медитация для снятия стресса',
          content: 'Простые техники медитации...',
          excerpt: 'Эффективные практики для релаксации',
          coverImage: '',
          viewsCount: 890,
          likesCount: 67,
          isPublished: true,
          createdAt: new Date(Date.now() - 86400000).toISOString(),
          updatedAt: new Date(Date.now() - 86400000).toISOString(),
          firstName: 'Михаил',
          lastName: 'Петров',
          avatarUrl: ''
        }
      ];
      setArticles(demoArticles);
    } finally {
      setLoading(false);
    }
  };


  const truncateText = (text: string, maxLength: number) => {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + '...';
  };

  return (
    <div className="home-page">
      {/* Dribbble Style Bento Grid */}
      <div className="bento-grid">
        {/* Hero Section - Большая слева */}
        <Card className="bento-card hero-card">
          <div className="hero-content">
            <Title level={1} className="hero-title">
              Откройте мир
              <br />
              <span className="hero-highlight">духовных практик</span>
            </Title>
            <Paragraph className="hero-description">
              Изучите работы самых талантливых и опытных
              <br />
              духовных практиков, готовых взяться за ваш проект.
            </Paragraph>
            <div className="hero-actions">
              <Button
                type="primary"
                size="large"
                icon={<SearchOutlined />}
                onClick={() => navigate('/experts')}
                className="hero-button"
              >
                Найти эксперта
              </Button>
              <Button
                size="large"
                icon={<FileTextOutlined />}
                onClick={() => navigate('/articles')}
                className="hero-button secondary"
              >
                Читать статьи
              </Button>
            </div>
          </div>
        </Card>

        {/* Popular Categories - Как на скриншоте */}
        <Card className="bento-card categories-card-main">
          <div className="section-header">
            <Title level={4}>Популярные категории</Title>
          </div>
          <div className="categories-list-main">
            <span className="category-tag-main">Медитация</span>
            <span className="category-tag-main">Астрология</span>
            <span className="category-tag-main">Таро</span>
            <span className="category-tag-main">Йога</span>
            <span className="category-tag-main">Рейки</span>
            <span className="category-tag-main">Нумерология</span>
            <span className="category-tag-main">Холотропное дыхание</span>
            <span className="category-tag-main">Регрессия</span>
            <span className="category-tag-main">Парапсихология</span>
            <span className="category-tag-main">Расстановки</span>
          </div>
        </Card>

        {/* Features Cards - Разные размеры */}
        <Card className="bento-card feature-card">
          <div className="feature-icon">
            <TeamOutlined />
          </div>
          <Title level={4}>Проверенные эксперты</Title>
          <Paragraph>Все мастера проходят тщательную проверку</Paragraph>
        </Card>

        <Card className="bento-card feature-card">
          <div className="feature-icon">
            <FileTextOutlined />
          </div>
          <Title level={4}>Качественные материалы</Title>
          <Paragraph>Изучайте практики через экспертные статьи</Paragraph>
        </Card>

        <Card className="bento-card feature-card">
          <div className="feature-icon">
            <SearchOutlined />
          </div>
          <Title level={4}>Удобный поиск</Title>
          <Paragraph>Фильтры по тематикам и городам</Paragraph>
        </Card>

        {/* Популярные категории */}
        <Card className="bento-card categories-card">
          <div className="section-header">
            <Title level={4}>Популярные категории</Title>
          </div>
          <div className="categories-list">
            <span className="category-tag">Медитация</span>
            <span className="category-tag">Астрология</span>
            <span className="category-tag">Таро</span>
            <span className="category-tag">Йога</span>
            <span className="category-tag">Рейки</span>
            <span className="category-tag">Нумерология</span>
          </div>
        </Card>

        {/* Избранные статьи */}
        <Card className="bento-card articles-card">
          <div className="section-header">
            <Title level={4}>Избранные статьи</Title>
            <Button
              type="link"
              onClick={() => navigate('/articles')}
              className="view-all-button"
            >
              Все статьи
            </Button>
          </div>

          {loading ? (
            <div className="loading-container">
              <Spin size="large" />
            </div>
          ) : articles.length === 0 ? (
            <Empty description="Пока нет статей" />
          ) : (
            <div className="featured-articles">
              {articles.slice(0, 2).map((article) => (
                <div
                  key={article.id}
                  className="featured-article"
                  onClick={() => navigate(`/articles/${article.id}`)}
                >
                  <div className="article-cover">
                    {article.coverImage ? (
                      <img
                        src={article.coverImage}
                        alt={article.title}
                        onError={(e) => {
                          e.currentTarget.style.display = 'none';
                        }}
                      />
                    ) : (
                      <div className="article-cover-placeholder">
                        <FileTextOutlined />
                      </div>
                    )}
                  </div>
                  <div className="article-info">
                    <Title level={5} className="article-title">
                      {truncateText(article.title, 35)}
                    </Title>
                    <Text className="article-excerpt">
                      {truncateText(article.excerpt || '', 60)}
                    </Text>
                    <div className="article-meta">
                      <Text className="article-author">
                        {article.firstName} {article.lastName}
                      </Text>
                      <div className="article-stats">
                        <span className="stat-item">
                          <EyeOutlined />
                          {article.viewsCount}
                        </span>
                        <span className="stat-item">
                          <HeartOutlined />
                          {article.likesCount}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </Card>

        {/* CTA Card */}
        <Card className="bento-card cta-card">
          <div className="cta-content">
            <div className="cta-icon">
              <SearchOutlined />
            </div>
            <Title level={3}>Готовы начать?</Title>
            <Paragraph>
              Расскажите, что вам нужно, и мгновенно получите подбор
              квалифицированных духовных практиков, готовых работать над вашим проектом.
            </Paragraph>
            <Button
              type="primary"
              size="large"
              onClick={() => navigate('/experts')}
              className="cta-button"
            >
              Найти эксперта
            </Button>
          </div>
        </Card>
      </div>
    </div>
  );
};

export default HomePage;

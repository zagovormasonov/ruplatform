import React, { useState, useEffect } from 'react';
import { Card, Button, Typography, Tabs, Spin, Empty } from 'antd';
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
  const [activeTab, setActiveTab] = useState('new');

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
      {/* Bento Grid */}
      <div className="bento-grid">
        {/* Hero Section - Большая карточка */}
        <Card className="bento-card hero-card">
          <div className="hero-content">
            <Title level={1} className="hero-title">
              Духовные практики
            </Title>
            <Paragraph className="hero-description">
              Найдите своего наставника
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
                Статьи
              </Button>
            </div>
          </div>
        </Card>

        {/* Features - Разные размеры */}
        <Card className="bento-card feature-card large">
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

        {/* Articles - Bento стиль */}
        <Card className="bento-card articles-card">
          <div className="section-header">
            <Title level={4}>Последние статьи</Title>
            <Button
              type="link"
              onClick={() => navigate('/articles')}
              className="view-all-button"
            >
              Все
            </Button>
          </div>

          <Tabs
            activeKey={activeTab}
            onChange={setActiveTab}
            className="articles-tabs"
            items={[
              {
                key: 'new',
                label: 'Новые',
              },
              {
                key: 'popular',
                label: 'Популярные',
              },
            ]}
          />

          {loading ? (
            <div className="loading-container">
              <Spin size="large" />
            </div>
          ) : articles.length === 0 ? (
            <Empty description="Пока нет статей" />
          ) : (
            <div className="articles-grid">
              {articles.slice(0, 4).map((article, index) => (
                <Card
                  key={article.id}
                  className={`article-card ${index === 0 ? 'featured' : ''}`}
                  hoverable
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
                  <div className="article-content">
                    <Title level={5} className="article-title">
                      {truncateText(article.title, index === 0 ? 40 : 30)}
                    </Title>
                    <Text className="article-excerpt">
                      {truncateText(article.excerpt || '', 80)}
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
                </Card>
              ))}
            </div>
          )}
        </Card>

        {/* CTA - Большая карточка */}
        <Card className="bento-card cta-card">
          <div className="cta-content">
            <Title level={3}>Начните свой путь</Title>
            <Paragraph>
              Присоединяйтесь к сообществу духовных практик
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

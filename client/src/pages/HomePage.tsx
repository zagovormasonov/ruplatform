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
        {/* Hero Section - Dribbble Style */}
        <Card className="bento-card hero-card-modern">
          <div className="hero-content-modern">
            <div className="hero-text-modern">
              <Title level={1} className="hero-title-modern">
                Откройте мир
                <br />
                <span className="hero-highlight-modern">духовных практик</span>
              </Title>
              <Paragraph className="hero-description-modern">
                Изучите работы самых талантливых и опытных
                <br />
                духовных практиков, готовых взяться за ваш проект.
              </Paragraph>
            </div>
            <div className="hero-actions-modern">
              <Button
                type="primary"
                size="large"
                icon={<SearchOutlined />}
                onClick={() => navigate('/experts')}
                className="hero-button-modern primary"
              >
                Найти эксперта
              </Button>
              <Button
                size="large"
                icon={<FileTextOutlined />}
                onClick={() => navigate('/articles')}
                className="hero-button-modern secondary"
              >
                Читать статьи
              </Button>
            </div>
          </div>
        </Card>

              {/* Nature Image Card */}
              <Card className="bento-card nature-card">
                <div className="nature-image-container">
                  <img
                    src="https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=600&fit=crop&crop=center"
                    alt="Природа - медитация"
                    className="nature-image"
                    onError={(e) => {
                      e.currentTarget.style.display = 'none';
                    }}
                  />
                  <div className="nature-overlay">
                    <Text className="nature-quote">«Природа - лучший учитель мудрости»</Text>
                  </div>
                </div>
              </Card>

        {/* Features Cards - Упрощенные */}
        <Card className="bento-card feature-card">
          <div className="feature-icon">
            <TeamOutlined />
          </div>
          <Title level={4}>Проверенные эксперты</Title>
        </Card>

        <Card className="bento-card feature-card">
          <div className="feature-icon">
            <FileTextOutlined />
          </div>
          <Title level={4}>Качественные материалы</Title>
        </Card>

        <Card className="bento-card feature-card">
          <div className="feature-icon">
            <SearchOutlined />
          </div>
          <Title level={4}>Удобный поиск</Title>
        </Card>

        {/* Избранные статьи - растянуты на всю ширину */}
        <Card className="bento-card articles-card-full">
          <div className="section-header">
            <Title level={4}>Избранные статьи</Title>
            <Button
              type="link"
              onClick={() => navigate('/articles')}
              className="view-all-button"
            >
              Все статьи →
            </Button>
          </div>

          {loading ? (
            <div className="loading-container">
              <Spin size="large" />
            </div>
          ) : articles.length === 0 ? (
            <Empty description="Пока нет статей" />
          ) : (
            <div className="featured-articles-full">
              {articles.slice(0, 3).map((article, index) => (
                <div
                  key={article.id}
                  className={`featured-article-full ${index === 0 ? 'featured-large' : 'featured-medium'}`}
                  onClick={() => navigate(`/articles/${article.id}`)}
                >
                  <div className="article-cover-full">
                    {article.coverImage ? (
                      <img
                        src={article.coverImage}
                        alt={article.title}
                        className="article-image-full"
                        onError={(e) => {
                          e.currentTarget.style.display = 'none';
                        }}
                      />
                    ) : (
                      <div className="article-cover-placeholder-full">
                        <FileTextOutlined />
                      </div>
                    )}
                  </div>
                  <div className="article-info-full">
                    <Title level={index === 0 ? 3 : 4} className="article-title-full">
                      {truncateText(article.title, index === 0 ? 50 : 35)}
                    </Title>
                    {index === 0 && (
                      <Text className="article-excerpt-full">
                        {truncateText(article.excerpt || '', 120)}
                      </Text>
                    )}
                    <div className="article-meta-full">
                      <Text className="article-author-full">
                        {article.firstName} {article.lastName}
                      </Text>
                      <div className="article-stats-full">
                        <span className="stat-item-full">
                          <EyeOutlined />
                          {article.viewsCount}
                        </span>
                        <span className="stat-item-full">
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

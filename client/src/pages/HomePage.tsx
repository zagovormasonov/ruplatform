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
              Discover Spiritual
              <br />
              <span className="hero-highlight">Masters</span>
            </Title>
            <Paragraph className="hero-description">
              Explore work from the most talented and accomplished
              <br />
              spiritual practitioners ready to take on your next project.
            </Paragraph>
            <div className="hero-actions">
              <Button
                type="primary"
                size="large"
                icon={<SearchOutlined />}
                onClick={() => navigate('/experts')}
                className="hero-button"
              >
                Find Expert
              </Button>
              <Button
                size="large"
                icon={<FileTextOutlined />}
                onClick={() => navigate('/articles')}
                className="hero-button secondary"
              >
                Read Articles
              </Button>
            </div>
          </div>
        </Card>

        {/* Statistics Card - Большая справа */}
        <Card className="bento-card stats-card">
          <div className="stats-header">
            <Title level={4}>Platform Statistics</Title>
          </div>
          <div className="stats-grid">
            <div className="stat-item">
              <div className="stat-number">1,765</div>
              <div className="stat-label">Active Experts</div>
            </div>
            <div className="stat-item">
              <div className="stat-number">437</div>
              <div className="stat-label">Success Stories</div>
            </div>
          </div>
          <div className="stats-chart">
            <div className="chart-placeholder">
              <div className="chart-line"></div>
              <div className="chart-dots">
                <div className="dot"></div>
                <div className="dot"></div>
                <div className="dot"></div>
              </div>
            </div>
          </div>
        </Card>

        {/* Features Cards - Разные размеры */}
        <Card className="bento-card feature-card">
          <div className="feature-icon">
            <TeamOutlined />
          </div>
          <Title level={4}>Verified Experts</Title>
          <Paragraph>All masters undergo thorough verification</Paragraph>
        </Card>

        <Card className="bento-card feature-card">
          <div className="feature-icon">
            <FileTextOutlined />
          </div>
          <Title level={4}>Quality Content</Title>
          <Paragraph>Learn practices through expert articles</Paragraph>
        </Card>

        <Card className="bento-card feature-card">
          <div className="feature-icon">
            <SearchOutlined />
          </div>
          <Title level={4}>Smart Search</Title>
          <Paragraph>Filters by topics and locations</Paragraph>
        </Card>

        {/* Popular Categories */}
        <Card className="bento-card categories-card">
          <div className="section-header">
            <Title level={4}>Popular Categories</Title>
          </div>
          <div className="categories-list">
            <span className="category-tag">Meditation</span>
            <span className="category-tag">Astrology</span>
            <span className="category-tag">Tarot</span>
            <span className="category-tag">Yoga</span>
            <span className="category-tag">Reiki</span>
            <span className="category-tag">Numerology</span>
          </div>
        </Card>

        {/* Featured Articles */}
        <Card className="bento-card articles-card">
          <div className="section-header">
            <Title level={4}>Featured Articles</Title>
            <Button
              type="link"
              onClick={() => navigate('/articles')}
              className="view-all-button"
            >
              View All
            </Button>
          </div>

          {loading ? (
            <div className="loading-container">
              <Spin size="large" />
            </div>
          ) : articles.length === 0 ? (
            <Empty description="No articles yet" />
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
            <Title level={3}>Ready to Start?</Title>
            <Paragraph>
              Tell us what you need and instantly get matched with world-class
              spiritual practitioners ready to work on your project.
            </Paragraph>
            <Button
              type="primary"
              size="large"
              onClick={() => navigate('/experts')}
              className="cta-button"
            >
              Get Matched Now
            </Button>
          </div>
        </Card>
      </div>
    </div>
  );
};

export default HomePage;

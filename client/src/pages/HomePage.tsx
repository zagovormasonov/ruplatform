import React, { useState, useEffect } from 'react';
import { Row, Col, Card, Button, Typography, Tabs, Spin, Empty } from 'antd';
import { useNavigate } from 'react-router-dom';
import { 
  TeamOutlined, 
  FileTextOutlined, 
  SearchOutlined,
  EyeOutlined,
  HeartOutlined,
  ClockCircleOutlined
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

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('ru-RU', {
      day: 'numeric',
      month: 'long',
      year: 'numeric'
    });
  };

  const truncateText = (text: string, maxLength: number) => {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + '...';
  };

  return (
    <div className="home-page">
      {/* Hero Section */}
      <section className="hero-section">
        <div className="hero-content">
          <Title level={1} className="hero-title">
            Добро пожаловать в мир духовных практик
          </Title>
          <Paragraph className="hero-description">
            Найдите своего наставника среди проверенных экспертов в области 
            духовного развития, парапсихологии, астрологии и других практик
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
      </section>

      <div className="home-content">
        {/* Features Section */}
        <section className="features-section">
        <Row gutter={[24, 24]}>
          <Col xs={24} md={8}>
            <Card className="feature-card" variant="outlined">
              <div className="feature-icon">
                <TeamOutlined />
              </div>
              <Title level={4}>Проверенные эксперты</Title>
              <Paragraph>
                Все мастера проходят тщательную проверку. 
                Читайте отзывы и выбирайте лучших специалистов.
              </Paragraph>
            </Card>
          </Col>
          <Col xs={24} md={8}>
            <Card className="feature-card" variant="outlined">
              <div className="feature-icon">
                <FileTextOutlined />
              </div>
              <Title level={4}>Образовательные статьи</Title>
              <Paragraph>
                Изучайте различные духовные практики через 
                качественные материалы от экспертов.
              </Paragraph>
            </Card>
          </Col>
          <Col xs={24} md={8}>
            <Card className="feature-card" variant="outlined">
              <div className="feature-icon">
                <SearchOutlined />
              </div>
              <Title level={4}>Удобный поиск</Title>
              <Paragraph>
                Фильтруйте экспертов по тематикам, городу 
                и типу услуг для быстрого поиска подходящего специалиста.
              </Paragraph>
            </Card>
          </Col>
        </Row>
      </section>

      {/* Articles Section */}
      <section className="articles-section">
        <div className="section-header">
          <Title level={2}>Последние статьи</Title>
          <Button 
            type="link" 
            onClick={() => navigate('/articles')}
            className="view-all-button"
          >
            Смотреть все
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
          <Row gutter={[24, 24]}>
            {articles.map((article) => (
              <Col xs={24} sm={12} lg={8} key={article.id}>
                <Card 
                  className="article-card"
                  hoverable
                  cover={
                    article.coverImage ? (
                      <div className="article-cover">
                        <img 
                          src={article.coverImage} 
                          alt={article.title}
                          onError={(e) => {
                            e.currentTarget.style.display = 'none';
                          }}
                        />
                      </div>
                    ) : (
                      <div className="article-cover-placeholder">
                        <FileTextOutlined />
                      </div>
                    )
                  }
                  onClick={() => navigate(`/articles/${article.id}`)}
                >
                  <Card.Meta
                    title={
                      <Title level={5} className="article-title">
                        {truncateText(article.title, 60)}
                      </Title>
                    }
                    description={
                      <div className="article-meta">
                        <Paragraph className="article-excerpt">
                          {truncateText(article.excerpt || '', 100)}
                        </Paragraph>
                        <div className="article-info">
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
                            <span className="stat-item">
                              <ClockCircleOutlined />
                              {formatDate(article.createdAt)}
                            </span>
                          </div>
                        </div>
                      </div>
                    }
                  />
                </Card>
              </Col>
            ))}
          </Row>
        )}
      </section>

      {/* CTA Section */}
      <section className="cta-section">
        <Card className="cta-card">
          <div className="cta-content">
            <Title level={3}>Готовы начать свой путь?</Title>
            <Paragraph>
              Присоединяйтесь к нашему сообществу и найдите своего наставника 
              в мире духовных практик
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
      </section>
      </div>
    </div>
  );
};

export default HomePage;

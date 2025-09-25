import React, { useState, useEffect } from 'react';
import { Card, Button, Typography, Spin, Input, Row, Col, Tabs, Avatar, Rate } from 'antd';
import { useNavigate } from 'react-router-dom';
import {
  SearchOutlined,
  UserOutlined,
  EnvironmentOutlined,
  FileTextOutlined,
  EyeOutlined,
  HeartOutlined,
  MessageOutlined
} from '@ant-design/icons';
import { expertsAPI, articlesAPI } from '../services/api';
import type { Expert } from '../types/index';
import type { Article } from '../types/article';
import './HomePageNew.css';

const { Title, Paragraph, Text } = Typography;
const { Search } = Input;
const { TabPane } = Tabs;

const HomePage: React.FC = () => {
  const navigate = useNavigate();
  const [experts, setExperts] = useState<Expert[]>([]);
  const [articles, setArticles] = useState<Article[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchValue, setSearchValue] = useState('');
  const [activeTab, setActiveTab] = useState('new');

  useEffect(() => {
    loadExperts();
    loadArticles(activeTab);
  }, [activeTab]);

  const loadExperts = async () => {
    try {
      const response = await expertsAPI.search({
        page: 1,
        limit: 3,
        sortBy: 'rating'
      });
      setExperts(response.experts);
    } catch (error) {
      console.error('Spiritual Platform: Ошибка загрузки экспертов:', error);
      // Устанавливаем демо-экспертов
      const demoExperts: Expert[] = [
        {
          id: 1,
          userId: 1,
          firstName: 'Анна',
          lastName: 'Светлова',
          avatarUrl: '',
          bio: 'Практикующий астролог и таролог с 15-летним опытом',
          rating: 4.9,
          reviewsCount: 127,
          cityName: 'Москва',
          region: 'Москва',
          topics: ['Таро', 'Астрология', 'Медитация'],
          services: [],
          reviews: []
        },
        {
          id: 2,
          userId: 2,
          firstName: 'Михаил',
          lastName: 'Энергетик',
          avatarUrl: '',
          bio: 'Мастер энергетических практик и целительства',
          rating: 4.8,
          reviewsCount: 89,
          cityName: 'Санкт-Петербург',
          region: 'Санкт-Петербург',
          topics: ['Рейки', 'Космоэнергетика', 'Целительство'],
          services: [],
          reviews: []
        },
        {
          id: 3,
          userId: 3,
          firstName: 'Елена',
          lastName: 'Мудрая',
          avatarUrl: '',
          bio: 'Специалист по древним славянским практикам',
          rating: 4.7,
          reviewsCount: 156,
          cityName: 'Екатеринбург',
          region: 'Свердловская область',
          topics: ['Нумерология', 'Руны', 'Славянские практики'],
          services: [],
          reviews: []
        }
      ];
      setExperts(demoExperts);
    }
  };

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
      // Устанавливаем демо-статьи
      const demoArticles: Article[] = [
        {
          id: 1,
          title: 'Тайны рунической магии',
          content: 'Руны — это древняя система...',
          excerpt: 'Погрузитесь в мир древней рунической магии',
          coverImage: '',
          viewsCount: 2150,
          likesCount: 189,
          isPublished: true,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
          firstName: 'Елена',
          lastName: 'Мудрая',
          avatarUrl: ''
        },
        {
          id: 2,
          title: 'Основы медитации для начинающих',
          content: 'Медитация помогает обрести гармонию...',
          excerpt: 'Простые техники медитации для ежедневной практики',
          coverImage: '',
          viewsCount: 1890,
          likesCount: 167,
          isPublished: true,
          createdAt: new Date(Date.now() - 86400000).toISOString(),
          updatedAt: new Date(Date.now() - 86400000).toISOString(),
          firstName: 'Анна',
          lastName: 'Светлова',
          avatarUrl: ''
        }
      ];
      setArticles(demoArticles);
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = (value: string) => {
    setSearchValue(value);
    if (value.trim()) {
      navigate(`/experts?search=${encodeURIComponent(value.trim())}`);
    }
  };

  const truncateText = (text: string, maxLength: number) => {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + '...';
  };

  return (
    <div className="home-page-new">
      {/* Hero Section с градиентным фоном */}
      <div className="hero-section">
        <div className="hero-content">
          <Title level={1} className="hero-title">
            Найдите своего духовного наставника
          </Title>
          <Paragraph className="hero-subtitle">
            Платформа для поиска и взаимодействия с проверенными мастерами духовных практик
          </Paragraph>

          {/* Большая поисковая строка */}
          <div className="search-container">
            <Search
              placeholder="Поиск по экспертам или практикам..."
              enterButton={
                <Button type="primary" icon={<SearchOutlined />} size="large">
                  Найти
                </Button>
              }
              size="large"
              value={searchValue}
              onChange={(e) => setSearchValue(e.target.value)}
              onSearch={handleSearch}
              className="main-search"
            />
          </div>
        </div>
      </div>

      {/* Рекомендуемые эксперты */}
      <div className="recommended-experts-section">
        <div className="container">
          <Title level={2} className="section-title">Рекомендуемые эксперты</Title>
          <Row gutter={[24, 24]}>
            {experts.map((expert) => (
              <Col xs={24} sm={12} lg={8} key={expert.id}>
                <Card
                  hoverable
                  className="expert-card"
                  cover={
                    <div className="expert-avatar-container">
                      <Avatar
                        size={120}
                        src={expert.avatarUrl}
                        icon={<UserOutlined />}
                        className="expert-avatar"
                      />
                    </div>
                  }
                >
                  <div className="expert-info">
                    <Title level={4} className="expert-name">
                      {expert.firstName} {expert.lastName}
                    </Title>

                    <div className="expert-location">
                      <EnvironmentOutlined />
                      <Text>{expert.cityName}</Text>
                    </div>

                    <div className="expert-rating">
                      <Rate disabled value={expert.rating} />
                      <Text className="rating-text">
                        {expert.rating} ({expert.reviewsCount} отзывов)
                      </Text>
                    </div>

                    <div className="expert-topics">
                      {expert.topics.slice(0, 3).map((topic, index) => (
                        <span key={index} className="topic-tag">
                          {topic}
                        </span>
                      ))}
                    </div>

                    <div className="expert-actions">
                      <Button
                        type="primary"
                        block
                        icon={<MessageOutlined />}
                        onClick={() => navigate(`/experts/${expert.id}`)}
                        className="contact-button"
                      >
                        Посмотреть профиль
                      </Button>
                    </div>
                  </div>
                </Card>
              </Col>
            ))}
          </Row>
        </div>
      </div>

      {/* Статьи и материалы */}
      <div className="articles-section">
        <div className="container">
          <Title level={2} className="section-title">Статьи и материалы</Title>

          <Tabs
            activeKey={activeTab}
            onChange={setActiveTab}
            className="articles-tabs"
          >
            <TabPane tab="Новые статьи" key="new">
              {loading ? (
                <div className="loading-container">
                  <Spin size="large" />
                </div>
              ) : (
                <Row gutter={[24, 24]}>
                  {articles.slice(0, 3).map((article) => (
                    <Col xs={24} sm={12} lg={8} key={article.id}>
                      <Card
                        hoverable
                        className="article-card"
                        cover={
                          <div className="article-cover">
                            {article.coverImage ? (
                              <img src={article.coverImage} alt={article.title} />
                            ) : (
                              <div className="article-cover-placeholder">
                                <FileTextOutlined />
                              </div>
                            )}
                          </div>
                        }
                      >
                        <div className="article-info">
                          <Title level={5} className="article-title">
                            {article.title}
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
                    </Col>
                  ))}
                </Row>
              )}
            </TabPane>

            <TabPane tab="Популярные" key="popular">
              {loading ? (
                <div className="loading-container">
                  <Spin size="large" />
                </div>
              ) : (
                <Row gutter={[24, 24]}>
                  {articles.slice(0, 3).map((article) => (
                    <Col xs={24} sm={12} lg={8} key={article.id}>
                      <Card
                        hoverable
                        className="article-card"
                        cover={
                          <div className="article-cover">
                            {article.coverImage ? (
                              <img src={article.coverImage} alt={article.title} />
                            ) : (
                              <div className="article-cover-placeholder">
                                <FileTextOutlined />
                              </div>
                            )}
                          </div>
                        }
                      >
                        <div className="article-info">
                          <Title level={5} className="article-title">
                            {article.title}
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
                    </Col>
                  ))}
                </Row>
              )}
            </TabPane>
          </Tabs>
        </div>
      </div>
    </div>
  );
};

export default HomePage;

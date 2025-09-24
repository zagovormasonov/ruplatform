import React, { useState, useEffect } from 'react';
import {
  Row,
  Col,
  Card,
  Typography,
  Button,
  Tabs,
  Spin,
  Empty,
  Pagination,
  Input,
  Avatar
} from 'antd';
import { useNavigate } from 'react-router-dom';
import {
  FileTextOutlined,
  EyeOutlined,
  HeartOutlined,
  ClockCircleOutlined,
  UserOutlined,
  SearchOutlined,
  PlusOutlined
} from '@ant-design/icons';
import { articlesAPI } from '../services/api';
import { useAuth } from '../contexts/AuthContext';
import type { Article } from '../types/article';
import './ArticlesPage.css';

const { Title, Text, Paragraph } = Typography;
const { Search } = Input;

const ArticlesPage: React.FC = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  
  const [articles, setArticles] = useState<Article[]>([]);
  const [loading, setLoading] = useState(false);
  const [activeTab, setActiveTab] = useState('new');
  const [searchQuery, setSearchQuery] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [totalArticles, setTotalArticles] = useState(0);
  
  const pageSize = 12;

  useEffect(() => {
    loadArticles();
  }, [activeTab, currentPage, searchQuery]);

  const loadArticles = async () => {
    try {
      setLoading(true);
      const response = await articlesAPI.getAll({
        page: currentPage,
        limit: pageSize,
        sort: activeTab as 'new' | 'popular'
      });
      
      let filteredArticles = response.articles;
      if (searchQuery) {
        filteredArticles = response.articles.filter(article =>
          article.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
          article.excerpt?.toLowerCase().includes(searchQuery.toLowerCase())
        );
      }
      
      setArticles(filteredArticles);
      setTotalArticles(response.pagination.total);
    } catch (error) {
      console.error('Spiritual Platform: Ошибка загрузки статей:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleTabChange = (key: string) => {
    setActiveTab(key);
    setCurrentPage(1);
  };

  const handleSearch = (value: string) => {
    setSearchQuery(value);
    setCurrentPage(1);
  };

  const handleArticleClick = (articleId: number) => {
    navigate(`/articles/${articleId}`);
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
    <div className="articles-page">
      <div className="articles-header">
        <div className="header-content">
          <div className="header-text">
            <Title level={2}>Статьи и материалы</Title>
            <Paragraph>
              Изучайте духовные практики через качественные материалы от экспертов
            </Paragraph>
          </div>
          {user && (
            <Button
              type="primary"
              size="large"
              icon={<PlusOutlined />}
              onClick={() => navigate('/create-article')}
              className="create-article-btn"
            >
              Написать статью
            </Button>
          )}
        </div>
      </div>

      <div className="articles-filters">
        <Row gutter={[16, 16]} align="middle">
          <Col xs={24} sm={12}>
            <Tabs
              activeKey={activeTab}
              onChange={handleTabChange}
              items={[
                {
                  key: 'new',
                  label: 'Новые статьи',
                },
                {
                  key: 'popular',
                  label: 'Популярные',
                },
              ]}
            />
          </Col>
          <Col xs={24} sm={12}>
            <Search
              placeholder="Поиск статей..."
              allowClear
              onSearch={handleSearch}
              style={{ width: '100%' }}
              enterButton={<SearchOutlined />}
            />
          </Col>
        </Row>
      </div>

      <div className="articles-content">
        {loading ? (
          <div className="loading-container">
            <Spin size="large" />
          </div>
        ) : articles.length === 0 ? (
          <Empty
            description={searchQuery ? "Статьи по запросу не найдены" : "Пока нет статей"}
            image={Empty.PRESENTED_IMAGE_SIMPLE}
          />
        ) : (
          <>
            <Row gutter={[24, 24]}>
              {articles.map(article => (
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
                    onClick={() => handleArticleClick(article.id)}
                  >
                    <div className="article-meta">
                      <div className="article-author">
                        <Avatar
                          size="small"
                          src={article.avatarUrl}
                          icon={<UserOutlined />}
                        />
                        <Text className="author-name">
                          {article.firstName} {article.lastName}
                        </Text>
                      </div>
                      <Text className="article-date">
                        {formatDate(article.createdAt)}
                      </Text>
                    </div>

                    <Title level={5} className="article-title">
                      {truncateText(article.title, 60)}
                    </Title>

                    {article.excerpt && (
                      <Paragraph className="article-excerpt">
                        {truncateText(article.excerpt, 120)}
                      </Paragraph>
                    )}

                    <div className="article-stats">
                      <div className="stat-item">
                        <EyeOutlined />
                        <Text>{article.viewsCount}</Text>
                      </div>
                      <div className="stat-item">
                        <HeartOutlined />
                        <Text>{article.likesCount}</Text>
                      </div>
                      <div className="stat-item">
                        <ClockCircleOutlined />
                        <Text>5 мин чтения</Text>
                      </div>
                    </div>
                  </Card>
                </Col>
              ))}
            </Row>

            {totalArticles > pageSize && (
              <div className="pagination-container">
                <Pagination
                  current={currentPage}
                  pageSize={pageSize}
                  total={totalArticles}
                  onChange={setCurrentPage}
                  showSizeChanger={false}
                  showQuickJumper
                  showTotal={(total, range) =>
                    `${range[0]}-${range[1]} из ${total} статей`
                  }
                />
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
};

export default ArticlesPage;
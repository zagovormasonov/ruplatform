import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Row,
  Col,
  Card,
  Typography,
  Button,
  Tabs,
  Space,
  Statistic,
  List
} from 'antd';
import {
  PlusOutlined,
  StarOutlined,
  MessageOutlined,
  DollarOutlined,
  FileTextOutlined
} from '@ant-design/icons';
import { expertsAPI, articlesAPI } from '../services/api';
import { useAuth } from '../contexts/AuthContext';
import type { Expert, Service, Article } from '../types/index';
import './ExpertDashboardPage.css';

const { Title } = Typography;

const ExpertDashboardPage: React.FC = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  
  const [expert, setExpert] = useState<Expert | null>(null);
  const [services, setServices] = useState<Service[]>([]);
  const [articles, setArticles] = useState<Article[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user || user.role !== 'expert') {
      navigate('/');
      return;
    }

    loadDashboardData();
  }, [user, navigate]);

  const loadDashboardData = async () => {
    try {
      setLoading(true);
      const [expertData, servicesData, articlesData] = await Promise.all([
        expertsAPI.getMyProfile(),
        expertsAPI.getMyServices(),
        articlesAPI.getMy({ page: 1, limit: 10 })
      ]);

      setExpert(expertData);
      setServices(servicesData);
      setArticles(articlesData.articles);
    } catch (error) {
      console.error('Spiritual Platform: Ошибка загрузки данных панели:', error);
    } finally {
      setLoading(false);
    }
  };

  if (!user || user.role !== 'expert') {
    return null;
  }

  return (
    <div className="expert-dashboard">
      <div className="dashboard-header">
        <Title level={2}>Панель эксперта</Title>
        <Space>
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={() => navigate('/create-article')}
          >
            Создать статью
          </Button>
        </Space>
      </div>

      <Row gutter={[16, 16]} className="stats-row">
        <Col xs={12} sm={6}>
          <Card>
            <Statistic
              title="Рейтинг"
              value={Number(expert?.rating) || 0}
              precision={1}
              valueStyle={{ color: '#6366f1' }}
              prefix={<StarOutlined />}
            />
          </Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card>
            <Statistic
              title="Отзывы"
              value={expert?.reviewsCount || 0}
              valueStyle={{ color: '#52c41a' }}
              prefix={<MessageOutlined />}
            />
          </Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card>
            <Statistic
              title="Услуги"
              value={services.length}
              valueStyle={{ color: '#1890ff' }}
              prefix={<DollarOutlined />}
            />
          </Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card>
            <Statistic
              title="Статьи"
              value={articles.length}
              valueStyle={{ color: '#722ed1' }}
              prefix={<FileTextOutlined />}
            />
          </Card>
        </Col>
      </Row>

      <Card className="main-content">
        <Tabs
          items={[
            {
              key: 'services',
              label: 'Мои услуги',
              children: (
                <div className="services-tab">
                  <p>Управление услугами будет добавлено в следующих обновлениях</p>
                </div>
              )
            },
            {
              key: 'articles',
              label: 'Мои статьи',
              children: (
                <div className="articles-tab">
                  <List
                    dataSource={articles}
                    loading={loading}
                    locale={{ emptyText: 'У вас пока нет статей' }}
                    renderItem={(article) => (
                      <List.Item>
                        <List.Item.Meta
                          title={article.title}
                          description={article.excerpt}
                        />
                      </List.Item>
                    )}
                  />
                </div>
              )
            }
          ]}
        />
      </Card>
    </div>
  );
};

export default ExpertDashboardPage;
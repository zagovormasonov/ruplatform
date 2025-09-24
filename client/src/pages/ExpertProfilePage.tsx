import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  Row,
  Col,
  Card,
  Avatar,
  Typography,
  Button,
  Tag,
  Rate,
  Divider,
  List,
  Spin,
  message,
  Modal
} from 'antd';
import {
  UserOutlined,
  MessageOutlined,
  EnvironmentOutlined,
  ClockCircleOutlined,
  CheckCircleOutlined,
  GlobalOutlined,
  HomeOutlined
} from '@ant-design/icons';
import { expertsAPI, chatsAPI } from '../services/api';
import { useAuth } from '../contexts/AuthContext';
import type { Expert, Service, Review } from '../types/index';
import './ExpertProfilePage.css';

const { Title, Text, Paragraph } = Typography;

const ExpertProfilePage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user } = useAuth();
  
  const [expert, setExpert] = useState<Expert | null>(null);
  const [loading, setLoading] = useState(true);
  const [contactLoading, setContactLoading] = useState(false);

  useEffect(() => {
    if (id) {
      loadExpert(id);
    }
  }, [id]);

  const loadExpert = async (expertId: string) => {
    try {
      setLoading(true);
      const data = await expertsAPI.getById(expertId);
      setExpert(data);
    } catch (error) {
      console.error('Spiritual Platform: Ошибка загрузки эксперта:', error);
      message.error('Эксперт не найден');
      navigate('/experts');
    } finally {
      setLoading(false);
    }
  };

  const handleContact = async () => {
    if (!user) {
      Modal.confirm({
        title: 'Требуется авторизация',
        content: 'Для связи с экспертом необходимо войти в систему',
        okText: 'Войти',
        cancelText: 'Отмена',
        onOk: () => navigate('/login')
      });
      return;
    }

    if (!expert) return;

    try {
      setContactLoading(true);
      const chatData = await chatsAPI.start(expert.id);
      navigate(`/chat/${chatData.chatId}`);
    } catch (error) {
      console.error('Spiritual Platform: Ошибка создания чата:', error);
      message.error('Не удалось связаться с экспертом');
    } finally {
      setContactLoading(false);
    }
  };

  const formatServiceType = (type: string) => {
    return type === 'online' ? 'Онлайн' : 'Офлайн';
  };

  const formatDuration = (minutes: number) => {
    if (minutes < 60) {
      return `${minutes} мин`;
    }
    const hours = Math.floor(minutes / 60);
    const remainingMinutes = minutes % 60;
    return remainingMinutes > 0 ? `${hours}ч ${remainingMinutes}м` : `${hours}ч`;
  };

  if (loading) {
    return (
      <div className="loading-container">
        <Spin size="large" />
      </div>
    );
  }

  if (!expert) {
    return null;
  }

  return (
    <div className="expert-profile-page">
      <Row gutter={[24, 24]}>
        {/* Основная информация */}
        <Col xs={24} lg={16}>
          <Card className="expert-main-card">
            <div className="expert-header">
              <Avatar
                size={120}
                src={expert.avatarUrl}
                icon={<UserOutlined />}
                className="expert-avatar"
              />
              <div className="expert-info">
                <Title level={2} className="expert-name">
                  {expert.firstName} {expert.lastName}
                </Title>
                
                <div className="expert-rating">
                  <Rate disabled value={Number(expert.rating) || 0} />
                  <Text className="rating-text">
                    {Number(expert.rating || 0).toFixed(1)} из 5 ({expert.reviewsCount || 0} отзывов)
                  </Text>
                </div>

                {expert.cityName && (
                  <div className="expert-location">
                    <EnvironmentOutlined />
                    <Text>{expert.cityName}, {expert.region}</Text>
                  </div>
                )}

                <div className="expert-actions">
                  <Button
                    type="primary"
                    size="large"
                    icon={<MessageOutlined />}
                    loading={contactLoading}
                    onClick={handleContact}
                  >
                    Связаться с экспертом
                  </Button>
                </div>
              </div>
            </div>

            {expert.bio && (
              <>
                <Divider />
                <div className="expert-bio">
                  <Title level={4}>О себе</Title>
                  <Paragraph>{expert.bio}</Paragraph>
                </div>
              </>
            )}

            {expert.topics && expert.topics.length > 0 && (
              <>
                <Divider />
                <div className="expert-topics">
                  <Title level={4}>Специализации</Title>
                  <div className="topics-list">
                    {expert.topics.map(topic => (
                      <Tag key={topic} color="blue" className="topic-tag">
                        {topic}
                      </Tag>
                    ))}
                  </div>
                </div>
              </>
            )}
          </Card>

          {/* Услуги */}
          {expert.services && expert.services.length > 0 && (
            <Card title="Услуги" className="services-card">
              <List
                dataSource={expert.services}
                renderItem={(service: Service) => (
                  <List.Item className="service-item">
                    <Card size="small" className="service-card">
                      <div className="service-header">
                        <Title level={5} className="service-title">
                          {service.title}
                        </Title>
                        <div className="service-price">
                          {service.price} ₽
                        </div>
                      </div>
                      
                      {service.description && (
                        <Paragraph className="service-description">
                          {service.description}
                        </Paragraph>
                      )}
                      
                      <div className="service-details">
                        <div className="service-detail">
                          <ClockCircleOutlined />
                          <Text>{formatDuration(service.durationMinutes)}</Text>
                        </div>
                        <div className="service-detail">
                          {service.serviceType === 'online' ? <GlobalOutlined /> : <HomeOutlined />}
                          <Text>{formatServiceType(service.serviceType)}</Text>
                        </div>
                        {service.isActive && (
                          <div className="service-detail">
                            <CheckCircleOutlined style={{ color: '#52c41a' }} />
                            <Text>Доступно</Text>
                          </div>
                        )}
                      </div>
                    </Card>
                  </List.Item>
                )}
              />
            </Card>
          )}

          {/* Отзывы */}
          {expert.reviews && expert.reviews.length > 0 && (
            <Card title="Отзывы" className="reviews-card">
              <List
                dataSource={expert.reviews}
                renderItem={(review: Review) => (
                  <List.Item>
                    <div className="review-item">
                      <div className="review-header">
                        <Avatar src={review.avatarUrl} icon={<UserOutlined />} />
                        <div className="review-author">
                          <Text strong>{review.firstName} {review.lastName}</Text>
                          <div className="review-meta">
                            <Rate disabled value={Number(review.rating) || 0} />
                            <Text className="review-date">
                              {new Date(review.createdAt).toLocaleDateString('ru-RU')}
                            </Text>
                          </div>
                        </div>
                      </div>
                      <div className="review-content">
                        <Text>{review.comment}</Text>
                      </div>
                    </div>
                  </List.Item>
                )}
              />
            </Card>
          )}
        </Col>

        {/* Боковая панель */}
        <Col xs={24} lg={8}>
          <Card title="Статистика" className="stats-card">
            <div className="stat-item">
              <div className="stat-value">{expert.reviewsCount}</div>
              <div className="stat-label">Отзывов</div>
            </div>
            <div className="stat-item">
              <div className="stat-value">{Number(expert.rating || 0).toFixed(1)}</div>
              <div className="stat-label">Рейтинг</div>
            </div>
            <div className="stat-item">
              <div className="stat-value">
                {expert.services ? expert.services.length : 0}
              </div>
              <div className="stat-label">Услуг</div>
            </div>
            <div className="stat-item">
              <div className="stat-value">{expert.topics.length}</div>
              <div className="stat-label">Специализаций</div>
            </div>
          </Card>

          {expert.services && expert.services.length > 0 && (
            <Card title="Ценовой диапазон" className="price-card">
              <div className="price-range">
                <div className="price-item">
                  <Text>От:</Text>
                  <Text strong className="price-value">
                    {(() => {
                      const validServices = expert.services.filter(s => s && typeof s.price === 'number');
                      return validServices.length > 0 ? Math.min(...validServices.map(s => s.price)) : 0;
                    })()} ₽
                  </Text>
                </div>
                <div className="price-item">
                  <Text>До:</Text>
                  <Text strong className="price-value">
                    {(() => {
                      const validServices = expert.services.filter(s => s && typeof s.price === 'number');
                      return validServices.length > 0 ? Math.max(...validServices.map(s => s.price)) : 0;
                    })()} ₽
                  </Text>
                </div>
              </div>
            </Card>
          )}

          <Card className="contact-card">
            <div className="contact-info">
              <Title level={5}>Готовы начать?</Title>
              <Paragraph>
                Свяжитесь с экспертом для записи на консультацию или задайте вопросы
              </Paragraph>
              <Button
                type="primary"
                block
                size="large"
                icon={<MessageOutlined />}
                loading={contactLoading}
                onClick={handleContact}
              >
                Написать эксперту
              </Button>
            </div>
          </Card>
        </Col>
      </Row>
    </div>
  );
};

export default ExpertProfilePage;
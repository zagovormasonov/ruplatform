import React, { useState, useEffect } from 'react';
import {
  Row,
  Col,
  Card,
  Input,
  Select,
  Button,
  Typography,
  Tag,
  Rate,
  Avatar,
  Spin,
  Empty,
  Pagination,
  Checkbox,
  message
} from 'antd';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { 
  UserOutlined, 
  EnvironmentOutlined,
  EyeOutlined,
  MessageOutlined
} from '@ant-design/icons';
import { expertsAPI, usersAPI, chatsAPI } from '../services/api';
import type { Expert, Topic, City } from '../types/index';
import './ExpertsPage.css';

const { Title, Text, Paragraph } = Typography;
const { Option } = Select;

const ExpertsPage: React.FC = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
const { Search } = Input;
  
  // Состояние данных
  const [experts, setExperts] = useState<Expert[]>([]);
  const [topics, setTopics] = useState<Topic[]>([]);
  const [cities, setCities] = useState<City[]>([]);
  const [loading, setLoading] = useState(false);
  const [contactLoading, setContactLoading] = useState(false);
  const [totalExperts, setTotalExperts] = useState(0);
  
  // Состояние фильтров
  const [selectedTopics, setSelectedTopics] = useState<string[]>([]);
  const [selectedCity, setSelectedCity] = useState<string>('');
  const [serviceType, setServiceType] = useState<string>('');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [sortBy, setSortBy] = useState<string>('rating');
  const [currentPage, setCurrentPage] = useState(1);
  
  const pageSize = 12;

  // Загрузка начальных данных
  useEffect(() => {
    loadInitialData();
  }, []);

  // Загрузка экспертов при изменении фильтров
  useEffect(() => {
    if (topics.length > 0) { // Загружаем экспертов только после загрузки тематик
      loadExperts();
    }
  }, [selectedTopics, selectedCity, serviceType, searchQuery, sortBy, currentPage, topics]);

  const loadInitialData = async () => {
    try {
      const [topicsRes, citiesRes] = await Promise.all([
        usersAPI.getTopics(),
        usersAPI.getCities()
      ]);
      setTopics(topicsRes || []);
      setCities(citiesRes || []);
    } catch (error) {
      console.error('Spiritual Platform: Ошибка загрузки данных:', error);
      // Устанавливаем fallback данные
      setTopics([
        { id: 1, name: 'Таро' },
        { id: 2, name: 'Астрология' },
        { id: 3, name: 'Нумерология' },
        { id: 4, name: 'Рейки' },
        { id: 5, name: 'Медитация' }
      ]);
      setCities([
        { id: 1, name: 'Москва', region: 'Московская область' },
        { id: 2, name: 'Санкт-Петербург', region: 'Ленинградская область' },
        { id: 3, name: 'Новосибирск', region: 'Новосибирская область' }
      ]);
    }
  };

  const loadExperts = async () => {
    try {
      setLoading(true);
      const params = {
        topics: selectedTopics.length > 0 ? selectedTopics : undefined,
        city: selectedCity || undefined,
        serviceType: serviceType || undefined,
        search: searchQuery || undefined,
        sortBy: sortBy || undefined,
        page: currentPage,
        limit: pageSize
      };

      console.log('Spiritual Platform: Отправляем запрос поиска экспертов с параметрами:', params);
      console.log('Spiritual Platform: Состояние фильтров:', {
        selectedTopics,
        selectedCity, 
        serviceType,
        searchQuery,
        sortBy
      });
      const response = await expertsAPI.search(params);
      console.log('Spiritual Platform: Получен ответ от API:', response);
      
      setExperts(response?.experts || []);
      setTotalExperts(response?.pagination?.total || 0);
    } catch (error) {
      console.error('Spiritual Platform: Ошибка поиска экспертов:', error);
      console.error('Spiritual Platform: Детали ошибки:', (error as any).response?.data || (error as Error).message);
      
      // Показываем пустой результат при ошибке, а не демо-данные
      setExperts([]);
      setTotalExperts(0);
      return; // Выходим из функции, не показывая демо-данные
    } finally {
      setLoading(false);
    }
  };

  const handleTopicChange = (topicName: string, checked: boolean) => {
    if (checked) {
      setSelectedTopics([...selectedTopics, topicName]);
    } else {
      setSelectedTopics(selectedTopics.filter(t => t !== topicName));
    }
    setCurrentPage(1);
  };

  const clearAllFilters = () => {
    setSelectedTopics([]);
    setSelectedCity('');
    setServiceType('');
    setSearchQuery('');
    setSortBy('rating');
    setCurrentPage(1);
  };

  const handleExpertClick = (expertId: number) => {
    navigate(`/experts/${expertId}`);
  };

  const handleContactExpert = async (expertId: number, event: React.MouseEvent) => {
    event.stopPropagation();

    console.log('Spiritual Platform: Нажата кнопка "связаться" с экспертом:', expertId);
    console.log('Spiritual Platform: Текущий пользователь:', user);

    if (!user) {
      console.log('Spiritual Platform: Пользователь не авторизован');
      message.error('Для связи с экспертом необходимо войти в систему');
      navigate('/login');
      return;
    }

    try {
      setContactLoading(true);
      console.log('Spiritual Platform: Отправляем запрос на создание чата с экспертом:', expertId);

      const chatData = await chatsAPI.start(expertId);
      console.log('Spiritual Platform: Получен ответ от API:', chatData);

      navigate(`/chat/${chatData.chatId}`);
      console.log('Spiritual Platform: Перенаправление на чат:', chatData.chatId);
    } catch (error: any) {
      console.error('Spiritual Platform: Ошибка создания чата:', error);
      console.error('Spiritual Platform: Детали ошибки:', {
        message: error.message,
        status: error.response?.status,
        data: error.response?.data
      });

      if (error.response?.status === 401) {
        message.error('Сессия истекла. Пожалуйста, войдите снова');
        navigate('/login');
      } else if (error.response?.status === 404) {
        message.error('Эксперт не найден');
      } else if (error.response?.status === 500) {
        message.error('Ошибка сервера. Попробуйте позже');
      } else {
        message.error('Не удалось связаться с экспертом');
      }
    } finally {
      setContactLoading(false);
      console.log('Spiritual Platform: Загрузка завершена');
    }
  };

  return (
    <div className="experts-page fullwidth-container">
      <div className="experts-header">
        <Title level={2}>Поиск экспертов</Title>
        <Paragraph>
          Найдите своего наставника среди {totalExperts} проверенных экспертов 
          в области духовных практик
        </Paragraph>
      </div>

      <Row gutter={[24, 24]} className="fullwidth-row">
        {/* Фильтры */}
        <Col xs={24} lg={6}>
          <Card title="Фильтры" className="filters-card" variant="outlined">
            {/* Поиск по имени */}
            <div className="filter-section">
              <Text strong>Поиск по имени:</Text>
              <Search
                placeholder="Имя эксперта"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                onSearch={() => {
                  setCurrentPage(1);
                  loadExperts();
                }}
                style={{ marginTop: 8 }}
              />
            </div>

            {/* Город */}
            <div className="filter-section">
              <Text strong>Город:</Text>
              <Select
                placeholder="Выберите город"
                value={selectedCity || undefined}
                onChange={(value) => {
                  setSelectedCity(value || '');
                  setCurrentPage(1);
                }}
                allowClear
                showSearch
                optionFilterProp="children"
                filterOption={(input, option) =>
                  String(option?.children || '')?.toLowerCase().indexOf(input.toLowerCase()) >= 0
                }
                style={{ width: '100%', marginTop: 8 }}
              >
                {cities.map(city => (
                  <Option key={city.id} value={city.name}>
                    {city.name} ({city.region})
                  </Option>
                ))}
              </Select>
            </div>

            {/* Тип услуг */}
            <div className="filter-section">
              <Text strong>Тип услуг:</Text>
              <Select
                placeholder="Онлайн/Офлайн"
                value={serviceType || undefined}
                onChange={(value) => {
                  setServiceType(value || '');
                  setCurrentPage(1);
                }}
                allowClear
                style={{ width: '100%', marginTop: 8 }}
              >
                <Option value="online">Онлайн</Option>
                <Option value="offline">Офлайн</Option>
              </Select>
            </div>

            {/* Сортировка */}
            <div className="filter-section">
              <Text strong>Сортировка:</Text>
              <Select
                placeholder="Сортировать по"
                value={sortBy}
                onChange={(value) => {
                  setSortBy(value);
                  setCurrentPage(1);
                }}
                style={{ width: '100%', marginTop: 8 }}
              >
                <Option value="rating">По рейтингу</Option>
                <Option value="reviews">По количеству отзывов</Option>
                <Option value="price_low">По цене (сначала дешевле)</Option>
                <Option value="price_high">По цене (сначала дороже)</Option>
                <Option value="newest">Сначала новые</Option>
              </Select>
            </div>

            {/* Тематики */}
            <div className="filter-section">
              <Text strong>Тематики:</Text>
              <div className="topics-checkboxes">
                {topics.map(topic => (
                  <Checkbox
                    key={topic.id}
                    checked={selectedTopics.includes(topic.name)}
                    onChange={(e) => handleTopicChange(topic.name, e.target.checked)}
                  >
                    {topic.name}
                  </Checkbox>
                ))}
              </div>
            </div>

            {/* Очистить фильтры */}
            <Button 
              block 
              onClick={clearAllFilters}
              style={{ marginTop: 16 }}
            >
              Очистить фильтры
            </Button>
          </Card>
        </Col>

        {/* Список экспертов */}
        <Col xs={24} lg={18}>
          {/* Результаты поиска */}
          <div className="search-results-header">
            <Text>
              Найдено экспертов: <Text strong>{totalExperts}</Text>
            </Text>
            {experts.length > 0 && experts[0]?.id === 1 && experts[0]?.firstName === 'Анна' && (
              <Text type="secondary" style={{ fontSize: '12px', marginLeft: '16px' }}>
                (демо-данные для предварительного просмотра)
              </Text>
            )}
          </div>

          {loading ? (
            <div className="loading-container">
              <Spin size="large" />
            </div>
          ) : experts.length === 0 ? (
            <Empty 
              description="Эксперты не найдены"
              image={Empty.PRESENTED_IMAGE_SIMPLE}
            />
          ) : (
            <>
              <Row gutter={[16, 16]} className="fullwidth-row">
                {experts.map(expert => (
                  <Col xs={24} sm={12} lg={8} key={expert.id}>
                    <Card
                      className="expert-card"
                      hoverable
                      onClick={() => handleExpertClick(expert.id)}
                      actions={[
                        <Button
                          type="primary"
                          icon={<MessageOutlined />}
                          onClick={(e) => handleContactExpert(expert.userId, e)}
                          loading={contactLoading}
                          block
                        >
                          Связаться
                        </Button>
                      ]}
                    >
                      <div className="expert-header">
                        <Avatar
                          size={64}
                          src={expert.avatarUrl}
                          icon={<UserOutlined />}
                          className="expert-avatar"
                        />
                        <div className="expert-info">
                          <Title level={5} className="expert-name">
                            {expert.firstName} {expert.lastName}
                          </Title>
                          <div className="expert-rating">
                            <Rate disabled value={Number(expert.rating) || 0} />
                            <Text className="rating-text">
                              {Number(expert.rating || 0).toFixed(1)} ({expert.reviewsCount || 0})
                            </Text>
                          </div>
                          {expert.cityName && (
                            <div className="expert-location">
                              <EnvironmentOutlined />
                              <Text>{expert.cityName}</Text>
                            </div>
                          )}
                        </div>
                      </div>

                      {expert.bio && (
                        <Paragraph className="expert-bio" ellipsis={{ rows: 2 }}>
                          {expert.bio}
                        </Paragraph>
                      )}

                      <div className="expert-topics">
                        {expert.topics.slice(0, 3).map(topic => (
                          <Tag key={topic} color="blue" className="topic-tag">
                            {topic}
                          </Tag>
                        ))}
                        {expert.topics.length > 3 && (
                          <Tag color="default">+{expert.topics.length - 3}</Tag>
                        )}
                      </div>

                      {expert.services && expert.services.length > 0 && (
                        <div className="expert-services">
                          <Text className="services-count">
                            <EyeOutlined /> {expert.services.length} услуг
                          </Text>
                          <Text className="price-from">
                            от {(() => {
                              const validServices = expert.services.filter(s => s && typeof s.price === 'number');
                              return validServices.length > 0 ? Math.min(...validServices.map(s => s.price)) : 0;
                            })()} ₽
                          </Text>
                        </div>
                      )}
                    </Card>
                  </Col>
                ))}
              </Row>

              {/* Пагинация */}
              {totalExperts > pageSize && (
                <div className="pagination-container">
                  <Pagination
                    current={currentPage}
                    pageSize={pageSize}
                    total={totalExperts}
                    onChange={setCurrentPage}
                    showSizeChanger={false}
                    showQuickJumper
                    showTotal={(total, range) => 
                      `${range[0]}-${range[1]} из ${total} экспертов`
                    }
                  />
                </div>
              )}
            </>
          )}
        </Col>
      </Row>
    </div>
  );
};

export default ExpertsPage;
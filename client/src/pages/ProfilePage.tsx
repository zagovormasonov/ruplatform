import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Card,
  Form,
  Input,
  Button,
  Typography,
  Avatar,
  Upload,
  Select,
  Divider,
  Row,
  Col,
  Space,
  message,
  Modal
} from 'antd';
import {
  UserOutlined,
  EditOutlined,
  SaveOutlined,
  CameraOutlined,
  EnvironmentOutlined,
  PhoneOutlined,
  MailOutlined,
  LogoutOutlined
} from '@ant-design/icons';
import { usersAPI } from '../services/api';
import { useAuth } from '../contexts/AuthContext';
import type { City } from '../types/index';
import type { UploadFile } from 'antd/es/upload/interface';
import './ProfilePage.css';

const { Title, Text } = Typography;
const { Option } = Select;

const ProfilePage: React.FC = () => {
  const navigate = useNavigate();
  const { user, logout } = useAuth();
  const [form] = Form.useForm();
  
  const [editMode, setEditMode] = useState(false);
  const [loading, setLoading] = useState(false);
  const [cities, setCities] = useState<City[]>([]);
  const [avatarUrl, setAvatarUrl] = useState<string>('');
  const [, setFileList] = useState<UploadFile[]>([]);

  useEffect(() => {
    if (!user) {
      navigate('/login');
      return;
    }

    loadCities();
    loadUserProfile();
  }, [user, navigate]);

  const loadCities = async () => {
    try {
      const citiesData = await usersAPI.getCities();
      setCities(citiesData);
    } catch (error) {
      console.error('Spiritual Platform: Ошибка загрузки городов:', error);
    }
  };

  const loadUserProfile = async () => {
    try {
      const profileData = await usersAPI.getProfile();
      
      form.setFieldsValue({
        firstName: profileData.firstName,
        lastName: profileData.lastName,
        email: profileData.email,
        phone: profileData.phone,
        city: profileData.city
      });
      
      if (profileData.avatarUrl) {
        setAvatarUrl(profileData.avatarUrl);
      }
    } catch (error) {
      console.error('Spiritual Platform: Ошибка загрузки профиля:', error);
    }
  };

  const handleSave = async (values: any) => {
    try {
      setLoading(true);
      
      const updateData = {
        firstName: values.firstName,
        lastName: values.lastName,
        phone: values.phone,
        city: values.city,
        avatarUrl: avatarUrl
      };

      await usersAPI.updateProfile(updateData);
      
      message.success('Профиль успешно обновлен');
      setEditMode(false);
      
      // Обновляем данные пользователя в контексте
      window.location.reload(); // Простое решение для обновления контекста
    } catch (error: any) {
      console.error('Spiritual Platform: Ошибка обновления профиля:', error);
      message.error(error.response?.data?.error || 'Ошибка при обновлении профиля');
    } finally {
      setLoading(false);
    }
  };

  const handleAvatarUpload = (info: any) => {
    const { fileList: newFileList } = info;
    setFileList(newFileList);

    if (info.file.status === 'done') {
      // В реальном приложении здесь был бы URL загруженного изображения
      const fakeAvatarUrl = URL.createObjectURL(info.file.originFileObj);
      setAvatarUrl(fakeAvatarUrl);
      message.success('Аватар загружен');
    } else if (info.file.status === 'error') {
      message.error('Ошибка загрузки аватара');
    }
  };

  const beforeUpload = (file: File) => {
    const isImage = file.type.startsWith('image/');
    if (!isImage) {
      message.error('Можно загружать только изображения!');
      return false;
    }
    
    const isLt2M = file.size / 1024 / 1024 < 2;
    if (!isLt2M) {
      message.error('Размер изображения не должен превышать 2MB!');
      return false;
    }
    
    return true;
  };

  const handleLogout = () => {
    Modal.confirm({
      title: 'Выйти из системы?',
      content: 'Вы уверены, что хотите выйти из своего аккаунта?',
      okText: 'Выйти',
      cancelText: 'Отмена',
      onOk: () => {
        logout();
        navigate('/');
      }
    });
  };

  const handleCancel = () => {
    form.resetFields();
    setEditMode(false);
    loadUserProfile(); // Восстанавливаем исходные данные
  };

  if (!user) {
    return null;
  }

  return (
    <div className="profile-page">
      <div className="profile-header">
        <Title level={2}>Личный кабинет</Title>
        <Space>
          {!editMode ? (
            <Button
              type="primary"
              icon={<EditOutlined />}
              onClick={() => setEditMode(true)}
            >
              Редактировать
            </Button>
          ) : (
            <Space>
              <Button onClick={handleCancel}>
                Отмена
              </Button>
              <Button
                type="primary"
                icon={<SaveOutlined />}
                onClick={() => form.submit()}
                loading={loading}
              >
                Сохранить
              </Button>
            </Space>
          )}
        </Space>
      </div>

      <Row gutter={[24, 24]}>
        {/* Основная информация */}
        <Col xs={24} lg={16}>
          <Card title="Персональная информация" className="profile-card">
            <Form
              form={form}
              layout="vertical"
              onFinish={handleSave}
              disabled={!editMode}
            >
              <Row gutter={[16, 0]}>
                <Col xs={24} sm={12}>
                  <Form.Item
                    label="Имя"
                    name="firstName"
                    rules={[
                      { required: true, message: 'Пожалуйста, введите ваше имя' }
                    ]}
                  >
                    <Input
                      prefix={<UserOutlined />}
                      placeholder="Имя"
                      size="large"
                    />
                  </Form.Item>
                </Col>
                <Col xs={24} sm={12}>
                  <Form.Item
                    label="Фамилия"
                    name="lastName"
                    rules={[
                      { required: true, message: 'Пожалуйста, введите вашу фамилию' }
                    ]}
                  >
                    <Input
                      prefix={<UserOutlined />}
                      placeholder="Фамилия"
                      size="large"
                    />
                  </Form.Item>
                </Col>
              </Row>

              <Form.Item
                label="Email"
                name="email"
              >
                <Input
                  prefix={<MailOutlined />}
                  placeholder="Email"
                  size="large"
                  disabled // Email нельзя изменить
                />
              </Form.Item>

              <Form.Item
                label="Телефон"
                name="phone"
              >
                <Input
                  prefix={<PhoneOutlined />}
                  placeholder="+7 (999) 123-45-67"
                  size="large"
                />
              </Form.Item>

              <Form.Item
                label="Город"
                name="city"
              >
                <Select
                  prefix={<EnvironmentOutlined />}
                  placeholder="Выберите город"
                  size="large"
                  showSearch
                  optionFilterProp="children"
                  filterOption={(input, option) =>
                    option?.children?.toString().toLowerCase().includes(input.toLowerCase()) ?? false
                  }
                >
                  {cities.map(city => (
                    <Option key={city.id} value={city.name}>
                      {city.name} ({city.region})
                    </Option>
                  ))}
                </Select>
              </Form.Item>
            </Form>
          </Card>
        </Col>

        {/* Боковая панель */}
        <Col xs={24} lg={8}>
          {/* Аватар */}
          <Card title="Фото профиля" className="avatar-card">
            <div className="avatar-section">
              <div className="avatar-container">
                <Avatar
                  size={120}
                  src={avatarUrl || user.avatarUrl}
                  icon={<UserOutlined />}
                  className="profile-avatar"
                />
                {editMode && (
                  <Upload
                    name="avatar"
                    listType="picture"
                    showUploadList={false}
                    beforeUpload={beforeUpload}
                    onChange={handleAvatarUpload}
                    className="avatar-upload"
                  >
                    <Button
                      icon={<CameraOutlined />}
                      className="avatar-upload-btn"
                      shape="circle"
                      size="large"
                    />
                  </Upload>
                )}
              </div>
              <div className="avatar-info">
                <Title level={5}>{user.firstName} {user.lastName}</Title>
                <Text type="secondary" className="user-role">
                  {user.role === 'expert' ? 'Эксперт' : 'Пользователь'}
                </Text>
              </div>
            </div>
          </Card>

          {/* Информация об аккаунте */}
          <Card title="Информация об аккаунте" className="account-info-card">
            <div className="account-info">
              <div className="info-item">
                <Text strong>Тип аккаунта:</Text>
                <Text>{user.role === 'expert' ? 'Эксперт' : 'Пользователь'}</Text>
              </div>
              <div className="info-item">
                <Text strong>Email:</Text>
                <Text>{user.email}</Text>
              </div>
              {user.role === 'expert' && (
                <div className="info-item">
                  <Text strong>Статус:</Text>
                  <Text style={{ color: '#52c41a' }}>Активный эксперт</Text>
                </div>
              )}
            </div>

            <Divider />

            <div className="account-actions">
              {user.role === 'expert' && (
                <Button
                  type="default"
                  block
                  onClick={() => navigate('/expert-dashboard')}
                  className="dashboard-btn"
                >
                  Панель эксперта
                </Button>
              )}
              
              <Button
                danger
                block
                icon={<LogoutOutlined />}
                onClick={handleLogout}
                className="logout-btn"
              >
                Выйти из системы
              </Button>
            </div>
          </Card>
        </Col>
      </Row>
    </div>
  );
};

export default ProfilePage;
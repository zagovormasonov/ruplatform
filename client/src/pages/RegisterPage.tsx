import React, { useState } from 'react';
import { Form, Input, Button, Card, Typography, Divider, Radio } from 'antd';
import { Link, useNavigate } from 'react-router-dom';
import { 
  LockOutlined, 
  MailOutlined, 
  UserOutlined, 
  UserAddOutlined,
  TeamOutlined
} from '@ant-design/icons';
import { useAuth } from '../contexts/AuthContext';
import type { RegisterData } from '../types/user';
import './AuthPages.css';

const { Title, Text } = Typography;

const RegisterPage: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const { register } = useAuth();
  const navigate = useNavigate();

  const onFinish = async (values: RegisterData & { confirmPassword: string }) => {
    if (values.password !== values.confirmPassword) {
      return;
    }

    try {
      setLoading(true);
      const { confirmPassword, ...registerData } = values;
      await register(registerData);
      navigate('/');
    } catch (error) {
      // Ошибка уже обработана в AuthContext
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-page">
      <div className="auth-container">
        <Card className="auth-card register-card">
          <div className="auth-header">
            <Title level={2} className="auth-title">
              Создание аккаунта
            </Title>
            <Text className="auth-subtitle">
              Присоединяйтесь к нашему сообществу
            </Text>
          </div>

          <Form
            name="register"
            onFinish={onFinish}
            layout="vertical"
            size="large"
            className="auth-form"
            initialValues={{ role: 'user' }}
          >
            <Form.Item
              label="Тип аккаунта"
              name="role"
              rules={[
                {
                  required: true,
                  message: 'Пожалуйста, выберите тип аккаунта!',
                },
              ]}
            >
              <Radio.Group className="role-selector">
                <Radio.Button value="user" className="role-option">
                  <UserOutlined />
                  <span>Пользователь</span>
                  <div className="role-description">
                    Поиск экспертов и чтение статей
                  </div>
                </Radio.Button>
                <Radio.Button value="expert" className="role-option">
                  <TeamOutlined />
                  <span>Эксперт</span>
                  <div className="role-description">
                    Предоставление услуг и написание статей
                  </div>
                </Radio.Button>
              </Radio.Group>
            </Form.Item>

            <div className="name-fields">
              <Form.Item
                label="Имя"
                name="firstName"
                rules={[
                  {
                    required: true,
                    message: 'Пожалуйста, введите ваше имя!',
                  },
                ]}
              >
                <Input
                  prefix={<UserOutlined />}
                  placeholder="Имя"
                  className="auth-input"
                />
              </Form.Item>

              <Form.Item
                label="Фамилия"
                name="lastName"
                rules={[
                  {
                    required: true,
                    message: 'Пожалуйста, введите вашу фамилию!',
                  },
                ]}
              >
                <Input
                  prefix={<UserOutlined />}
                  placeholder="Фамилия"
                  className="auth-input"
                />
              </Form.Item>
            </div>

            <Form.Item
              label="Email"
              name="email"
              rules={[
                {
                  required: true,
                  message: 'Пожалуйста, введите ваш email!',
                },
                {
                  type: 'email',
                  message: 'Пожалуйста, введите корректный email!',
                },
              ]}
            >
              <Input
                prefix={<MailOutlined />}
                placeholder="your.email@example.com"
                className="auth-input"
              />
            </Form.Item>

            <Form.Item
              label="Пароль"
              name="password"
              rules={[
                {
                  required: true,
                  message: 'Пожалуйста, введите пароль!',
                },
                {
                  min: 6,
                  message: 'Пароль должен содержать минимум 6 символов!',
                },
              ]}
            >
              <Input.Password
                prefix={<LockOutlined />}
                placeholder="Минимум 6 символов"
                className="auth-input"
              />
            </Form.Item>

            <Form.Item
              label="Подтверждение пароля"
              name="confirmPassword"
              dependencies={['password']}
              rules={[
                {
                  required: true,
                  message: 'Пожалуйста, подтвердите пароль!',
                },
                ({ getFieldValue }) => ({
                  validator(_, value) {
                    if (!value || getFieldValue('password') === value) {
                      return Promise.resolve();
                    }
                    return Promise.reject(new Error('Пароли не совпадают!'));
                  },
                }),
              ]}
            >
              <Input.Password
                prefix={<LockOutlined />}
                placeholder="Повторите пароль"
                className="auth-input"
              />
            </Form.Item>

            <Form.Item>
              <Button
                type="primary"
                htmlType="submit"
                loading={loading}
                icon={<UserAddOutlined />}
                className="auth-submit-button"
                block
              >
                Создать аккаунт
              </Button>
            </Form.Item>
          </Form>

          <Divider className="auth-divider">или</Divider>

          <div className="auth-footer">
            <Text className="auth-footer-text">
              Уже есть аккаунт?{' '}
              <Link to="/login" className="auth-link">
                Войти
              </Link>
            </Text>
          </div>
        </Card>
      </div>
    </div>
  );
};

export default RegisterPage;

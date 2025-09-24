import React, { useState } from 'react';
import { Form, Input, Button, Card, Typography, Divider } from 'antd';
import { Link, useNavigate } from 'react-router-dom';
import { LockOutlined, MailOutlined, LoginOutlined } from '@ant-design/icons';
import { useAuth } from '../contexts/AuthContext';
import './AuthPages.css';

const { Title, Text } = Typography;

const LoginPage: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  const onFinish = async (values: { email: string; password: string }) => {
    try {
      setLoading(true);
      await login(values.email, values.password);
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
        <Card className="auth-card">
          <div className="auth-header">
            <Title level={2} className="auth-title">
              Добро пожаловать
            </Title>
            <Text className="auth-subtitle">
              Войдите в свою учетную запись
            </Text>
          </div>

          <Form
            name="login"
            onFinish={onFinish}
            layout="vertical"
            size="large"
            className="auth-form"
          >
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
                  message: 'Пожалуйста, введите ваш пароль!',
                },
              ]}
            >
              <Input.Password
                prefix={<LockOutlined />}
                placeholder="Введите пароль"
                className="auth-input"
              />
            </Form.Item>

            <Form.Item>
              <Button
                type="primary"
                htmlType="submit"
                loading={loading}
                icon={<LoginOutlined />}
                className="auth-submit-button"
                block
              >
                Войти
              </Button>
            </Form.Item>
          </Form>

          <Divider className="auth-divider">или</Divider>

          <div className="auth-footer">
            <Text className="auth-footer-text">
              Еще нет аккаунта?{' '}
              <Link to="/register" className="auth-link">
                Зарегистрироваться
              </Link>
            </Text>
          </div>
        </Card>
      </div>
    </div>
  );
};

export default LoginPage;

import React, { useState } from 'react';
import { Layout as AntLayout, Menu, Button, Avatar, Space, Drawer } from 'antd';
import { useNavigate, useLocation } from 'react-router-dom';
import { 
  HomeOutlined, 
  TeamOutlined, 
  FileTextOutlined, 
  MessageOutlined,
  UserOutlined,
  LogoutOutlined,
  LoginOutlined,
  UserAddOutlined,
  PlusOutlined,
  DashboardOutlined,
  MenuOutlined
} from '@ant-design/icons';
import { useAuth } from '../../contexts/AuthContext';
import type { MenuProps } from 'antd';
import './Layout.css';

const { Header, Content, Footer } = AntLayout;

interface LayoutProps {
  children: React.ReactNode;
}

const Layout: React.FC<LayoutProps> = ({ children }) => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [drawerVisible, setDrawerVisible] = useState(false);

  const handleMenuClick = (key: string) => {
    navigate(key);
    setDrawerVisible(false);
  };

  // Удалена функция handleUserMenuClick так как больше не используется

  const menuItems: MenuProps['items'] = [
    {
      key: '/',
      icon: <HomeOutlined />,
      label: 'Главная',
    },
    {
      key: '/experts',
      icon: <TeamOutlined />,
      label: 'Эксперты',
    },
    {
      key: '/articles',
      icon: <FileTextOutlined />,
      label: 'Статьи',
    },
  ];

  if (user) {
    menuItems.push({
      key: '/chat',
      icon: <MessageOutlined />,
      label: 'Чаты',
    });
  }

  // Удалены userMenuItems так как больше не используется Dropdown

  const mobileMenu = (
    <Menu
      mode="vertical"
      selectedKeys={[location.pathname]}
      items={menuItems}
      onClick={({ key }) => handleMenuClick(key)}
      style={{ border: 'none' }}
    />
  );

  return (
    <AntLayout className="layout">
      <Header className="header">
        <div className="header-content">
          <div className="logo-section">
            <Button
              className="mobile-menu-button"
              type="text"
              icon={<MenuOutlined />}
              onClick={() => setDrawerVisible(true)}
            />
            <div className="logo" onClick={() => navigate('/')}>
              <span className="logo-text">Духовные Мастера</span>
            </div>
          </div>

          <Menu
            theme="light"
            mode="horizontal"
            selectedKeys={[location.pathname]}
            items={menuItems}
            onClick={({ key }) => handleMenuClick(key)}
            className="desktop-menu"
          />

          <div className="header-actions">
            {user ? (
              <Space size="middle">
                {user.role === 'expert' && (
                  <Button
                    type="primary"
                    icon={<PlusOutlined />}
                    onClick={() => navigate('/create-article')}
                    className="create-button"
                  >
                    <span className="create-button-text">Создать статью</span>
                  </Button>
                )}
                
                <Button
                  type="text"
                  icon={<MessageOutlined />}
                  onClick={() => navigate('/chat')}
                  className="message-button"
                >
                  Чаты
                </Button>

                {user.role === 'expert' && (
                  <Button
                    type="text"
                    icon={<DashboardOutlined />}
                    onClick={() => navigate('/expert-dashboard')}
                    className="dashboard-button"
                  >
                    Панель
                  </Button>
                )}

                <Space>
                  <Avatar 
                    src={user.avatarUrl} 
                    icon={<UserOutlined />}
                    size="default"
                    style={{ cursor: 'pointer' }}
                    onClick={() => navigate('/profile')}
                  />
                  <span 
                    className="user-name"
                    style={{ cursor: 'pointer' }}
                    onClick={() => navigate('/profile')}
                  >
                    {user.firstName} {user.lastName}
                  </span>
                  <Button
                    type="text"
                    icon={<LogoutOutlined />}
                    onClick={() => {
                      logout();
                      navigate('/');
                    }}
                    title="Выйти"
                  />
                </Space>
              </Space>
            ) : (
              <Space>
                <Button
                  type="text"
                  icon={<LoginOutlined />}
                  onClick={() => navigate('/login')}
                  className="auth-button"
                >
                  Войти
                </Button>
                <Button
                  type="primary"
                  icon={<UserAddOutlined />}
                  onClick={() => navigate('/register')}
                  className="auth-button"
                >
                  Регистрация
                </Button>
              </Space>
            )}
          </div>
        </div>
      </Header>

      <Drawer
        title="Меню"
        placement="left"
        onClose={() => setDrawerVisible(false)}
        open={drawerVisible}
        className="mobile-drawer"
      >
        {mobileMenu}
        {!user && (
          <div className="mobile-auth-buttons">
            <Button
              type="text"
              icon={<LoginOutlined />}
              onClick={() => {
                navigate('/login');
                setDrawerVisible(false);
              }}
              block
            >
              Войти
            </Button>
            <Button
              type="primary"
              icon={<UserAddOutlined />}
              onClick={() => {
                navigate('/register');
                setDrawerVisible(false);
              }}
              block
            >
              Регистрация
            </Button>
          </div>
        )}
      </Drawer>

      <Content className="content">
        <div className="content-wrapper">
          {children}
        </div>
      </Content>

      <Footer className="footer">
        <div className="footer-content">
          <div className="footer-text">
            Платформа Духовных Мастеров © 2024. Все права защищены.
          </div>
        </div>
      </Footer>
    </AntLayout>
  );
};

export default Layout;

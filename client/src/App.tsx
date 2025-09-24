// import React from 'react'; // Не используется в современном React
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { ConfigProvider, App as AntApp } from 'antd';
import ruRU from 'antd/locale/ru_RU';
import { AuthProvider } from './contexts/AuthContext';
import { ChatProvider } from './contexts/ChatContext';
import Layout from './components/Layout/Layout';
import ErrorBoundary from './components/ErrorBoundary';
import HomePage from './pages/HomePage';
import LoginPage from './pages/LoginPage';
import RegisterPage from './pages/RegisterPage';
import ExpertsPage from './pages/ExpertsPage';
import ExpertProfilePage from './pages/ExpertProfilePage';
import ArticlesPage from './pages/ArticlesPage';
import ArticlePage from './pages/ArticlePage';
import ProfilePage from './pages/ProfilePage';
import ChatPage from './pages/ChatPage';
import CreateArticlePage from './pages/CreateArticlePage';
import ExpertDashboardPage from './pages/ExpertDashboardPage';
import './App.css';

const theme = {
  token: {
    colorPrimary: '#6366f1',
    colorBgContainer: '#ffffff',
    colorBgElevated: '#ffffff',
    borderRadius: 8,
    fontSize: 14,
    fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
  },
  components: {
    Layout: {
      headerBg: '#ffffff',
      bodyBg: '#f8fafc',
      footerBg: '#ffffff',
    },
    Button: {
      borderRadius: 6,
      controlHeight: 40,
    },
    Input: {
      borderRadius: 6,
      controlHeight: 40,
    },
    Card: {
      borderRadius: 12,
      boxShadow: '0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)',
    },
    Grid: {
      containerMaxWidths: {
        xs: '100%',
        sm: '100%',
        md: '100%',
        lg: '100%',
        xl: '100%',
        xxl: '100%',
      },
    },
  },
};

function App() {
  return (
    <ConfigProvider theme={theme} locale={ruRU}>
      <AntApp>
        <ErrorBoundary>
          <AuthProvider>
            <ChatProvider>
              <Router>
              <Layout>
                <Routes>
                  <Route path="/" element={<HomePage />} />
                  <Route path="/login" element={<LoginPage />} />
                  <Route path="/register" element={<RegisterPage />} />
                  <Route path="/experts" element={<ErrorBoundary><ExpertsPage /></ErrorBoundary>} />
                  <Route path="/experts/:id" element={<ErrorBoundary><ExpertProfilePage /></ErrorBoundary>} />
                  <Route path="/articles" element={<ErrorBoundary><ArticlesPage /></ErrorBoundary>} />
                  <Route path="/articles/:id" element={<ErrorBoundary><ArticlePage /></ErrorBoundary>} />
                  <Route path="/profile" element={<ErrorBoundary><ProfilePage /></ErrorBoundary>} />
                  <Route path="/chat" element={<ErrorBoundary><ChatPage /></ErrorBoundary>} />
                  <Route path="/chat/:chatId" element={<ErrorBoundary><ChatPage /></ErrorBoundary>} />
                  <Route path="/create-article" element={<ErrorBoundary><CreateArticlePage /></ErrorBoundary>} />
                  <Route path="/expert-dashboard" element={<ErrorBoundary><ExpertDashboardPage /></ErrorBoundary>} />
                </Routes>
              </Layout>
              </Router>
            </ChatProvider>
          </AuthProvider>
        </ErrorBoundary>
      </AntApp>
    </ConfigProvider>
  );
}

export default App;
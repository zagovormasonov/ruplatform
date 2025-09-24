import React, { Component } from 'react';
import type { ReactNode } from 'react';
import { Result, Button } from 'antd';

interface Props {
  children: ReactNode;
}

interface State {
  hasError: boolean;
  error?: Error;
}

class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('Spiritual Platform: Ошибка в компоненте:', error, errorInfo);
  }

  handleReload = () => {
    window.location.reload();
  };

  render() {
    if (this.state.hasError) {
      return (
        <div style={{ padding: '50px', textAlign: 'center' }}>
          <Result
            status="error"
            title="Упс! Что-то пошло не так"
            subTitle="Произошла ошибка при загрузке компонента. Попробуйте перезагрузить страницу."
            extra={[
              <Button key="reload" type="primary" onClick={this.handleReload}>
                Перезагрузить страницу
              </Button>,
              <Button key="back" onClick={() => window.history.back()}>
                Назад
              </Button>
            ]}
          />
        </div>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;

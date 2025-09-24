import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Card,
  Form,
  Input,
  Button,
  Typography,
  Upload,
  message,
  Switch,
  Space,
  Divider
} from 'antd';
import {
  SaveOutlined,
  EyeOutlined,
  FileImageOutlined,
  ArrowLeftOutlined
} from '@ant-design/icons';
import { articlesAPI } from '../services/api';
import { useAuth } from '../contexts/AuthContext';
import type { UploadFile } from 'antd/es/upload/interface';
import './CreateArticlePage.css';

const { Title, Text } = Typography;
const { TextArea } = Input;

const CreateArticlePage: React.FC = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [form] = Form.useForm();
  
  const [loading, setLoading] = useState(false);
  const [previewMode, setPreviewMode] = useState(false);
  const [coverImage, setCoverImage] = useState<string>('');
  const [fileList, setFileList] = useState<UploadFile[]>([]);

  React.useEffect(() => {
    if (!user) {
      navigate('/login');
      return;
    }
  }, [user, navigate]);

  const handleSubmit = async (values: any) => {
    try {
      setLoading(true);
      
      const articleData = {
        title: values.title,
        content: values.content,
        excerpt: values.excerpt,
        coverImage: coverImage,
        isPublished: values.isPublished || false
      };

      const createdArticle = await articlesAPI.create(articleData);
      
      message.success(
        values.isPublished 
          ? 'Статья успешно опубликована!' 
          : 'Статья сохранена как черновик!'
      );
      
      navigate(`/articles/${createdArticle.id}`);
    } catch (error: any) {
      console.error('Spiritual Platform: Ошибка создания статьи:', error);
      message.error(error.response?.data?.error || 'Ошибка при создании статьи');
    } finally {
      setLoading(false);
    }
  };

  const handleImageUpload = (info: any) => {
    const { fileList: newFileList } = info;
    setFileList(newFileList);

    if (info.file.status === 'done') {
      // В реальном приложении здесь был бы URL загруженного изображения
      const fakeImageUrl = URL.createObjectURL(info.file.originFileObj);
      setCoverImage(fakeImageUrl);
      message.success('Изображение загружено');
    } else if (info.file.status === 'error') {
      message.error('Ошибка загрузки изображения');
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

  const handlePreview = () => {
    const values = form.getFieldsValue();
    if (!values.title || !values.content) {
      message.warning('Заполните заголовок и содержание для предварительного просмотра');
      return;
    }
    setPreviewMode(!previewMode);
  };

  const renderPreview = () => {
    const values = form.getFieldsValue();
    
    return (
      <div className="article-preview">
        {coverImage && (
          <div className="preview-cover">
            <img src={coverImage} alt="Обложка статьи" />
          </div>
        )}
        
        <div className="preview-content">
          <Title level={1} className="preview-title">
            {values.title || 'Заголовок статьи'}
          </Title>
          
          <div className="preview-meta">
            <Text>
              Автор: {user?.firstName} {user?.lastName}
            </Text>
            <Text>
              Дата: {new Date().toLocaleDateString('ru-RU')}
            </Text>
          </div>
          
          {values.excerpt && (
            <div className="preview-excerpt">
              <Text italic>{values.excerpt}</Text>
            </div>
          )}
          
          <Divider />
          
          <div className="preview-text">
            {values.content?.split('\n').map((paragraph: string, index: number) => (
              <p key={index}>{paragraph}</p>
            ))}
          </div>
        </div>
      </div>
    );
  };

  if (!user) {
    return null;
  }

  return (
    <div className="create-article-page">
      <div className="page-header">
        <Button
          icon={<ArrowLeftOutlined />}
          onClick={() => navigate(-1)}
          className="back-button"
        >
          Назад
        </Button>
        
        <Title level={2}>
          {previewMode ? 'Предварительный просмотр' : 'Создание статьи'}
        </Title>
        
        <Space>
          <Button
            icon={<EyeOutlined />}
            onClick={handlePreview}
            className={previewMode ? 'preview-active' : ''}
          >
            {previewMode ? 'Редактировать' : 'Просмотр'}
          </Button>
        </Space>
      </div>

      {previewMode ? (
        <Card className="preview-card">
          {renderPreview()}
        </Card>
      ) : (
        <Card className="form-card">
          <Form
            form={form}
            layout="vertical"
            onFinish={handleSubmit}
            className="article-form"
          >
            <Form.Item
              label="Заголовок статьи"
              name="title"
              rules={[
                { required: true, message: 'Пожалуйста, введите заголовок статьи' },
                { min: 10, message: 'Заголовок должен содержать минимум 10 символов' },
                { max: 200, message: 'Заголовок не должен превышать 200 символов' }
              ]}
            >
              <Input
                placeholder="Введите заголовок статьи..."
                size="large"
                showCount
                maxLength={200}
              />
            </Form.Item>

            <Form.Item
              label="Краткое описание"
              name="excerpt"
              rules={[
                { max: 300, message: 'Описание не должно превышать 300 символов' }
              ]}
            >
              <TextArea
                placeholder="Краткое описание статьи для превью..."
                rows={3}
                showCount
                maxLength={300}
              />
            </Form.Item>

            <Form.Item label="Обложка статьи">
              <Upload
                name="coverImage"
                listType="picture-card"
                fileList={fileList}
                beforeUpload={beforeUpload}
                onChange={handleImageUpload}
                onPreview={() => {}}
                className="cover-upload"
              >
                {fileList.length === 0 && (
                  <div>
                    <FileImageOutlined />
                    <div style={{ marginTop: 8 }}>Загрузить обложку</div>
                  </div>
                )}
              </Upload>
              <Text type="secondary" className="upload-hint">
                Рекомендуемый размер: 1200x600px. Максимальный размер: 2MB
              </Text>
            </Form.Item>

            <Form.Item
              label="Содержание статьи"
              name="content"
              rules={[
                { required: true, message: 'Пожалуйста, введите содержание статьи' },
                { min: 100, message: 'Статья должна содержать минимум 100 символов' }
              ]}
            >
              <TextArea
                placeholder="Напишите вашу статью..."
                rows={15}
                showCount
                className="content-textarea"
              />
            </Form.Item>

            <Divider />

            <div className="form-actions">
              <div className="publish-options">
                <Form.Item
                  name="isPublished"
                  valuePropName="checked"
                  className="publish-switch"
                >
                  <Switch />
                </Form.Item>
                <div className="publish-text">
                  <Text strong>Опубликовать сразу</Text>
                  <Text type="secondary">
                    Если выключено, статья будет сохранена как черновик
                  </Text>
                </div>
              </div>

              <Space size="middle">
                <Button onClick={() => navigate(-1)}>
                  Отмена
                </Button>
                <Button
                  type="primary"
                  htmlType="submit"
                  loading={loading}
                  icon={<SaveOutlined />}
                  size="large"
                >
                  {form.getFieldValue('isPublished') ? 'Опубликовать' : 'Сохранить черновик'}
                </Button>
              </Space>
            </div>
          </Form>
        </Card>
      )}
    </div>
  );
};

export default CreateArticlePage;
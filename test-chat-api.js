const axios = require('axios');

async function testChatAPI() {
  try {
    // Получаем токен (нужно заменить на реальный токен с сервера)
    const loginResponse = await axios.post('http://31.130.155.103/api/auth/login', {
      email: 'test@example.com', // Замените на реальный email
      password: 'password'       // Замените на реальный пароль
    });

    const token = loginResponse.data.token;
    console.log('Token получен:', token);

    // Тестируем создание чата
    const chatResponse = await axios.post('http://31.130.155.103/api/chats/start', {
      otherUserId: 2  // ID эксперта
    }, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });

    console.log('Ответ от API:', chatResponse.data);

  } catch (error) {
    console.error('Ошибка:', error.response?.data || error.message);
    console.error('Статус:', error.response?.status);
  }
}

testChatAPI();

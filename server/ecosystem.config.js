module.exports = {
  apps: [{
    name: 'ruplatform-api',
    script: 'dist/index.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    // Логи
    log_file: './logs/combined.log',
    out_file: './logs/out.log',
    error_file: './logs/error.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    
    // Другие настройки
    exec_mode: 'fork',
    min_uptime: '10s',
    max_restarts: 10,
    
    // Переменные окружения из файла
    env_file: '.env'
  }]
}

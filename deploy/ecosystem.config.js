// PM2 process definition for the Node API in production.
// Usage on the VPS: pm2 start deploy/ecosystem.config.js
module.exports = {
  apps: [
    {
      name: 'portfolio-api',
      cwd: '/var/www/portfolio/backend',
      script: 'dist/server.js',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
      },
      max_memory_restart: '300M',
      autorestart: true,
      watch: false,
    },
  ],
};

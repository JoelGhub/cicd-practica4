const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// Health check endpoint (importante para ECS)
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: process.env.APP_VERSION || '1.0.0'
  });
});

// Endpoint principal
app.get('/', (req, res) => {
  res.json({
    message: '¡Hola desde Render con CI/CD!',
    version: process.env.APP_VERSION || '1.0.0',
    deployment: process.env.DEPLOYMENT_TYPE || 'production',
    timestamp: new Date().toISOString()
  });
});

// Endpoint de información
app.get('/info', (req, res) => {
  res.json({
    app: 'CI/CD con Render + GitHub Actions',
    environment: process.env.NODE_ENV || 'development',
    version: process.env.APP_VERSION || '1.0.0',
    platform: 'Render',
    pipeline: 'GitHub Actions'
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📦 Version: ${process.env.APP_VERSION || '1.0.0'}`);
  console.log(`🎯 Deployment: ${process.env.DEPLOYMENT_TYPE || 'blue'}`);
});

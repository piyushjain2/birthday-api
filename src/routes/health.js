const express = require('express');
const router = express.Router();
const { checkDatabaseHealth } = require('../config/database');
const logger = require('../utils/logger');

// Liveness probe - checks if the application is running
router.get('/live', (req, res) => {
  res.status(200).json({ 
    status: 'ok',
    timestamp: new Date().toISOString()
  });
});

// Readiness probe - checks if the application is ready to serve traffic
router.get('/ready', async (req, res) => {
  try {
    const dbHealth = await checkDatabaseHealth();
    
    // Application is ready only if primary database is available
    if (dbHealth.primary) {
      res.status(200).json({
        status: 'ready',
        timestamp: new Date().toISOString(),
        database: dbHealth
      });
    } else {
      res.status(503).json({
        status: 'not ready',
        timestamp: new Date().toISOString(),
        database: dbHealth,
        message: 'Primary database is not available'
      });
    }
  } catch (error) {
    logger.error('Health check failed:', error);
    res.status(503).json({
      status: 'error',
      timestamp: new Date().toISOString(),
      message: 'Health check failed'
    });
  }
});

// Detailed health check
router.get('/', async (req, res) => {
  try {
    const dbHealth = await checkDatabaseHealth();
    const memoryUsage = process.memoryUsage();
    const uptime = process.uptime();

    res.status(200).json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: `${Math.floor(uptime / 60)} minutes`,
      memory: {
        rss: `${Math.round(memoryUsage.rss / 1024 / 1024)} MB`,
        heapTotal: `${Math.round(memoryUsage.heapTotal / 1024 / 1024)} MB`,
        heapUsed: `${Math.round(memoryUsage.heapUsed / 1024 / 1024)} MB`,
      },
      database: dbHealth,
      environment: process.env.NODE_ENV || 'development'
    });
  } catch (error) {
    logger.error('Detailed health check failed:', error);
    res.status(503).json({
      status: 'error',
      timestamp: new Date().toISOString(),
      message: 'Health check failed'
    });
  }
});

module.exports = router; 
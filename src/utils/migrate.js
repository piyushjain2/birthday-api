require('dotenv').config();
const { initializeDatabase } = require('../config/database');
const logger = require('./logger');

const runMigrations = async () => {
  try {
    logger.info('Starting database migrations...');
    
    // Initialize database and create tables
    await initializeDatabase();
    
    logger.info('Database migrations completed successfully');
    process.exit(0);
  } catch (error) {
    logger.error('Migration failed:', error);
    process.exit(1);
  }
};

// Run migrations if this file is executed directly
if (require.main === module) {
  runMigrations();
}

module.exports = { runMigrations }; 
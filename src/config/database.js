const { Pool } = require('pg');
const logger = require('../utils/logger');

let pool;
let readPool;

const MAX_RETRIES = 5;
const RETRY_DELAY = 5000;

const createPool = (config) => {
  return new Pool({
    ...config,
    max: parseInt(process.env.DB_POOL_SIZE || '20'),
    min: parseInt(process.env.DB_MIN_POOL_SIZE || '5'),
    idleTimeoutMillis: parseInt(process.env.DB_IDLE_TIMEOUT || '30000'),
    connectionTimeoutMillis: parseInt(process.env.DB_CONNECTION_TIMEOUT || '2000'),
    statement_timeout: parseInt(process.env.DB_STATEMENT_TIMEOUT || '30000'),
    query_timeout: parseInt(process.env.DB_QUERY_TIMEOUT || '30000'),
    application_name: process.env.APP_NAME || 'birthday-app',
  });
};

const wait = (ms) => new Promise(resolve => setTimeout(resolve, ms));

const initializeDatabase = async (retryCount = 0) => {
  try {
    // Primary write connection
    const primaryConfig = {
      host: process.env.DB_PRIMARY_HOST || 'localhost',
      port: parseInt(process.env.DB_PRIMARY_PORT || '5432'),
      database: process.env.DB_NAME || 'birthday_db',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres',
      ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
    };

    pool = createPool(primaryConfig);

    // Read replica connection (if configured)
    if (process.env.DB_READ_HOST) {
      const readConfig = {
        host: process.env.DB_READ_HOST,
        port: parseInt(process.env.DB_READ_PORT || '5432'),
        database: process.env.DB_NAME || 'birthday_db',
        user: process.env.DB_USER || 'postgres',
        password: process.env.DB_PASSWORD || 'postgres',
        ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
      };
      readPool = createPool(readConfig);
    } else {
      // Use primary for reads if no read replica configured
      readPool = pool;
    }

    // Test connections with retry logic
    await testConnection(pool, 'Primary');
    if (readPool !== pool) {
      await testConnection(readPool, 'Read Replica');
    }

    // Create table if not exists
    await createTables();

  } catch (error) {
    logger.error(`Database initialization attempt ${retryCount + 1} failed:`, error);
    
    if (retryCount < MAX_RETRIES) {
      logger.info(`Retrying in ${RETRY_DELAY/1000} seconds...`);
      await wait(RETRY_DELAY);
      return initializeDatabase(retryCount + 1);
    }
    
    throw error;
  }
};

const testConnection = async (pool, name) => {
  try {
    await pool.query('SELECT 1');
    logger.info(`${name} database connection established`);
  } catch (error) {
    logger.error(`${name} database connection test failed:`, error);
    throw error;
  }
};

const createTables = async () => {
  const createTableQuery = `
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      username VARCHAR(255) UNIQUE NOT NULL CHECK (username ~ '^[a-zA-Z]+$'),
      date_of_birth DATE NOT NULL CHECK (date_of_birth < CURRENT_DATE),
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );

    CREATE INDEX IF NOT EXISTS idx_username ON users(username);
    CREATE INDEX IF NOT EXISTS idx_date_of_birth ON users(date_of_birth);

    -- Create update trigger for updated_at
    CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER AS $$
    BEGIN
      NEW.updated_at = CURRENT_TIMESTAMP;
      RETURN NEW;
    END;
    $$ language 'plpgsql';

    DROP TRIGGER IF EXISTS update_users_updated_at ON users;
    
    CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();
  `;

  try {
    await pool.query(createTableQuery);
    logger.info('Database tables created/verified successfully');
  } catch (error) {
    logger.error('Error creating tables:', error);
    throw error;
  }
};

const getWritePool = () => {
  if (!pool) {
    throw new Error('Database not initialized');
  }
  return pool;
};

const getReadPool = () => {
  if (!readPool) {
    throw new Error('Database not initialized');
  }
  return readPool;
};

const closeDatabase = async () => {
  try {
    if (pool) {
      await pool.end();
      logger.info('Primary database pool closed');
    }
    if (readPool && readPool !== pool) {
      await readPool.end();
      logger.info('Read replica database pool closed');
    }
  } catch (error) {
    logger.error('Error closing database connections:', error);
    throw error;
  }
};

// Health check for database
const checkDatabaseHealth = async () => {
  const checks = {
    primary: false,
    readReplica: false,
  };

  try {
    await pool.query('SELECT 1');
    checks.primary = true;
  } catch (error) {
    logger.error('Primary database health check failed:', error);
  }

  if (readPool !== pool) {
    try {
      await readPool.query('SELECT 1');
      checks.readReplica = true;
    } catch (error) {
      logger.error('Read replica health check failed:', error);
    }
  } else {
    checks.readReplica = checks.primary;
  }

  return checks;
};

module.exports = {
  initializeDatabase,
  getWritePool,
  getReadPool,
  closeDatabase,
  checkDatabaseHealth,
}; 
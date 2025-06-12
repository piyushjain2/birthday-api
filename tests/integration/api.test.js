const request = require('supertest');
const express = require('express');

// Mock the database module before requiring the app
jest.mock('../../src/config/database', () => ({
  initializeDatabase: jest.fn().mockResolvedValue(true),
  closeDatabase: jest.fn().mockResolvedValue(true),
  getWritePool: jest.fn().mockReturnValue({
    query: jest.fn().mockResolvedValue({ rows: [] })
  }),
  getReadPool: jest.fn().mockReturnValue({
    query: jest.fn().mockResolvedValue({ rows: [] })
  }),
  checkDatabaseHealth: jest.fn().mockResolvedValue({
    primary: true,
    readReplica: true
  })
}));

// Create a test app instance without starting the server
const createTestApp = () => {
  const app = express();
  const helmet = require('helmet');
  const cors = require('cors');
  const compression = require('compression');
  
  // Middleware
  app.use(helmet());
  app.use(cors());
  app.use(compression());
  app.use(express.json());
  app.use(express.urlencoded({ extended: true }));
  
  // Routes
  app.use('/health', require('../../src/routes/health'));
  app.use('/hello', require('../../src/routes/birthday'));
  
  // Error handler
  app.use(require('../../src/middleware/errorHandler'));
  
  return app;
};

// Mock user model
jest.mock('../../src/models/userModel', () => ({
  createUser: jest.fn(),
  updateUser: jest.fn(),
  findByUsername: jest.fn(),
  findAll: jest.fn()
}));

const userModel = require('../../src/models/userModel');

describe('Birthday API Integration Tests', () => {
  let app;
  
  beforeAll(() => {
    app = createTestApp();
  });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('PUT /hello/:username', () => {
    it('should save user birthday successfully', async () => {
      userModel.findByUsername.mockResolvedValue(null);
      userModel.createUser.mockResolvedValue({ id: 1, username: 'alice', date_of_birth: '1990-05-15' });

      const response = await request(app)
        .put('/hello/alice')
        .send({ dateOfBirth: '1990-05-15' });

      expect(response.status).toBe(204);
    });

    it('should update existing user birthday', async () => {
      userModel.findByUsername.mockResolvedValue({ id: 1, username: 'bob', date_of_birth: '1985-03-20' });
      userModel.updateUser.mockResolvedValue({ id: 1, username: 'bob', date_of_birth: '1985-03-21' });

      const response = await request(app)
        .put('/hello/bob')
        .send({ dateOfBirth: '1985-03-21' });

      expect(response.status).toBe(204);
    });

    it('should reject invalid username with numbers', async () => {
      const response = await request(app)
        .put('/hello/user123')
        .send({ dateOfBirth: '1990-01-01' });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('Validation Error');
    });

    it('should reject invalid username with special characters', async () => {
      const response = await request(app)
        .put('/hello/user-name')
        .send({ dateOfBirth: '1990-01-01' });

      expect(response.status).toBe(400);
    });

    it('should reject future date', async () => {
      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + 1);
      const futureDateStr = futureDate.toISOString().split('T')[0];

      const response = await request(app)
        .put('/hello/charlie')
        .send({ dateOfBirth: futureDateStr });

      expect(response.status).toBe(400);
    });

    it('should reject today date', async () => {
      const today = new Date().toISOString().split('T')[0];

      const response = await request(app)
        .put('/hello/david')
        .send({ dateOfBirth: today });

      expect(response.status).toBe(400);
    });

    it('should reject invalid date format', async () => {
      const response = await request(app)
        .put('/hello/eve')
        .send({ dateOfBirth: '01-01-1990' });

      expect(response.status).toBe(400);
    });

    it('should reject missing dateOfBirth', async () => {
      const response = await request(app)
        .put('/hello/frank')
        .send({});

      expect(response.status).toBe(400);
    });
  });

  describe('GET /hello/:username', () => {
    it('should return birthday message for existing user', async () => {
      userModel.findByUsername.mockResolvedValue({
        username: 'testuser',
        date_of_birth: '1990-01-01'
      });

      const response = await request(app)
        .get('/hello/testuser');

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('message');
      expect(response.body.message).toMatch(/Hello, testuser!/);
    });

    it('should return 404 for non-existent user', async () => {
      userModel.findByUsername.mockResolvedValue(null);

      const response = await request(app)
        .get('/hello/nonexistentuser');

      expect(response.status).toBe(404);
      expect(response.body.error).toBe('User not found');
    });

    it('should return happy birthday message on birthday', async () => {
      const today = new Date();
      const birthYear = today.getFullYear() - 25;
      const birthday = `${birthYear}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`;

      userModel.findByUsername.mockResolvedValue({
        username: 'birthdayuser',
        date_of_birth: birthday
      });

      const response = await request(app)
        .get('/hello/birthdayuser');

      expect(response.status).toBe(200);
      expect(response.body.message).toBe('Hello, birthdayuser! Happy birthday!');
    });
  });

  describe('Health Endpoints', () => {
    it('should return 200 for liveness probe', async () => {
      const response = await request(app)
        .get('/health/live');

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('ok');
    });

    it('should return readiness status', async () => {
      const response = await request(app)
        .get('/health/ready');

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('ready');
      expect(response.body).toHaveProperty('database');
    });

    it('should return detailed health information', async () => {
      const response = await request(app)
        .get('/health');

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('uptime');
      expect(response.body).toHaveProperty('memory');
      expect(response.body).toHaveProperty('database');
    });
  });

  describe('Metrics Endpoint', () => {
    it('should return prometheus metrics', async () => {
      const response = await request(app)
        .get('/metrics');

      expect(response.status).toBe(200);
      expect(response.headers['content-type']).toMatch(/text\/plain/);
      expect(response.text).toContain('# HELP');
      expect(response.text).toContain('# TYPE');
    });
  });
}); 
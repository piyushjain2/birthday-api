# Development Guide

## Overview

This guide provides detailed information for developers working on the Birthday App, including setup instructions, coding standards, and best practices.

## Development Environment Setup

### Prerequisites

1. **Required Tools**
   - Node.js 18+
   - Docker and Docker Compose
   - PostgreSQL client
   - kubectl
   - AWS CLI
   - Terraform

2. **IDE Setup**
   - VS Code recommended
   - Extensions:
     - ESLint
     - Prettier
     - Docker
     - Kubernetes
     - Terraform

### Local Development

1. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd revolut
   ```

2. **Install Dependencies**
   ```bash
   npm install
   ```

3. **Environment Setup**
   ```bash
   cp env.example .env
   # Edit .env with your local settings
   ```

4. **Start Services**
   ```bash
   docker-compose up -d
   ```

## Code Structure

```
src/
├── config/         # Configuration files
├── controllers/    # Request handlers
├── models/         # Database models
├── routes/         # API routes
├── services/       # Business logic
├── utils/          # Utility functions
└── app.js          # Application entry point
```

## Coding Standards

### JavaScript/Node.js

1. **Style Guide**
   - Follow ESLint configuration
   - Use async/await for asynchronous code
   - Use meaningful variable names
   - Add JSDoc comments for functions

2. **Error Handling**
   ```javascript
   try {
     // Operation
   } catch (error) {
     logger.error('Operation failed', { error });
     throw new AppError('Operation failed', 500);
   }
   ```

3. **Logging**
   ```javascript
   const logger = require('./utils/logger');
   logger.info('Operation successful', { data });
   logger.error('Operation failed', { error });
   ```

### API Development

1. **Route Structure**
   ```javascript
   router.put('/hello/:username', validateRequest, async (req, res) => {
     // Handler logic
   });
   ```

2. **Validation**
   ```javascript
   const { validateRequest } = require('../middleware/validation');
   const { birthdaySchema } = require('../utils/validators');
   ```

3. **Error Responses**
   ```javascript
   res.status(400).json({
     error: 'Invalid input',
     details: validationErrors
   });
   ```

## Testing

### Unit Tests

1. **Test Structure**
   ```javascript
   describe('UserService', () => {
     it('should create a new user', async () => {
       // Test implementation
     });
   });
   ```

2. **Running Tests**
   ```bash
   npm run test:unit
   ```

### Integration Tests

1. **Test Setup**
   ```javascript
   beforeAll(async () => {
     // Setup test database
   });
   ```

2. **Running Tests**
   ```bash
   npm run test:integration
   ```

## Database

### Migrations

1. **Creating Migrations**
   ```bash
   npm run migrate:create -- --name add_user_table
   ```

2. **Running Migrations**
   ```bash
   npm run migrate:up
   ```

### Models

1. **Model Structure**
   ```javascript
   class User extends Model {
     static init(sequelize, DataTypes) {
       return super.init({
         // Model definition
       });
     }
   }
   ```

## Deployment

### Local Testing

1. **Build Docker Image**
   ```bash
   docker build -t birthday-app:local .
   ```

2. **Run Container**
   ```bash
   docker run -p 3000:3000 birthday-app:local
   ```

### Kubernetes Development

1. **Deploy to Minikube**
   ```bash
   kubectl apply -f k8s/base/
   ```

2. **Port Forward**
   ```bash
   kubectl port-forward svc/birthday-app 3000:80
   ```

## Monitoring and Logging

### Metrics

1. **Adding Metrics**
   ```javascript
   const prometheus = require('prom-client');
   const httpRequestDuration = new prometheus.Histogram({
     name: 'http_request_duration_seconds',
     help: 'Duration of HTTP requests in seconds'
   });
   ```

2. **Viewing Metrics**
   ```bash
   curl localhost:3000/metrics
   ```

### Logging

1. **Structured Logging**
   ```javascript
   logger.info('Request processed', {
     method: req.method,
     path: req.path,
     duration: duration
   });
   ```

## Troubleshooting

### Common Issues

1. **Database Connection**
   - Check PostgreSQL is running
   - Verify connection string
   - Check network connectivity

2. **Kubernetes Issues**
   - Check pod status
   - View pod logs
   - Check service endpoints

### Debugging Tools

1. **Node.js Debugging**
   ```bash
   node --inspect app.js
   ```

2. **Kubernetes Debugging**
   ```bash
   kubectl describe pod <pod-name>
   kubectl logs <pod-name>
   ```

## Best Practices

1. **Code Quality**
   - Write unit tests
   - Follow style guide
   - Document code
   - Use type checking

2. **Performance**
   - Use connection pooling
   - Implement caching
   - Optimize database queries
   - Monitor resource usage

3. **Security**
   - Validate all inputs
   - Use parameterized queries
   - Implement rate limiting
   - Follow security guidelines 
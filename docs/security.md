# Security Guide

## Overview

This document outlines the security measures implemented in the Birthday App, including infrastructure security, application security, and operational security practices.

## Infrastructure Security

### AWS Security

1. **VPC Configuration**
   - Private subnets for application and database
   - Public subnets for load balancers
   - Network ACLs and security groups
   - NAT Gateways for outbound traffic

2. **EKS Security**
   - IAM roles for service accounts
   - Pod security policies
   - Network policies
   - Encryption at rest

3. **Database Security**
   - Encrypted EBS volumes
   - SSL/TLS for connections
   - Regular security updates
   - Access control lists

### Kubernetes Security

1. **RBAC**
   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: Role
   metadata:
     namespace: birthday-app
     name: pod-reader
   rules:
   - apiGroups: [""]
     resources: ["pods"]
     verbs: ["get", "list"]
   ```

2. **Network Policies**
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: app-network-policy
   spec:
     podSelector:
       matchLabels:
         app: birthday-app
     policyTypes:
     - Ingress
     - Egress
     ingress:
     - from:
       - podSelector:
           matchLabels:
             app: birthday-app
     egress:
     - to:
       - podSelector:
           matchLabels:
             app: postgres
   ```

3. **Pod Security**
   - Non-root containers
   - Read-only root filesystem
   - Resource limits
   - Security context

## Application Security

### API Security

1. **Input Validation**
   ```javascript
   const { validateRequest } = require('../middleware/validation');
   const { birthdaySchema } = require('../utils/validators');

   router.put('/hello/:username', validateRequest(birthdaySchema), async (req, res) => {
     // Handler logic
   });
   ```

2. **Rate Limiting**
   ```javascript
   const rateLimit = require('express-rate-limit');

   const limiter = rateLimit({
     windowMs: 15 * 60 * 1000, // 15 minutes
     max: 100 // limit each IP to 100 requests per windowMs
   });

   app.use(limiter);
   ```

3. **CORS Configuration**
   ```javascript
   const cors = require('cors');

   app.use(cors({
     origin: process.env.ALLOWED_ORIGINS.split(','),
     methods: ['GET', 'PUT'],
     allowedHeaders: ['Content-Type']
   }));
   ```

### Data Security

1. **Database Security**
   - Parameterized queries
   - Connection pooling
   - SSL/TLS encryption
   - Regular backups

2. **Secrets Management**
   ```javascript
   const { SecretsManager } = require('aws-sdk');
   const secretsManager = new SecretsManager();

   async function getSecret(secretName) {
     const data = await secretsManager.getSecretValue({ SecretId: secretName }).promise();
     return JSON.parse(data.SecretString);
   }
   ```

3. **Data Encryption**
   - TLS for data in transit
   - EBS encryption for data at rest
   - S3 encryption for backups

## Operational Security

### Monitoring and Logging

1. **Security Logging**
   ```javascript
   const logger = require('./utils/logger');

   logger.info('Security event', {
     event: 'login_attempt',
     user: username,
     ip: req.ip,
     success: success
   });
   ```

2. **Audit Logging**
   - Database access logs
   - API access logs
   - Infrastructure changes
   - Security events

### Incident Response

1. **Detection**
   - Security monitoring
   - Alert thresholds
   - Anomaly detection
   - Regular audits

2. **Response Plan**
   - Incident classification
   - Response procedures
   - Communication plan
   - Recovery steps

### Compliance

1. **Data Protection**
   - GDPR compliance
   - Data retention policies
   - Data deletion procedures
   - Privacy by design

2. **Security Standards**
   - OWASP guidelines
   - AWS security best practices
   - Kubernetes security standards
   - Industry compliance

## Security Testing

### Vulnerability Scanning

1. **Container Scanning**
   ```bash
   trivy image birthday-app:latest
   ```

2. **Dependency Scanning**
   ```bash
   npm audit
   ```

### Penetration Testing

1. **API Testing**
   - Authentication testing
   - Authorization testing
   - Input validation testing
   - Rate limiting testing

2. **Infrastructure Testing**
   - Network security testing
   - Kubernetes security testing
   - AWS security testing
   - Database security testing

## Security Updates

### Patch Management

1. **Application Updates**
   - Regular dependency updates
   - Security patch deployment
   - Version control
   - Change management

2. **Infrastructure Updates**
   - Kubernetes version updates
   - Node group updates
   - Security group updates
   - IAM policy updates

### Security Maintenance

1. **Regular Tasks**
   - Security group review
   - IAM role audit
   - Certificate rotation
   - Secret rotation

2. **Documentation**
   - Security procedures
   - Incident response
   - Compliance documentation
   - Security architecture

## Best Practices

1. **Code Security**
   - Regular security reviews
   - Secure coding guidelines
   - Dependency management
   - Error handling

2. **Infrastructure Security**
   - Least privilege principle
   - Defense in depth
   - Regular audits
   - Security automation

3. **Operational Security**
   - Security training
   - Incident response drills
   - Regular backups
   - Disaster recovery testing 
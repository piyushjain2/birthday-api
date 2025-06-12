# Infrastructure Documentation

## Overview

This document describes the infrastructure setup for the Birthday App, which is deployed on AWS EKS with a highly available PostgreSQL database.

## Architecture

The infrastructure consists of the following components:

1. **VPC and Networking**
   - VPC with public and private subnets across multiple availability zones
   - NAT Gateways for private subnet internet access
   - Security groups for controlling traffic

2. **EKS Cluster**
   - Managed Kubernetes cluster
   - Node groups with auto-scaling
   - IAM roles and policies for cluster and node access

3. **PostgreSQL Database**
   - StatefulSet deployment with multiple replicas
   - Persistent storage using EBS volumes
   - Automatic failover and replication
   - Headless service for pod discovery

4. **Application Deployment**
   - Node.js application deployment
   - ConfigMaps for environment variables
   - Ingress controller for external access
   - Health checks and monitoring

## High Availability

The infrastructure is designed for high availability with the following features:

1. **Multi-AZ Deployment**
   - Resources spread across multiple availability zones
   - Automatic failover in case of zone failure

2. **Database Replication**
   - PostgreSQL replicas in different availability zones
   - Automatic failover using StatefulSet
   - Data persistence using EBS volumes

3. **Application Scaling**
   - Multiple application replicas
   - Rolling updates for zero-downtime deployments
   - Auto-scaling based on load

## Deployment Process

1. **Infrastructure Setup**
   ```bash
   # Initialize Terraform
   terraform init

   # Plan the deployment
   terraform plan -var-file=environments/prod.tfvars

   # Apply the changes
   terraform apply -var-file=environments/prod.tfvars
   ```

2. **Application Deployment**
   ```bash
   # Deploy the application
   ./scripts/deploy.sh
   ```

## Monitoring and Maintenance

1. **Health Checks**
   - Application health endpoint: `/health`
   - Database health checks using `pg_isready`
   - Kubernetes liveness and readiness probes

2. **Logging**
   - Application logs via Kubernetes logging
   - Database logs via StatefulSet
   - CloudWatch integration for AWS services

3. **Backup and Recovery**
   - Regular database backups
   - EBS volume snapshots
   - Terraform state backup in S3

## Security

1. **Network Security**
   - Private subnets for database and application
   - Security groups for traffic control
   - SSL/TLS for all external communications

2. **Access Control**
   - IAM roles for AWS services
   - Kubernetes RBAC
   - Database user permissions

3. **Secrets Management**
   - Kubernetes secrets for sensitive data
   - AWS Secrets Manager integration
   - Encrypted storage for database

## Disaster Recovery

1. **Backup Strategy**
   - Daily database backups
   - EBS volume snapshots
   - Terraform state backups

2. **Recovery Process**
   - Database restore from backups
   - Infrastructure recreation using Terraform
   - Application redeployment

## Cost Optimization

1. **Resource Management**
   - Auto-scaling for dynamic workloads
   - Spot instances for non-critical workloads
   - Resource limits and requests

2. **Storage Optimization**
   - EBS volume sizing
   - Database cleanup policies
   - Log rotation

## Maintenance Tasks

1. **Regular Updates**
   - Kubernetes version updates
   - Node group updates
   - Application updates

2. **Monitoring**
   - Resource usage monitoring
   - Performance metrics
   - Cost tracking

## Troubleshooting

1. **Common Issues**
   - Database connection issues
   - Application deployment failures
   - Network connectivity problems

2. **Debugging Tools**
   - kubectl commands
   - PostgreSQL logs
   - AWS CloudWatch logs 
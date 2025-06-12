# Monitoring Documentation

## Overview

The Birthday App uses Prometheus and Grafana for comprehensive monitoring and alerting. This document describes the monitoring setup, available metrics, and how to use the monitoring tools.

## Monitoring Stack

### Components

1. **Prometheus**
   - Metrics collection and storage
   - Alert rule evaluation
   - Service discovery
   - 15-day data retention
   - 50Gi storage capacity

2. **Grafana**
   - Metrics visualization
   - Custom dashboards
   - Alert notifications
   - 10Gi storage capacity
   - LoadBalancer service type

3. **Alertmanager**
   - Alert routing
   - Deduplication
   - Silencing
   - 10Gi storage capacity
   - 120-hour alert retention

## Available Metrics

### Application Metrics

1. **HTTP Metrics**
   - `http_requests_total`: Total number of HTTP requests
   - `http_request_duration_seconds`: Request duration histogram
   - `http_requests_in_flight`: Current number of requests being served

2. **Database Metrics**
   - `pg_up`: Database connection status
   - `pg_stat_activity_count`: Number of active connections
   - `pg_stat_database_tup_returned`: Number of rows returned
   - `pg_stat_database_tup_fetched`: Number of rows fetched

3. **System Metrics**
   - `process_cpu_seconds_total`: CPU usage
   - `process_resident_memory_bytes`: Memory usage
   - `node_memory_MemTotal_bytes`: Total system memory
   - `node_cpu_seconds_total`: CPU time spent

## Alerting Rules

### Application Alerts

1. **High Error Rate**
   - Trigger: Error rate > 5% for 5 minutes
   - Severity: Warning
   - Description: High HTTP error rate detected

2. **High Latency**
   - Trigger: 95th percentile latency > 1 second for 5 minutes
   - Severity: Warning
   - Description: High response time detected

3. **Database Connection Issues**
   - Trigger: Database connection down for 1 minute
   - Severity: Critical
   - Description: Cannot connect to PostgreSQL

## Grafana Dashboards

### Birthday App Dashboard

1. **Request Metrics**
   - Request rate by endpoint
   - Error rate by endpoint
   - Response time percentiles
   - HTTP status code distribution

2. **Database Metrics**
   - Active connections
   - Query performance
   - Replication lag
   - Connection pool status

3. **System Metrics**
   - CPU usage
   - Memory usage
   - Disk I/O
   - Network traffic

## Accessing Monitoring Tools

### Prometheus

1. **Local Access**
   ```bash
   kubectl port-forward -n monitoring svc/prometheus 9090:9090
   ```
   Then visit: http://localhost:9090

2. **Direct Access**
   ```bash
   kubectl get svc -n monitoring prometheus
   ```

### Grafana

1. **Local Access**
   ```bash
   kubectl port-forward -n monitoring svc/grafana 3000:3000
   ```
   Then visit: http://localhost:3000

2. **Direct Access**
   ```bash
   kubectl get svc -n monitoring grafana
   ```

## Adding Custom Metrics

1. **Application Metrics**
   ```javascript
   const prometheus = require('prom-client');
   const httpRequestDuration = new prometheus.Histogram({
     name: 'http_request_duration_seconds',
     help: 'Duration of HTTP requests in seconds',
     labelNames: ['method', 'route', 'status_code']
   });
   ```

2. **Custom Dashboard**
   - Access Grafana
   - Create new dashboard
   - Add panels using PromQL queries
   - Save dashboard

## Troubleshooting

### Common Issues

1. **Metrics Not Showing**
   - Check ServiceMonitor configuration
   - Verify metrics endpoint is accessible
   - Check Prometheus targets

2. **Alerts Not Firing**
   - Verify alert rules
   - Check Alertmanager configuration
   - Verify notification channels

3. **High Resource Usage**
   - Check retention settings
   - Verify scrape intervals
   - Monitor storage usage

### Useful Commands

```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus 9090:9090
curl localhost:9090/api/v1/targets

# Check Alertmanager status
kubectl port-forward -n monitoring svc/alertmanager 9093:9093
curl localhost:9093/api/v2/status

# View Grafana logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana
```

## Best Practices

1. **Resource Management**
   - Set appropriate retention periods
   - Configure resource limits
   - Monitor storage usage

2. **Alert Management**
   - Use meaningful alert names
   - Set appropriate thresholds
   - Configure proper severity levels

3. **Dashboard Design**
   - Use consistent naming
   - Include relevant metrics
   - Add helpful descriptions 
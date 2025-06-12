resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# Prometheus Operator
resource "helm_release" "prometheus_operator" {
  name       = "prometheus-operator"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "45.7.1"

  values = [
    <<-EOT
    prometheus:
      prometheusSpec:
        retention: 15d
        resources:
          requests:
            cpu: 200m
            memory: 1Gi
          limits:
            cpu: 1000m
            memory: 2Gi
        storageSpec:
          volumeClaimTemplate:
            spec:
              accessModes: ["ReadWriteOnce"]
              storageClassName: "gp3"
              resources:
                requests:
                  storage: 50Gi
        serviceMonitorSelectorNilUsesHelmValues: false
        serviceMonitorNamespaceSelector: {}
        serviceMonitorSelector: {}
        podMonitorSelectorNilUsesHelmValues: false
        podMonitorNamespaceSelector: {}
        podMonitorSelector: {}
        ruleSelectorNilUsesHelmValues: false
        ruleNamespaceSelector: {}
        ruleSelector: {}
    grafana:
      adminPassword: ${var.grafana_admin_password}
      persistence:
        enabled: true
        storageClassName: "gp3"
        size: 10Gi
      resources:
        requests:
          cpu: 100m
          memory: 256Mi
        limits:
          cpu: 500m
          memory: 512Mi
      service:
        type: LoadBalancer
    alertmanager:
      alertmanagerSpec:
        retention: 120h
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 200m
            memory: 512Mi
        storage:
          volumeClaimTemplate:
            spec:
              accessModes: ["ReadWriteOnce"]
              storageClassName: "gp3"
              resources:
                requests:
                  storage: 10Gi
    EOT
  ]
}

# ServiceMonitor for the application
resource "kubernetes_manifest" "service_monitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "birthday-app"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      labels = {
        release = "prometheus-operator"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = "birthday-app"
        }
      }
      namespaceSelector = {
        matchNames = ["birthday-app"]
      }
      endpoints = [
        {
          port     = "metrics"
          interval = "15s"
          path     = "/metrics"
        }
      ]
    }
  }
}

# PrometheusRule for application alerts
resource "kubernetes_manifest" "prometheus_rule" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "birthday-app-alerts"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      labels = {
        release = "prometheus-operator"
      }
    }
    spec = {
      groups = [
        {
          name  = "birthday-app"
          rules = [
            {
              alert = "HighErrorRate"
              expr  = "rate(http_requests_total{status=~\"5..\"}[5m]) / rate(http_requests_total[5m]) > 0.05"
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "High error rate detected"
                description = "Error rate is above 5% for the last 5 minutes"
              }
            },
            {
              alert = "HighLatency"
              expr  = "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1"
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "High latency detected"
                description = "95th percentile latency is above 1 second for the last 5 minutes"
              }
            },
            {
              alert = "DatabaseConnectionIssues"
              expr  = "pg_up == 0"
              for   = "1m"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary     = "Database connection issues"
                description = "Cannot connect to PostgreSQL database"
              }
            }
          ]
        }
      ]
    }
  }
}

# Grafana Dashboard for the application
resource "kubernetes_config_map" "grafana_dashboard" {
  metadata {
    name      = "birthday-app-dashboard"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      grafana_dashboard = "true"
    }
  }

  data = {
    "birthday-app.json" = jsonencode({
      annotations = {
        list = []
      }
      editable = true
      graphTooltip = 0
      id = null
      links = []
      panels = [
        {
          title = "Request Rate"
          type = "graph"
          targets = [
            {
              expr = "rate(http_requests_total[5m])"
              legendFormat = "{{method}} {{path}}"
            }
          ]
        },
        {
          title = "Error Rate"
          type = "graph"
          targets = [
            {
              expr = "rate(http_requests_total{status=~\"5..\"}[5m])"
              legendFormat = "{{method}} {{path}}"
            }
          ]
        },
        {
          title = "Response Time"
          type = "graph"
          targets = [
            {
              expr = "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))"
              legendFormat = "{{method}} {{path}}"
            }
          ]
        },
        {
          title = "Database Connections"
          type = "gauge"
          targets = [
            {
              expr = "pg_stat_activity_count"
            }
          ]
        }
      ]
      refresh = "10s"
      schemaVersion = 27
      style = "dark"
      tags = []
      templating = {
        list = []
      }
      time = {
        from = "now-6h"
        to = "now"
      }
      timepicker = {}
      timezone = ""
      title = "Birthday App Dashboard"
      uid = "birthday-app"
      version = 1
    })
  }
}

output "grafana_url" {
  value = "http://${helm_release.prometheus_operator.name}-grafana.${kubernetes_namespace.monitoring.metadata[0].name}.svc.cluster.local"
}

output "prometheus_url" {
  value = "http://${helm_release.prometheus_operator.name}-prometheus.${kubernetes_namespace.monitoring.metadata[0].name}.svc.cluster.local"
} 
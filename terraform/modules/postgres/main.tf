resource "kubernetes_storage_class" "postgres" {
  metadata {
    name = "postgres-storage"
  }

  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy     = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"

  parameters = {
    type = "gp3"
    encrypted = "true"
    iopsPerGB = "3000"
    throughputPerGB = "125"
  }
}

resource "kubernetes_persistent_volume_claim" "postgres" {
  count = var.replicas

  metadata {
    name      = "postgres-data-${count.index}"
    namespace = kubernetes_namespace.postgres.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    storage_class_name = kubernetes_storage_class.postgres.metadata[0].name
    resources {
      requests = {
        storage = var.storage_size
      }
    }
  }
}

resource "kubernetes_namespace" "postgres" {
  metadata {
    name = "postgres"
  }
}

resource "kubernetes_config_map" "postgres" {
  metadata {
    name      = "postgres-config"
    namespace = kubernetes_namespace.postgres.metadata[0].name
  }

  data = {
    POSTGRES_DB       = "birthday_db"
    POSTGRES_USER     = var.db_user
    POSTGRES_PASSWORD = var.db_password
    PGDATA           = "/var/lib/postgresql/data/pgdata"
    POSTGRES_INITDB_ARGS = "--data-checksums"
    POSTGRES_HOST_AUTH_METHOD = "scram-sha-256"
  }
}

resource "kubernetes_stateful_set" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.postgres.metadata[0].name
  }

  spec {
    service_name = "postgres"
    replicas     = var.replicas

    selector {
      match_labels = {
        app = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }

      spec {
        container {
          name  = "postgres"
          image = "postgres:15-alpine"

          port {
            container_port = 5432
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.postgres.metadata[0].name
            }
          }

          volume_mount {
            name       = "postgres-data"
            mount_path = "/var/lib/postgresql/data"
          }

          resources {
            requests = {
              cpu    = "500m"
              memory = "1Gi"
            }
            limits = {
              cpu    = "1000m"
              memory = "2Gi"
            }
          }

          liveness_probe {
            exec {
              command = ["pg_isready", "-U", var.db_user]
            }
            initial_delay_seconds = 30
            period_seconds       = 10
            timeout_seconds      = 5
            failure_threshold    = 3
          }

          readiness_probe {
            exec {
              command = ["pg_isready", "-U", var.db_user]
            }
            initial_delay_seconds = 5
            period_seconds       = 5
            timeout_seconds      = 3
            failure_threshold    = 3
          }

          startup_probe {
            exec {
              command = ["pg_isready", "-U", var.db_user]
            }
            initial_delay_seconds = 30
            period_seconds       = 10
            timeout_seconds      = 5
            failure_threshold    = 30
          }
        }

        affinity {
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 100
              pod_affinity_term {
                label_selector {
                  match_expressions {
                    key = "app"
                    operator = "In"
                    values = ["postgres"]
                  }
                }
                topology_key = "kubernetes.io/hostname"
              }
            }
          }
        }

        toleration {
          key = "dedicated"
          operator = "Equal"
          value = "database"
          effect = "NoSchedule"
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "postgres-data"
      }

      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = kubernetes_storage_class.postgres.metadata[0].name
        resources {
          requests = {
            storage = var.storage_size
          }
        }
      }
    }

    update_strategy {
      type = "RollingUpdate"
      rolling_update {
        partition = 0
      }
    }
  }
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.postgres.metadata[0].name
  }

  spec {
    selector = {
      app = "postgres"
    }

    port {
      port        = 5432
      target_port = 5432
    }

    cluster_ip = "None" # Headless service for StatefulSet
  }
}

resource "kubernetes_service" "postgres_read" {
  metadata {
    name      = "postgres-read"
    namespace = kubernetes_namespace.postgres.metadata[0].name
  }

  spec {
    selector = {
      app = "postgres"
      statefulset.kubernetes.io/pod-name = "postgres-1" # Read replica
    }

    port {
      port        = 5432
      target_port = 5432
    }
  }
}

output "endpoint" {
  value = "postgres.${kubernetes_namespace.postgres.metadata[0].name}.svc.cluster.local"
}

output "read_endpoint" {
  value = "postgres-read.${kubernetes_namespace.postgres.metadata[0].name}.svc.cluster.local"
} 
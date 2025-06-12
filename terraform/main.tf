# VPC and Networking
module "vpc" {
  source = "./modules/vpc"

  environment     = var.environment
  vpc_cidr       = var.vpc_cidr
  azs            = var.availability_zones
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs
}

# EKS Cluster
module "eks" {
  source = "./modules/eks"

  cluster_name    = "${var.environment}-birthday-app"
  cluster_version = "1.27"
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnet_ids

  node_groups = {
    general = {
      desired_size = 2
      min_size     = 1
      max_size     = 4
      instance_types = ["t3.medium"]
    }
  }
}

# PostgreSQL StatefulSet
module "postgres" {
  source = "./modules/postgres"

  environment     = var.environment
  cluster_name    = module.eks.cluster_name
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnet_ids
  storage_size   = "20Gi"
  replicas       = 3
}

# Application Deployment
module "app" {
  source = "./modules/app"

  environment     = var.environment
  cluster_name    = module.eks.cluster_name
  app_name        = "birthday-app"
  app_image       = var.app_image
  app_replicas    = 3
  db_host         = module.postgres.endpoint
  db_name         = "birthday_db"
  db_user         = var.db_user
  db_password     = var.db_password
}

module "monitoring" {
  source = "./modules/monitoring"

  environment            = var.environment
  grafana_admin_password = var.grafana_admin_password
  prometheus_retention   = var.prometheus_retention
  prometheus_storage_size = var.prometheus_storage_size
  grafana_storage_size   = var.grafana_storage_size
  alertmanager_storage_size = var.alertmanager_storage_size

  depends_on = [
    module.eks
  ]
}
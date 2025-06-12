environment = "prod"
aws_region  = "us-west-2"

vpc_cidr = "10.0.0.0/16"
availability_zones = [
  "us-west-2a",
  "us-west-2b",
  "us-west-2c"
]

private_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24",
  "10.0.3.0/24"
]

public_subnet_cidrs = [
  "10.0.101.0/24",
  "10.0.102.0/24",
  "10.0.103.0/24"
]

app_image    = "your-registry/birthday-app:latest"
app_replicas = 3

postgres_replicas = 3
storage_size     = "50Gi"

# These values should be provided securely, e.g., through AWS Secrets Manager
# db_user     = "your-db-user"
# db_password = "your-db-password" 
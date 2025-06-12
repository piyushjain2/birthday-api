variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "storage_size" {
  description = "Size of PostgreSQL storage"
  type        = string
  default     = "20Gi"
}

variable "replicas" {
  description = "Number of PostgreSQL replicas"
  type        = number
  default     = 3
}

variable "db_user" {
  description = "PostgreSQL database user"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "PostgreSQL database password"
  type        = string
  sensitive   = true
} 
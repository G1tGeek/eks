# Network remote state S3 config
variable "network_remote_state_bucket" {
  description = "S3 bucket where network module terraform.tfstate is stored"
  type        = string
}

variable "network_remote_state_key" {
  description = "S3 key path for the network module terraform.tfstate"
  type        = string
}

variable "network_remote_state_region" {
  description = "AWS region where the S3 bucket is located"
  type        = string
}

# RDS variables
variable "vpc_id" {
  description = "VPC ID where RDS will be deployed (override remote state)"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for RDS (override remote state)"
  type        = list(string)
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database master username"
  type        = string
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "db_engine" {
  description = "RDS engine (e.g., mysql, postgres)"
  type        = string
}

variable "db_engine_version" {
  description = "RDS engine version (e.g., 8.0, 13.7)"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class (e.g., db.t3.micro)"
  type        = string
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
}

variable "rds_secret_name" {
  description = "Secrets Manager secret name to store RDS credentials (optional)"
  type        = string
}

variable "tags" {
  description = "Tags for RDS resources"
  type        = map(string)
}

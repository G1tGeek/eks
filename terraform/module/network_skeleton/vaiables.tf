###########################
# Provider / general
###########################

variable "aws_region" {
  description = "AWS region to create resources in (e.g. us-east-1)."
  type        = string
}

variable "environment" {
  description = "Environment name used to prefix resource names (e.g. dev/stage/prod)."
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to resources."
  type        = map(string)
  default     = {}
}

###########################
# VPC / subnets
###########################

variable "vpc_cidr" {
  description = "CIDR block for the VPC (e.g. 10.0.0.0/16)."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr)) && can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\/\\d{1,2}$", var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR (e.g. 10.0.0.0/16)."
  }
}

variable "public_subnets" {
  description = "List of CIDR blocks for public subnets (order used for AZ distribution). Example: [\"10.0.0.0/24\",\"10.0.2.0/24\"]"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "List of CIDR blocks for private subnets (order used for AZ distribution). Example: [\"10.0.1.0/24\",\"10.0.3.0/24\"]"
  type        = list(string)
  default     = []
}

###########################
# Keypair helper (null_resource)
###########################

variable "key_name" {
  description = "Name of EC2 keypair (used by helper script and by nodegroup.remote_access.ec2_ssh_key)."
  type        = string
  default     = ""
}

variable "keypair_s3_bucket" {
  description = "Optional S3 bucket where the key.sh helper stores key material."
  type        = string
  default     = ""
}

###########################
# EKS cluster
###########################

variable "cluster_name" {
  description = "Optional EKS cluster name. If empty module derives one from 'environment'."
  type        = string
  default     = ""
}

variable "cluster_endpoint_public_access" {
  description = "Whether the EKS API endpoint should be publicly accessible."
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Whether the EKS API endpoint should be accessible from within the VPC."
  type        = bool
  default     = false
}

variable "cluster_public_access_cidrs" {
  description = "List of CIDRs allowed to access the public EKS API endpoint when public access is enabled."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

###########################
# Node group
###########################

variable "node_group_name" {
  description = "Name for the managed node group (optional)."
  type        = string
  default     = ""
}

variable "node_subnet_ids" {
  description = "Optional list of subnet IDs for nodegroup. If empty, module uses private subnets created here."
  type        = list(string)
  default     = []
}

variable "node_desired_capacity" {
  description = "Desired number of nodes in the managed node group."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of nodes in the managed node group."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of nodes in the managed node group."
  type        = number
  default     = 4
}

variable "node_instance_types" {
  description = "List of EC2 instance types for the node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_ami_type" {
  description = "AMI type for the managed node group (e.g. AL2_x86_64)."
  type        = string
  default     = "AL2_x86_64"
}

variable "node_disk_size" {
  description = "Root disk size (GB) for nodes."
  type        = number
  default     = 20
}

###########################
# Node SSH / SSM access
###########################

variable "node_ssh_source_security_group_ids" {
  description = "List of security group IDs allowed to SSH into nodes (used by nodegroup.remote_access.source_security_group_ids). Example: [aws_security_group.bastion.id]"
  type        = list(string)
  default     = []
}

variable "attach_ssm_policy" {
  description = "If true, attach AmazonSSMManagedInstanceCore to node role to allow Session Manager access to nodes."
  type        = bool
  default     = false
}

###########################
# RDS / DB variables
###########################

variable "rds_sg_name" {
  description = "Optional name for security group the module creates for RDS."
  type        = string
  default     = ""
}

variable "db_allowed_source_security_group_ids" {
  description = "List of security group IDs that should be allowed to access the DB (module will create ingress rules permitting var.db_port)."
  type        = list(string)
  default     = []
}

variable "db_allowed_cidr_blocks" {
  description = "List of CIDR blocks to allow DB access from (module will create ingress rules permitting var.db_port)."
  type        = list(string)
  default     = []
}

variable "egress_cidr_blocks" {
  description = "Default egress CIDR blocks for the RDS security group (module default allows 0.0.0.0/0)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "db_subnet_group_name" {
  description = "Optional RDS subnet group name."
  type        = string
  default     = ""
}

variable "db_subnet_ids" {
  description = "Optional list of subnet IDs to use for RDS subnet group. If empty the module uses the private subnets defined here."
  type        = list(string)
  default     = []
}

variable "db_identifier" {
  description = "Optional DB instance identifier. If empty derived from environment."
  type        = string
  default     = ""
}

variable "db_engine" {
  description = "RDS engine (e.g. mysql, postgres)."
  type        = string
  default     = "mysql"
}

variable "db_engine_version" {
  description = "Optional RDS engine version (e.g. 8.0). Leave empty for provider defaults."
  type        = string
  default     = ""
}

variable "db_instance_class" {
  description = "RDS instance class (e.g. db.t3.micro)."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Size of the RDS storage in GB."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial DB name to create (optional)."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for the DB."
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Master password for the DB. Mark this sensitive in your wrapper."
  type        = string
  sensitive   = true
  default     = ""
}

variable "db_port" {
  description = "DB listening port (e.g. 3306 for MySQL, 5432 for Postgres)."
  type        = number
  default     = 3306
}

variable "db_vpc_security_group_ids" {
  description = "Optional list of security group IDs to attach to the DB. If empty the module creates/uses its own RDS SG."
  type        = list(string)
  default     = []
}

variable "db_multi_az" {
  description = "Whether to enable RDS multi-AZ deployment."
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Whether to skip final snapshot on DB deletion. Set false for production (to preserve data)."
  type        = bool
  default     = true
}

variable "db_deletion_protection" {
  description = "If true, prevents RDS instance deletion (safety for prod)."
  type        = bool
  default     = false
}

variable "db_apply_immediately" {
  description = "Whether to apply DB modifications immediately."
  type        = bool
  default     = false
}

variable "db_backup_retention" {
  description = "Days to retain backups."
  type        = number
  default     = 7
}

variable "db_backup_window" {
  description = "Preferred backup window (UTC). Example: 03:00-03:30"
  type        = string
  default     = "03:00-03:30"
}

variable "db_maintenance_window" {
  description = "Preferred maintenance window (UTC). Example: sun:04:00-sun:04:30"
  type        = string
  default     = "sun:04:00-sun:04:30"
}

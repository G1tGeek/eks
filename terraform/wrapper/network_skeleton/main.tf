
# Minimal locals for the wrapper
locals {
  environment = "dev"
  name_prefix = "${local.environment}-"

  # VPC CIDR for this environment
  vpc_cidr = "10.0.0.0/25"

  # Simple public/private subnets (one per AZ in this minimal example)
  public_subnets  = ["10.0.0.0/28", "10.0.0.16/28"]
  private_subnets = ["10.0.0.32/27", "10.0.0.64/28"]

  # Basic tags
  tags = {
    Application = "OTMS"
    Owner       = "Yuvraj"
    Environment = local.environment
  }
}

# Call the module with only required/minimal inputs.
module "network_skeleton" {
  source = "git::https://github.com/snaatak-Downtime-Crew/terraform-modules.git//network-skeleton?ref=main"

  # Provider / generic
  aws_region = "us-west-1"
  environment = local.environment
  tags        = local.tags

  # VPC & subnets
  vpc_cidr        = local.vpc_cidr
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets

  # Keypair helper (optional; keep if you use your key.sh)
  key_name          = "otms"
  keypair_s3_bucket = "snaatak-p14-tfstatefiles"

  # EKS minimal settings (module has sensible defaults for omitted values)
  cluster_name                      = "${local.name_prefix}otms-cluster"
  cluster_endpoint_public_access    = true
  cluster_endpoint_private_access   = false
  cluster_public_access_cidrs       = ["0.0.0.0/0"]

  # Node group - defaults in module are fine, but passing concise values here
  node_group_name                   = "${local.name_prefix}nodes"
  node_desired_capacity             = 2
  node_min_size                     = 1
  node_max_size                     = 3
  node_instance_types               = ["t3.medium"]
  node_ami_type                     = "AL2_x86_64"
  node_disk_size                    = 20

  # SSH sources for nodes (empty = no SSH permitted). Provide SG IDs if you want SSH.
  node_ssh_source_security_group_ids = []

  # Attach SSM policy to node role? (recommended for secure access)
  attach_ssm_policy = true

  # RDS minimal inputs: keep DB password out of this file; pass by secure tfvars instead
  db_engine                          = "mysql"
  db_instance_class                  = "db.t3.micro"
  db_allocated_storage               = 20
  db_name                            = "appdb"
  db_username                        = "admin"
  # db_password should be set via terraform.tfvars or remote state secrets
  db_password                        = ""   # <-- set securely outside this file
  db_port                            = 3306
  db_allowed_cidr_blocks             = [local.vpc_cidr]  # allow DB access from VPC
  db_vpc_security_group_ids          = []                # let module create SG by default
  db_multi_az                        = false
  db_skip_final_snapshot             = true
  db_deletion_protection             = false
  db_apply_immediately               = false
  db_backup_retention                = 7
  db_backup_window                   = "03:00-03:30"
  db_maintenance_window              = "sun:04:00-sun:04:30"
}

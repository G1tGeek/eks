# ----------------------------
# Locals
# -----------------------------
locals {
  environment = "eks"
  name_prefix = "${local.environment}-"

  # VPC CIDR for this environment
  vpc_cidr = "10.0.0.0/25"

  # Simple public/private subnets (one per AZ in this minimal example)
  public_subnets  = ["10.0.0.0/28", "10.0.0.16/28"]
  private_subnets = ["10.0.0.32/27", "10.0.0.64/28"]

  # Basic tags
  tags = {
    Application = "EKS"
    Owner       = "Yuvraj"
    Environment = local.environment
  }
}

# -----------------------------
# Network Skeleton Module
# -----------------------------
module "network_skeleton" {
  source = "git::https://github.com/G1tGeek/eks.git//terraform/module/network_skeleton?ref=main"

  # checkov:skip=CKV_TF_1: Skipping commit hash pinning check
  # checkov:skip=CKV_TF_2: Skipping tag pinning check

  # Provider / generic
  aws_region  = "ap-northeast-1"
  environment = local.environment
  tags        = local.tags

  # VPC & subnets
  vpc_cidr        = local.vpc_cidr
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets

  key_name          = "eks"
  keypair_s3_bucket = "yuvraj-opstree"
}

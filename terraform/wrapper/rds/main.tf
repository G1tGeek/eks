module "rds" {
  source = "git::https://github.com/G1tGeek/eks.git//terraform/module/rds?ref=main"

  # checkov:skip=CKV_TF_1: Skipping commit hash pinning check
  # checkov:skip=CKV_TF_2: Skipping tag pinning check

  # -----------------------------
  # Network remote state S3 info
  # -----------------------------
  network_remote_state_bucket = "yuvraj-opstree"
  network_remote_state_key    = "modules/network-skeleton/terraform.tfstate"
  network_remote_state_region = "ap-northeast-1"

  # -----------------------------
  vpc_id             = ""   # use network remote state VPC
  private_subnet_ids = []   # use network remote state private subnets
  account_id  = "130830900133"
  # -----------------------------
  # RDS configuration
  # -----------------------------
  db_name           = "mydb"
  db_engine         = "mysql"
  db_engine_version = "8.0"
  db_instance_class = "db.t3.micro"
  multi_az          = false

  # -----------------------------
  # Secrets Manager secret
  # -----------------------------
  rds_secret_name = "eks/yuvraj/rds"

  # -----------------------------
  # Tags
  # -----------------------------
  tags = {
    Environment = "dev"
    Project     = "eks-demo"
  }
}

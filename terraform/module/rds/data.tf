data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = var.network_remote_state_bucket
    key    = var.network_remote_state_key
    region = var.network_remote_state_region
  }
}

data "aws_secretsmanager_secret_version" "rds" {
  count     = var.rds_secret_name != "" ? 1 : 0
  secret_id = var.rds_secret_name
}

locals {
  rds_credentials = var.rds_secret_name != "" ? jsondecode(data.aws_secretsmanager_secret_version.rds[0].secret_string) : {}
}

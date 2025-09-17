# Fetch network module outputs from S3
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.network_s3_bucket
    key    = var.network_s3_key
    region = var.aws_region
  }
}

# Fetch the private key (PEM) from S3 for node group SSH access
data "aws_s3_object" "node_key" {
  bucket = var.network_s3_bucket
  key    = "${var.environment}/key-pair/${var.key_name}.pem"
}

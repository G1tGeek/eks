# -----------------------------
# Security Group for RDS
# -----------------------------
resource "aws_security_group" "rds_sg" {
  name        = "${var.db_name}-sg"
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id != "" ? var.vpc_id : data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    description = "Allow MySQL traffic from VPC CIDR"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/25"]
  }

  egress {
    description = "Restrict egress to VPC CIDR"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/25"]
  }

  tags = merge(var.tags, { Name = "${var.db_name}-sg" })
}

# -----------------------------
# DB Subnet Group
# -----------------------------
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.db_name}-subnet-group"
  subnet_ids = length(var.private_subnet_ids) > 0 ? var.private_subnet_ids : data.terraform_remote_state.network.outputs.private_subnet_ids
  tags       = merge(var.tags, { Name = "${var.db_name}-subnet-group" })
}

# -----------------------------
# IAM Role for Enhanced Monitoring
# -----------------------------
resource "aws_iam_role" "rds_monitoring" {
  name               = "${var.db_name}-rds-monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.rds_monitoring_assume.json
}

data "aws_iam_policy_document" "rds_monitoring_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_attach" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# -----------------------------
# KMS Key for RDS
# -----------------------------
resource "aws_kms_key" "rds" {
  description             = "KMS CMK for RDS storage and Performance Insights"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1"
    Statement = [
      {
        Sid       = "AllowRootAccountFullAccess"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid       = "AllowRDSServiceUse"
        Effect    = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, { Name = "${var.db_name}-kms" })
}

# -----------------------------
# RDS Instance
# -----------------------------
resource "aws_db_instance" "rds" {
  identifier             = var.db_name
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  username               = local.rds_credentials.username
  password               = local.rds_credentials.password
  allocated_storage      = 20
  storage_type           = "gp2"
  publicly_accessible    = false
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  multi_az               = var.multi_az

  # 🔐 Security & compliance
  storage_encrypted               = true
  kms_key_id                      = aws_kms_key.rds.arn
  deletion_protection             = true
  auto_minor_version_upgrade      = true
  copy_tags_to_snapshot           = true
  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.rds.arn
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  tags = merge(var.tags, { Name = var.db_name })
}

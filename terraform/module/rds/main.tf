# -----------------------------
# Security Group for RDS
# -----------------------------
resource "aws_security_group" "rds_sg" {
  name        = "${var.db_name}-sg"
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id != "" ? var.vpc_id : data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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
# RDS Instance
# -----------------------------
resource "aws_db_instance" "rds" {
  identifier           = var.db_name
  engine               = var.db_engine
  engine_version       = var.db_engine_version
  instance_class       = var.db_instance_class
  username             = local.rds_credentials.username
  password             = local.rds_credentials.password
  allocated_storage    = 20
  storage_type         = "gp2"
  publicly_accessible  = false
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  multi_az             = var.multi_az

  tags = merge(var.tags, { Name = var.db_name })
}

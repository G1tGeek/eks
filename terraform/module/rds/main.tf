# RDS Instance
# checkov:skip=CKV_AWS_293: Deletion protection is intentionally disabled for RDS
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

  storage_encrypted               = true
  kms_key_id                      = aws_kms_key.rds.arn
  auto_minor_version_upgrade      = true
  deletion_protection             = false
  copy_tags_to_snapshot           = true
  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.rds.arn
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  tags = merge(var.tags, { Name = var.db_name })
}

output "rds_endpoint" {
  description = "The RDS endpoint for the database"
  value       = aws_db_instance.rds.endpoint
}

output "rds_instance_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.rds.id
}

output "rds_security_group_id" {
  description = "The security group ID associated with RDS"
  value       = aws_security_group.rds_sg.id
}

output "rds_secret_arn" {
  description = "ARN of the RDS credentials stored in Secrets Manager"
  value       = var.rds_secret_name != "" ? aws_secretsmanager_secret.rds_secret[0].arn : ""
}

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

# Optional: ARN of the Secrets Manager secret (without exposing credentials)
output "rds_secret_arn" {
  description = "ARN of the Secrets Manager secret storing RDS credentials"
  value       = var.rds_secret_name != "" ? var.rds_secret_name : ""
}

output "rds_endpoint" {
  description = "RDS endpoint from module"
  value       = module.rds.rds_endpoint
}

output "rds_instance_id" {
  description = "RDS instance ID from module"
  value       = module.rds.rds_instance_id
}

output "rds_security_group_id" {
  description = "RDS security group ID from module"
  value       = module.rds.rds_security_group_id
}

output "rds_secret_arn" {
  description = "ARN of the Secrets Manager secret storing RDS credentials"
  value       = module.rds.rds_secret_arn
}

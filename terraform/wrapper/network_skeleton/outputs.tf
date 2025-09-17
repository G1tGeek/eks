# --- VPC / Networking ---
output "vpc_id" {
  description = "The ID of the created VPC"
  value       = module.network_skeleton.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.network_skeleton.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.network_skeleton.private_subnet_ids
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = module.network_skeleton.nat_gateway_id
}



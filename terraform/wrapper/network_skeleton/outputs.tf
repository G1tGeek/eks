#####################################
# Wrapper Outputs
#####################################

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

# --- EKS ---
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.network_skeleton.eks_cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint for the EKS control plane"
  value       = module.network_skeleton.eks_cluster_endpoint
}

output "eks_cluster_security_group_id" {
  description = "Cluster security group ID"
  value       = module.network_skeleton.eks_cluster_security_group_id
}

output "eks_node_group_role_arn" {
  description = "IAM role ARN for worker nodes"
  value       = module.network_skeleton.eks_node_group_role_arn
}

# --- RDS ---
output "rds_instance_endpoint" {
  description = "DNS address of the RDS instance"
  value       = module.network_skeleton.rds_instance_endpoint
}

output "rds_instance_id" {
  description = "Identifier of the RDS instance"
  value       = module.network_skeleton.rds_instance_id
}

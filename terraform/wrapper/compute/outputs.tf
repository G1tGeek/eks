output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.compute.eks_cluster_id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.compute.eks_cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API server endpoint"
  value       = module.compute.eks_cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Certificate authority data for cluster authentication"
  value       = module.compute.eks_cluster_certificate_authority_data
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.compute.eks_cluster_arn
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN for IAM roles for service accounts (IRSA)"
  value       = module.compute.eks_oidc_provider_arn
}

output "managed_node_group_names" {
  description = "List of managed node group names"
  value       = module.compute.eks_managed_node_group_names
}

output "managed_node_group_arns" {
  description = "List of managed node group ARNs"
  value       = module.compute.eks_managed_node_group_arns
}
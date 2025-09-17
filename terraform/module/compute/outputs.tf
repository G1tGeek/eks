output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_id" {
  value = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "eks_cluster_arn" {
  value = module.eks.cluster_arn
}

output "eks_oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "eks_managed_node_group_names" {
  value = keys(module.eks.eks_managed_node_groups)
}

output "eks_managed_node_group_arns" {
  value = [
    for ng in values(module.eks.eks_managed_node_groups) : try(ng.resources[0].arn, "")
  ]
}

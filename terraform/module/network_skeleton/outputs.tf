output "vpc_id" {
  description = "ID of the created VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of created public subnets."
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "IDs of created private subnets."
  value       = [for s in aws_subnet.private : s.id]
}

output "nat_gateway_id" {
  description = "NAT Gateway ID."
  value       = aws_nat_gateway.nat.id
}

output "eks_cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority (base64)."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "eks_node_group_arn" {
  description = "ARN of the managed EKS node group."
  value       = aws_eks_node_group.default.arn
}

output "rds_instance_id" {
  description = "RDS instance identifier."
  value       = aws_db_instance.default.id
}

output "rds_endpoint" {
  description = "RDS endpoint address."
  value       = aws_db_instance.default.address
}

output "rds_port" {
  description = "RDS endpoint port."
  value       = aws_db_instance.default.port
}

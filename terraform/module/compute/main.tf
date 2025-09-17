module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = var.cluster_name
  cluster_version = "1.28"
  subnets         = data.terraform_remote_state.network.outputs.private_subnet_ids
  vpc_id          = data.terraform_remote_state.network.outputs.vpc_id

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  node_groups = {
    for ng_name, ng in var.node_groups :
    ng_name => {
      desired_capacity = ng.desired_size
      max_capacity     = ng.max_size
      min_capacity     = ng.min_size

      instance_type = ng.instance_type
      subnet_ids    = data.terraform_remote_state.network.outputs.private_subnet_ids

      key_name = var.key_name
    }
  }

  tags = {
    Environment = var.environment
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"  # Compatible version

  cluster_name    = var.cluster_name
  cluster_version = "1.28"
  subnet_ids      = data.terraform_remote_state.network.outputs.private_subnet_ids
  vpc_id          = data.terraform_remote_state.network.outputs.vpc_id

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  eks_managed_node_groups = {
    for ng_name, ng in var.node_groups :
    ng_name => {
      desired_size  = ng.desired_size
      max_size      = ng.max_size
      min_size      = ng.min_size

      instance_types = ng.instance_types
      subnet_ids     = data.terraform_remote_state.network.outputs.private_subnet_ids

      key_name = var.key_name
    }
  }

  tags = {
    Environment = var.environment
  }
}


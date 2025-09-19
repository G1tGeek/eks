module "eks" {
  # checkov:skip=CKV_TF_1: Registry module version is pinned, commit hash not applicable

  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  subnet_ids      = data.terraform_remote_state.network.outputs.private_subnet_ids
  vpc_id          = data.terraform_remote_state.network.outputs.vpc_id

  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access

  eks_managed_node_groups = {
    for ng_name, ng in var.node_groups :
    ng_name => {
      desired_size   = ng.desired_size
      max_size       = ng.max_size
      min_size       = ng.min_size
      instance_types = ng.instance_types
      subnet_ids     = data.terraform_remote_state.network.outputs.private_subnet_ids
      key_name       = var.key_name
    }
  }

  authentication_mode = "API"

  access_entries = {
    for u in var.map_users :
    u.username => {
      principal_arn = u.userarn
      type          = "STANDARD"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = {
    Environment = var.environment
  }
}


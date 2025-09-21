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

# ------------------------------------------------
# Standalone EC2 instance for OpenVPN
# ------------------------------------------------
resource "aws_instance" "openvpn" {
# checkov:skip=CKV_AWS_126: Skipping detailed monitoring check
# checkov:skip=CKV_AWS_135: Skipping EBS optimization check
# checkov:skip=CKV_AWS_8: Skipping EBS encryption check
# checkov:skip=CKV_AWS_88: Skipping public IP check
# checkov:skip=CKV2_AWS_41: Skipping IAM role attachment check
# checkov:skip=CKV_AWS_79: Skipping IMDSv1 restriction check


  ami                         = "ami-07ce52c67e2a051d6"
  instance_type               = "t3.small"
  key_name                    = var.key_name
  subnet_id                   = data.terraform_remote_state.network.outputs.public_subnet_ids[0]
  associate_public_ip_address = true

  tags = {
    Name        = "open-vpn"
    Environment = var.environment
  }
}

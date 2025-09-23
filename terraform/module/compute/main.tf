# ------------------------------------------------
# Fetch VPC CIDR (for SG rules)
# ------------------------------------------------
data "aws_vpc" "eks_vpc" {
  id = data.terraform_remote_state.network.outputs.vpc_id
}

# ------------------------------------------------
# Launch Templates for Ubuntu 22.04 Nodes
# ------------------------------------------------
resource "aws_launch_template" "ubuntu_node" {
  for_each = var.node_groups

  name_prefix   = "ubuntu22-${each.key}-"
  image_id      = "ami-0d88b56ff2c65082e" # Ubuntu 22.04 AMI
  instance_type = each.value.instance_types[0]
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = false
    subnet_id                   = data.terraform_remote_state.network.outputs.private_subnet_ids[0]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "eks-ubuntu-node-${each.key}"
    }
  }

  # IMDSv2 enforcement
  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2 # Skipping Prisma check
  }
}

# ------------------------------------------------
# EKS Cluster
# ------------------------------------------------
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

      # Use launch template with Ubuntu 22 AMI
      launch_template = {
        id      = aws_launch_template.ubuntu_node[ng_name].id
        version = "$Latest"
      }
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

  # -------------------------
  # Security Group Rules
  # -------------------------
  cluster_security_group_additional_rules = {
    allow_all_vpc = {
      description = "Allow all traffic from same VPC"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      cidr_blocks = [data.aws_vpc.eks_vpc.cidr_block]
    }
  }

  node_security_group_additional_rules = {
    ssh_from_vpc = {
      description = "Allow SSH from same VPC"
      protocol    = "tcp"
      from_port   = 22
      to_port     = 22
      type        = "ingress"
      cidr_blocks = [data.aws_vpc.eks_vpc.cidr_block]
    }
  }

  tags = {
    Environment = var.environment
  }
}

# ------------------------------------------------
# Security Group for OpenVPN (allow all traffic)
# ------------------------------------------------
resource "aws_security_group" "openvpn_sg" {
  # checkov:skip=CKV_AWS_277
  # checkov:skip=CKV_AWS_260
  # checkov:skip=CKV_AWS_25
  # checkov:skip=CKV_AWS_24
  # checkov:skip=CKV_AWS_382
  name        = "openvpn-sg"
  description = "Allow all inbound and outbound traffic for OpenVPN"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    description      = "Allow all inbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "openvpn-sg"
    Environment = var.environment
  }
}

# ------------------------------------------------
# Standalone EC2 instance for OpenVPN
# ------------------------------------------------
resource "aws_instance" "openvpn" {
  # checkov:skip=CKV_AWS_126
  # checkov:skip=CKV_AWS_135
  # checkov:skip=CKV_AWS_8
  # checkov:skip=CKV_AWS_88
  # checkov:skip=CKV2_AWS_41
  # checkov:skip=CKV_AWS_79

  ami                         = "ami-07ce52c67e2a051d6"
  instance_type               = "t3.small"
  key_name                    = var.key_name
  subnet_id                   = data.terraform_remote_state.network.outputs.public_subnet_ids[0]
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.openvpn_sg.id]

  tags = {
    Name        = "open-vpn"
    Environment = var.environment
  }
}


provider "aws" {
  region = var.aws_region
}

# availability zones helper 
data "aws_availability_zones" "available" {}

# -----------------------------
# VPC
# -----------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${var.environment}-vpc"
  })
}

# -----------------------------
# Internet Gateway
# -----------------------------
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

# ------------------------------------------------------------------
# Key Pair - Create if missing and upload to S3 
# ------------------------------------------------------------------
resource "null_resource" "create_key_pair_if_missing" {
  provisioner "local-exec" {
    command     = "${path.module}/key.sh ${var.key_name} ${var.aws_region} ${var.keypair_s3_bucket} ${var.environment}"
    interpreter = ["/bin/bash", "-c"]
  }

  triggers = {
    key_name = var.key_name
  }
}

# -----------------------------
# Public Subnets 
# -----------------------------
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.environment}-public-${count.index}"
    # Optional EKS tagging (wrapper can set cluster_name)
    # "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    # "kubernetes.io/role/elb" = "1"
  })
}

# -----------------------------
# Private Subnets
# -----------------------------
resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]

  tags = merge(var.tags, {
    Name = "${var.environment}-private-${count.index}"
    # Optional EKS tagging
    # "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    # "kubernetes.io/role/internal-elb" = "1"
  })
}

# -----------------------------
# NAT Gateway 
# -----------------------------
resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(var.tags, {
    Name = "${var.environment}-nat"
  })
}

# -----------------------------
# Route Tables & Associations
# -----------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = merge(var.tags, { Name = "${var.environment}-public-rt" })
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(var.tags, { Name = "${var.environment}-private-rt" })
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# -----------------------------
# EKS IAM Role (control plane)
# -----------------------------
resource "aws_iam_role" "eks_cluster" {
  name = coalescelist([var.cluster_name, var.environment])[0] != "" ? "${var.cluster_name}-eks-cluster-role" : "${var.environment}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# -----------------------------
# EKS Cluster
# -----------------------------
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name != "" ? var.cluster_name : "${var.environment}-eks-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  dynamic "vpc_config" {
    for_each = [1]
    content {
      subnet_ids = concat(
        [for s in aws_subnet.public : s.id],
        [for s in aws_subnet.private : s.id]
      )
      endpoint_public_access  = var.cluster_endpoint_public_access
      endpoint_private_access = var.cluster_endpoint_private_access
      public_access_cidrs     = var.cluster_public_access_cidrs
    }
  }

  lifecycle {
    ignore_changes = ["version"]
  }
  depends_on = [aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy]
}

# -----------------------------
# Node group IAM role
# -----------------------------
resource "aws_iam_role" "eks_nodegroup" {
  name = coalescelist([var.cluster_name, var.environment])[0] != "" ? "${var.cluster_name}-eks-nodegroup-role" : "${var.environment}-eks-nodegroup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_nodegroup.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "eks_cni_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_nodegroup.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
resource "aws_iam_role_policy_attachment" "eks_registry_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_nodegroup.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# optionally attach SSM if requested by wrapper
resource "aws_iam_role_policy_attachment" "eks_node_ssm" {
  count      = var.attach_ssm_policy ? 1 : 0
  role       = aws_iam_role.eks_nodegroup.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# -----------------------------
# Managed Node Group (with SSH access)
# -----------------------------
resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.node_group_name != "" ? var.node_group_name : "${var.environment}-default"
  node_role_arn   = aws_iam_role.eks_nodegroup.arn
  subnet_ids      = var.node_subnet_ids != [] ? var.node_subnet_ids : [for s in aws_subnet.private : s.id]

  scaling_config {
    desired_size = var.node_desired_capacity
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  instance_types = var.node_instance_types
  ami_type       = var.node_ami_type
  disk_size      = var.node_disk_size

  # -----------------------
  # Enable SSH access to EKS nodes
  # -----------------------
  remote_access {
    ec2_ssh_key               = var.key_name
    source_security_group_ids = var.node_ssh_source_security_group_ids
  }

  # Ensure keypair creation helper runs first to avoid races (optional but helpful)
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_AmazonEKSWorkerNodePolicy,
    null_resource.create_key_pair_if_missing
  ]
}

# -----------------------------
# RDS Security Group 
# -----------------------------
resource "aws_security_group" "rds" {
  name   = var.rds_sg_name != "" ? var.rds_sg_name : "${var.environment}-rds-sg"
  vpc_id = aws_vpc.main.id

  # dynamic ingress rules for SG IDs
  dynamic "ingress" {
    for_each = var.db_allowed_source_security_group_ids != null ? var.db_allowed_source_security_group_ids : []
    content {
      from_port       = var.db_port
      to_port         = var.db_port
      protocol        = "tcp"
      security_groups = [ingress.value]
      description     = "Allow DB from allowed security group"
    }
  }

  # dynamic ingress rules for CIDR blocks
  dynamic "ingress" {
    for_each = var.db_allowed_cidr_blocks != null ? var.db_allowed_cidr_blocks : []
    content {
      from_port   = var.db_port
      to_port     = var.db_port
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "Allow DB from allowed CIDR"
    }
  }

  # default egress - allow outbound (customize via var if needed)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.egress_cidr_blocks
  }

  tags = merge(var.tags, { Name = var.rds_sg_name != "" ? var.rds_sg_name : "${var.environment}-rds-sg" })
}

# -----------------------------
# RDS Subnet Group (private subnets)
# -----------------------------
resource "aws_db_subnet_group" "default" {
  name       = var.db_subnet_group_name != "" ? var.db_subnet_group_name : "${var.environment}-rds-subnet-group"
  subnet_ids = var.db_subnet_ids != [] ? var.db_subnet_ids : [for s in aws_subnet.private : s.id]

  tags = merge(var.tags, { Name = var.db_subnet_group_name != "" ? var.db_subnet_group_name : "${var.environment}-rds-subnet-group" })
}

# -----------------------------
# RDS Instance (all parameters from variables)
# -----------------------------
resource "aws_db_instance" "default" {
  identifier             = var.db_identifier != "" ? var.db_identifier : "${var.environment}-rds"
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  name                   = var.db_name
  username               = var.db_username
  password               = var.db_password
  port                   = var.db_port
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = var.db_vpc_security_group_ids != [] ? var.db_vpc_security_group_ids : [aws_security_group.rds.id]

  multi_az                = var.db_multi_az
  skip_final_snapshot     = var.db_skip_final_snapshot
  deletion_protection     = var.db_deletion_protection
  apply_immediately       = var.db_apply_immediately
  backup_retention_period = var.db_backup_retention
  backup_window           = var.db_backup_window
  maintenance_window      = var.db_maintenance_window

  tags = merge(var.tags, { Name = var.db_identifier != "" ? var.db_identifier : "${var.environment}-rds" })
}

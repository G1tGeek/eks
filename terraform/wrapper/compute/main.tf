module "compute" {
  source = "git::https://github.com/G1tGeek/eks.git//terraform/module/compute?ref=main"

  aws_region   = "ap-northeast-1"
  environment  = "eks"
  cluster_name = "eks-cluster"
  key_name     = "eks"

  cluster_version                 = "1.28"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  network_s3_bucket = "yuvraj-opstree"
  network_s3_key    = "modules/network-skeleton/terraform.tfstate"

  node_groups = {
    java = {
      instance_types = ["t3.medium"]
      desired_size   = 1
      max_size       = 2
      min_size       = 1
    }
    nodejs = {
      instance_types = ["t3.medium"]
      desired_size   = 1
      max_size       = 2
      min_size       = 1
    }
  }

  # 👇 This matches module expectation (module will convert to access_entries)
  map_users = [
    {
      userarn  = "arn:aws:iam::130830900133:user/new"
      username = "new"
      groups   = ["system:masters"] # kept for compatibility, module ignores groups but uses username + ARN
    }
  ]
}

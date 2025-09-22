module "ecr" {
  source = "git::https://github.com/G1tGeek/eks.git//terraform/module/ecr?ref=main"
  
  # checkov:skip=CKV_TF_1: Skipping commit hash pinning check
  # checkov:skip=CKV_TF_2: Skipping tag pinning check

  environment = "eks"

  repositories = [
    "java-api",
    "node-api",
  ]

  tags = {
    Project = "eks-apps"
    Owner   = "yuvraj"
  }
}

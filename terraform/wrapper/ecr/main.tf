module "ecr" {
  source = "git::https://github.com/G1tGeek/eks.git//terraform/module/ecr?ref=main"

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
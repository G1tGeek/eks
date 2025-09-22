data "aws_caller_identity" "current" {}

########################################################
# KMS Key for ECR encryption
########################################################
resource "aws_kms_key" "ecr_key" {
  description             = "KMS key for ECR repositories"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1"
    Statement = [
      {
        Sid       = "Allow administration of the key"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = [
          "kms:*"
        ]
        Resource = "*"
      }
    ]
  })
}

########################################################
# ECR Repositories
########################################################
resource "aws_ecr_repository" "this" {
  for_each = toset(var.repositories)

  name                 = each.value
  image_tag_mutability = "IMMUTABLE" 

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ecr_key.arn
  }

  tags = merge(
    {
      Name        = each.value
      Environment = var.environment
    },
    var.tags
  )
}

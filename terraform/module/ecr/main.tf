resource "aws_kms_key" "ecr_key" {
  description             = "KMS key for ECR repositories"
  deletion_window_in_days = 7
}

resource "aws_ecr_repository" "this" {
  for_each = toset(var.repositories)

  name                 = each.value
  image_tag_mutability = "MUTABLE"   # keep mutable, skipping Checkov CKV_AWS_51

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {           # enable KMS encryption
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

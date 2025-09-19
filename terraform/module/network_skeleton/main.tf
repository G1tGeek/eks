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
# VPC Flow Logs (Fix CKV2_AWS_11)
# -----------------------------
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/${var.environment}-flow-logs"
  retention_in_days = 30
}

resource "aws_iam_role" "vpc_flow_logs_role" {
  name = "${var.environment}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "vpc_flow_logs_role_policy" {
  role       = aws_iam_role.vpc_flow_logs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_flow_log" "vpc_flow_log" {
  vpc_id          = aws_vpc.main.id
  iam_role_arn    = aws_iam_role.vpc_flow_logs_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL"

  tags = merge(var.tags, {
    Name = "${var.environment}-vpc-flow-logs"
  })
}

# -----------------------------
# Lock down Default Security Group (Fix CKV2_AWS_12)
# -----------------------------
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  ingress = []
  egress  = []

  tags = merge(var.tags, {
    Name = "${var.environment}-default-sg"
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
    command     = "bash ${path.module}/key.sh ${var.key_name} ${var.aws_region} ${var.keypair_s3_bucket} ${var.environment}"
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
  })
}

# -----------------------------
# NAT Gateway 
# -----------------------------
resource "aws_eip" "nat" {
  domain = "vpc"
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

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
# (can stay here if you want SSH key infra at network layer,
# but usually this would move to compute too)
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

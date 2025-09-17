###########################
# Provider / general
###########################

variable "aws_region" {
  description = "AWS region to create resources in (e.g. us-east-1)."
  type        = string
}

variable "environment" {
  description = "Environment name used to prefix resource names (e.g. dev/stage/prod)."
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to resources."
  type        = map(string)
  default     = {}
}

###########################
# VPC / subnets
###########################

variable "vpc_cidr" {
  description = "CIDR block for the VPC (e.g. 10.0.0.0/16)."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr)) && can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\/\\d{1,2}$", var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR (e.g. 10.0.0.0/16)."
  }
}

variable "public_subnets" {
  description = "List of CIDR blocks for public subnets (order used for AZ distribution). Example: [\"10.0.0.0/24\",\"10.0.2.0/24\"]"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "List of CIDR blocks for private subnets (order used for AZ distribution). Example: [\"10.0.1.0/24\",\"10.0.3.0/24\"]"
  type        = list(string)
  default     = []
}

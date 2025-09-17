variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "network_s3_bucket" {
  description = "S3 bucket storing the remote state of the network module"
  type        = string
}

variable "network_s3_key" {
  description = "S3 key (path) of the remote state file for the network module"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "key_name" {
  description = "Name of an existing EC2 key pair to enable SSH access to nodes"
  type        = string
}

variable "node_groups" {
  type = map(object({
    instance_types = list(string)
    desired_size   = number
    max_size       = number
    min_size       = number
  }))
}


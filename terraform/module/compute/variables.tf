variable "aws_region" {
  type = string
}

variable "environment" {
  type = string
}

variable "network_s3_bucket" {
  type = string
}

variable "network_s3_key" {
  type = string
}

variable "cluster_name" {
  type    = string
  default = "eks-cluster"
}

variable "key_name" {
  type = string
}

variable "node_groups" {
  type = map(object({
    instance_type = string
    desired_size  = number
    max_size      = number
    min_size      = number
  }))
  default = {
    app1 = {
      instance_type = "t3.medium"
      desired_size  = 1
      max_size      = 2
      min_size      = 1
    }
    app2 = {
      instance_type = "t3.medium"
      desired_size  = 1
      max_size      = 2
      min_size      = 1
    }
  }
}

variable "repositories" {
  description = "List of ECR repositories to create"
  type        = list(string)
}

variable "environment" {
  description = "Environment name (e.g. dev, prod)"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

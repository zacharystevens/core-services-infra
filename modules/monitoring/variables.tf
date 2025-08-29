variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for resources"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for resources"
  type        = list(string)
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs allowed to access OpenSearch"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "origin_domain_names" {
  description = "List of origin domain names"
  type        = list(string)
}

variable "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

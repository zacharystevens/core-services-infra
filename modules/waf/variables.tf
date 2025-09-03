variable "name" {
  description = "Name prefix for the WAF"
  type        = string
}

variable "description" {
  description = "Description of the WAF"
  type        = string
  default     = "WAF for public dashboards"
}

variable "scope" {
  description = "Scope of the WAF (CLOUDFRONT or REGIONAL)"
  type        = string
  default     = "CLOUDFRONT"
  
  validation {
    condition     = contains(["CLOUDFRONT", "REGIONAL"], var.scope)
    error_message = "Scope must be either CLOUDFRONT or REGIONAL"
  }
}



variable "rate_limit" {
  description = "Rate limit for IP-based blocking"
  type        = number
  default     = 2000
  
  validation {
    condition     = var.rate_limit > 0
    error_message = "Rate limit must be greater than 0"
  }
}

variable "tags" {
  description = "Tags to apply to the WAF"
  type        = map(string)
  default     = {}
}

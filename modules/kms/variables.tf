variable "name_prefix" {
  description = "Prefix for KMS key names and aliases"
  type        = string
}

variable "key_configs" {
  description = "Map of KMS key configurations"
  type = map(object({
    description = string
    service    = string
    key_usage  = string
  }))
  
  validation {
    condition = alltrue([
      for key, config in var.key_configs : 
      contains(["ec2", "elasticfilesystem", "rds", "s3", "es", "secretsmanager"], config.service)
    ])
    error_message = "Service must be one of: ec2, elasticfilesystem, rds, s3, es, secretsmanager"
  }
}

variable "deletion_window_in_days" {
  description = "Number of days to wait before deleting KMS key"
  type        = number
  default     = 7
  
  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "Deletion window must be between 7 and 30 days"
  }
}

variable "enable_key_rotation" {
  description = "Whether to enable automatic key rotation"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all KMS keys"
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN for EKS service accounts"
  type        = string
  default     = ""
}

variable "namespace" {
  description = "Kubernetes namespace for service account"
  type        = string
  default     = ""
}

variable "service_account_name" {
  description = "Kubernetes service account name"
  type        = string
  default     = ""
}

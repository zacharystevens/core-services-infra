output "kms_key_arns" {
  description = "Map of KMS key ARNs"
  value = module.kms_keys.kms_key_arns
}

output "jenkins_role_arn" {
  description = "ARN of Jenkins IAM role"
  value       = aws_iam_role.jenkins.arn
}

output "eks_service_account_role_arn" {
  description = "ARN of EKS service account IAM role"
  value       = aws_iam_role.eks_service_account.arn
}

# Additional KMS outputs from the new module
output "kms_key_ids" {
  description = "Map of KMS key IDs"
  value = module.kms_keys.kms_key_ids
}

output "kms_key_aliases" {
  description = "Map of KMS key aliases"
  value = module.kms_keys.kms_key_aliases
}

output "kms_keys" {
  description = "Complete KMS key information"
  value = module.kms_keys.kms_keys
}

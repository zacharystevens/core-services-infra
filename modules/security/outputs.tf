output "kms_key_arns" {
  description = "Map of KMS key ARNs"
  value = {
    ebs         = aws_kms_key.ebs.arn
    efs         = aws_kms_key.efs.arn
    rds         = aws_kms_key.rds.arn
    s3          = aws_kms_key.s3.arn
    opensearch  = aws_kms_key.opensearch.arn
  }
}

output "jenkins_role_arn" {
  description = "ARN of Jenkins IAM role"
  value       = aws_iam_role.jenkins.arn
}

output "eks_service_account_role_arn" {
  description = "ARN of EKS service account IAM role"
  value       = aws_iam_role.eks_service_account.arn
}

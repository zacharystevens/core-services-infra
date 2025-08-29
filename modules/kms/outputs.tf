output "kms_key_arns" {
  description = "Map of KMS key ARNs by key name"
  value = {
    for key, kms_key in aws_kms_key.main : key => kms_key.arn
  }
}

output "kms_key_ids" {
  description = "Map of KMS key IDs by key name"
  value = {
    for key, kms_key in aws_kms_key.main : key => kms_key.id
  }
}

output "kms_key_aliases" {
  description = "Map of KMS key aliases by key name"
  value = {
    for key, alias in aws_kms_alias.main : key => alias.name
  }
}

output "kms_keys" {
  description = "Complete KMS key information"
  value = {
    for key, kms_key in aws_kms_key.main : key => {
      arn         = kms_key.arn
      id          = kms_key.id
      alias       = aws_kms_alias.main[key].name
      description = kms_key.description
      key_rotation_enabled = kms_key.enable_key_rotation
    }
  }
}

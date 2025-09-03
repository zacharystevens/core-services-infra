terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Reusable KMS Module
# This module creates KMS keys with service-specific policies to eliminate duplication

# Data sources for current AWS account and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# KMS Key resource
resource "aws_kms_key" "main" {
  for_each = var.key_configs
  
  description             = each.value.description
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
  
  # Use templatefile to generate service-specific policies
  policy = templatefile("${path.module}/policies/${each.value.service}.json", {
    account_id = data.aws_caller_identity.current.account_id
    region     = data.aws_region.current.name
    service    = each.value.service
    key_usage  = each.value.key_usage
  })
  
  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-${each.key}-key"
    Service     = each.value.service
    Purpose     = each.value.description
    ManagedBy   = "terraform"
  })
}

# KMS Key Alias
resource "aws_kms_alias" "main" {
  for_each = var.key_configs
  
  name          = "alias/${var.name_prefix}-${each.key}"
  target_key_id = aws_kms_key.main[each.key].id
}

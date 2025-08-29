# Example usage of the new KMS module
# This file demonstrates how to use the reusable KMS module

# Example 1: Basic KMS keys for common services
module "basic_kms_keys" {
  source = "../modules/kms"
  
  name_prefix = "example-basic"
  
  key_configs = {
    ebs = {
      description = "EBS volume encryption"
      service    = "ec2"
      key_usage  = "ENCRYPT_DECRYPT"
    }
    efs = {
      description = "EFS file system encryption"
      service    = "elasticfilesystem"
      key_usage  = "ENCRYPT_DECRYPT"
    }
  }
  
  tags = {
    Environment = "development"
    Project     = "example"
    Purpose     = "demonstration"
  }
}

# Example 2: Production KMS keys with custom settings
module "production_kms_keys" {
  source = "../modules/kms"
  
  name_prefix = "example-prod"
  
  key_configs = {
    ebs = {
      description = "Production EBS encryption"
      service    = "ec2"
      key_usage  = "ENCRYPT_DECRYPT"
    }
    rds = {
      description = "Production RDS encryption"
      service    = "rds"
      key_usage  = "ENCRYPT_DECRYPT"
    }
    s3 = {
      description = "Production S3 encryption"
      service    = "s3"
      key_usage  = "ENCRYPT_DECRYPT"
    }
    opensearch = {
      description = "Production OpenSearch encryption"
      service    = "es"
      key_usage  = "ENCRYPT_DECRYPT"
    }
  }
  
  deletion_window_in_days = 14
  enable_key_rotation     = true
  
  tags = {
    Environment = "production"
    Project     = "example"
    Compliance  = "SOC2"
    CostCenter  = "IT-001"
  }
}

# Example 3: Minimal KMS keys for testing
module "test_kms_keys" {
  source = "../modules/kms"
  
  name_prefix = "example-test"
  
  key_configs = {
    ebs = {
      description = "Test EBS encryption"
      service    = "ec2"
      key_usage  = "ENCRYPT_DECRYPT"
    }
  }
  
  deletion_window_in_days = 7
  enable_key_rotation     = false
  
  tags = {
    Environment = "testing"
    Project     = "example"
    Purpose     = "testing-only"
  }
}

# Outputs to demonstrate the module's capabilities
output "basic_key_arns" {
  description = "Basic KMS key ARNs"
  value = module.basic_kms_keys.kms_key_arns
}

output "production_key_aliases" {
  description = "Production KMS key aliases"
  value = module.production_kms_keys.kms_key_aliases
}

output "test_key_info" {
  description = "Test KMS key complete information"
  value = module.test_kms_keys.kms_keys
}

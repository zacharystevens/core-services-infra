# KMS Module

A reusable Terraform module for creating AWS KMS keys with service-specific policies. This module eliminates duplication by providing a flexible way to create multiple KMS keys with different service permissions.

## Features

- **DRY Principle**: Eliminates repeated KMS key configurations
- **Service-Specific Policies**: Pre-built policy templates for common AWS services
- **Flexible Configuration**: Support for multiple keys with different configurations
- **Consistent Tagging**: Automatic tagging with service and purpose information
- **Validation**: Input validation for service types and configuration values

## Supported Services

- **EC2/EBS**: `ec2` - For EBS volume encryption
- **EFS**: `elasticfilesystem` - For EFS file system encryption
- **RDS**: `rds` - For RDS database encryption
- **S3**: `s3` - For S3 bucket encryption
- **OpenSearch**: `es` - For OpenSearch domain encryption
- **Secrets Manager**: `secretsmanager` - For Secrets Manager encryption

## Usage

### Basic Example

```hcl
module "kms_keys" {
  source = "./modules/kms"
  
  name_prefix = "core-services"
  
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
    rds = {
      description = "RDS database encryption"
      service    = "rds"
      key_usage  = "ENCRYPT_DECRYPT"
    }
  }
  
  tags = {
    Environment = "production"
    Project     = "core-services"
  }
}
```

### Advanced Example with Custom Settings

```hcl
module "kms_keys" {
  source = "./modules/kms"
  
  name_prefix = "core-services"
  
  key_configs = {
    ebs = {
      description = "EBS volume encryption"
      service    = "ec2"
      key_usage  = "ENCRYPT_DECRYPT"
    }
    s3 = {
      description = "S3 bucket encryption"
      service    = "s3"
      key_usage  = "ENCRYPT_DECRYPT"
    }
    opensearch = {
      description = "OpenSearch domain encryption"
      service    = "es"
      key_usage  = "ENCRYPT_DECRYPT"
    }
  }
  
  deletion_window_in_days = 14
  enable_key_rotation     = true
  
  tags = {
    Environment = "production"
    Project     = "core-services"
    Compliance  = "SOC2"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name_prefix | Prefix for KMS key names and aliases | `string` | n/a | yes |
| key_configs | Map of KMS key configurations | `map(object)` | n/a | yes |
| deletion_window_in_days | Number of days to wait before deleting KMS key | `number` | `7` | no |
| enable_key_rotation | Whether to enable automatic key rotation | `bool` | `true` | no |
| tags | Tags to apply to all KMS keys | `map(string)` | `{}` | no |

### key_configs Object

| Name | Description | Type | Required |
|------|-------------|------|:--------:|
| description | Human-readable description of the key | `string` | yes |
| service | AWS service identifier | `string` | yes |
| key_usage | Key usage (ENCRYPT_DECRYPT, SIGN_VERIFY) | `string` | yes |

## Outputs

| Name | Description |
|------|-------------|
| kms_key_arns | Map of KMS key ARNs by key name |
| kms_key_ids | Map of KMS key IDs by key name |
| kms_key_aliases | Map of KMS key aliases by key name |
| kms_keys | Complete KMS key information including metadata |

## Example Output

```hcl
kms_key_arns = {
  ebs = "arn:aws:kms:us-west-2:123456789012:key/abcd1234-5678-90ef-ghij-klmnopqrstuv"
  efs = "arn:aws:kms:us-west-2:123456789012:key/efgh5678-90ab-cdef-ghij-klmnopqrstuv"
  rds = "arn:aws:kms:us-west-2:123456789012:key/ijkl90ab-cdef-ghij-klmn-opqrstuvwxyz"
}

kms_key_aliases = {
  ebs = "alias/core-services-ebs"
  efs = "alias/core-services-efs"
  rds = "alias/core-services-rds"
}
```

## Migration from Old Security Module

To migrate from the old security module that had individual KMS resources:

1. **Replace the old KMS resources** in `modules/security/main.tf` with the new module call
2. **Update the outputs** to reference the new module outputs
3. **Test the migration** in a non-production environment first

### Before (Old Security Module)

```hcl
# Old way - individual resources
resource "aws_kms_key" "ebs" {
  description             = "KMS key for EBS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy = jsonencode({...})
}

resource "aws_kms_key" "efs" {
  description             = "KMS key for EFS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy = jsonencode({...})
}
```

### After (New KMS Module)

```hcl
# New way - reusable module
module "kms_keys" {
  source = "./modules/kms"
  
  name_prefix = var.name
  
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
  
  tags = var.tags
}
```

## Security Considerations

- All KMS keys are created with automatic key rotation enabled by default
- Keys are tagged with service and purpose information for better governance
- Policies follow the principle of least privilege
- Deletion protection is enabled with a configurable window

## Contributing

To add support for new AWS services:

1. Create a new policy template in the `policies/` directory
2. Update the service validation in `variables.tf`
3. Add the new service to this README
4. Test with the new service configuration

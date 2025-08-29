# Migration Guide: KMS Module Refactoring

This guide helps you migrate from the old individual KMS key resources to the new reusable KMS module that eliminates duplication and improves maintainability.

## What Changed

### Before (Old Approach)
The security module contained 5 individual KMS key resources with nearly identical configurations:

```hcl
# Old way - individual resources with duplication
resource "aws_kms_key" "ebs" {
  description             = "KMS key for EBS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow EBS to use the key"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ec2.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      }
    ]
  })
  tags = var.tags
}

# Repeated for EFS, RDS, S3, OpenSearch...
```

### After (New Approach)
The security module now uses a single, reusable KMS module:

```hcl
# New way - reusable module
module "kms_keys" {
  source = "../kms"
  
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
    rds = {
      description = "RDS database encryption"
      service    = "rds"
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
  
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  tags = var.tags
}
```

## Migration Steps

### Step 1: Backup Your Current State
```bash
# Create a backup of your current Terraform state
terraform state pull > backup-state.json
```

### Step 2: Update the Security Module
1. **Replace KMS resources** in `modules/security/main.tf` with the new module call
2. **Update outputs** in `modules/security/outputs.tf` to reference the new module
3. **Remove data sources** that are no longer needed

### Step 3: Test the Migration
```bash
# Test the plan without applying
cd modules/security
terraform plan

# If successful, apply the changes
terraform apply
```

### Step 4: Update References
Update any other modules or configurations that reference the old KMS outputs to use the new structure.

## Benefits of the New Approach

### 1. **DRY Principle Compliance**
- **Before**: 5 nearly identical KMS key resources (~150 lines of code)
- **After**: 1 module call with configuration (~30 lines of code)
- **Reduction**: ~80% less code duplication

### 2. **Maintainability**
- **Before**: Changes to KMS policies required updating 5 separate resources
- **After**: Changes to KMS policies require updating 1 template file
- **Benefit**: Single source of truth for KMS policies

### 3. **Consistency**
- **Before**: Risk of inconsistent configurations between keys
- **After**: Guaranteed consistent configuration across all keys
- **Benefit**: Reduced configuration drift and security risks

### 4. **Flexibility**
- **Before**: Fixed set of 5 KMS keys
- **After**: Configurable number and types of KMS keys
- **Benefit**: Easy to add new services or remove unused keys

### 5. **Testing**
- **Before**: Difficult to test individual KMS configurations
- **After**: Module can be tested independently
- **Benefit**: Better test coverage and validation

## Output Changes

### Before
```hcl
output "kms_key_arns" {
  value = {
    ebs         = aws_kms_key.ebs.arn
    efs         = aws_kms_key.efs.arn
    rds         = aws_kms_key.rds.arn
    s3          = aws_kms_key.s3.arn
    opensearch  = aws_kms_key.opensearch.arn
  }
}
```

### After
```hcl
output "kms_key_arns" {
  value = module.kms_keys.kms_key_arns
}

# Additional outputs available
output "kms_key_ids" {
  value = module.kms_keys.kms_key_ids
}

output "kms_key_aliases" {
  value = module.kms_keys.kms_key_aliases
}

output "kms_keys" {
  value = module.kms_keys.kms_keys
}
```

## Rollback Plan

If you need to rollback to the old approach:

1. **Restore the old KMS resources** in `modules/security/main.tf`
2. **Restore the old outputs** in `modules/security/outputs.tf`
3. **Restore the data sources** if needed
4. **Run terraform plan** to verify the rollback
5. **Apply the rollback** with `terraform apply`

## Testing the Migration

### 1. **Unit Tests**
```bash
# Test the KMS module independently
cd modules/kms
terraform init
terraform plan
```

### 2. **Integration Tests**
```bash
# Test the security module with the new KMS module
cd modules/security
terraform init
terraform plan
```

### 3. **End-to-End Tests**
```bash
# Test the complete infrastructure
cd ../..
terraform plan
```

## Common Issues and Solutions

### Issue 1: State Mismatch
**Problem**: Terraform state doesn't match the new module structure
**Solution**: Use `terraform state mv` to migrate existing resources

```bash
# Example: Move EBS KMS key to new module
terraform state mv 'module.security.aws_kms_key.ebs' 'module.security.module.kms_keys.aws_kms_key.main["ebs"]'
```

### Issue 2: Policy Template Not Found
**Problem**: Policy template files are missing
**Solution**: Ensure all policy templates are created in `modules/kms/policies/`

### Issue 3: Output References
**Problem**: Other modules can't find KMS key ARNs
**Solution**: Update references to use the new output structure

## Performance Impact

- **Deployment Time**: No significant change
- **State File Size**: Slightly smaller due to reduced duplication
- **Maintenance Overhead**: Significantly reduced
- **Security**: Improved due to consistent policies

## Next Steps

After successful migration:

1. **Monitor** the new KMS keys for any issues
2. **Update documentation** to reflect the new module usage
3. **Consider extending** the KMS module for other services
4. **Apply the same pattern** to other duplicated resources in your infrastructure

## Support

If you encounter issues during migration:

1. Check the [KMS module documentation](../modules/kms/README.md)
2. Review the [example usage](../examples/kms-usage.tf)
3. Create an issue in the repository with detailed error information
4. Consider rolling back if critical issues arise

# Core Services Infrastructure - AWS DevOps Platform

A secure, compliance-ready AWS DevOps platform featuring EKS with IRSA/OPA, self-hosted Jenkins, comprehensive security scanning, and centralized observability.

## Architecture Overview

- **Infrastructure**: EKS cluster with IRSA, OPA Gatekeeper, network policies
- **CI/CD**: Jenkins on EKS with ephemeral ECS Fargate agents
- **Security**: Comprehensive scanning (SAST/IaC/Container)
- **Observability**: AMP/AMG, OpenSearch, CloudWatch, centralized logging
- **Networking**: Multi-AZ VPC with public/private/data subnets, ALB, CloudFront + WAF, Route 53 domain (taiyakicode.click)

## Quick Start

### Prerequisites
- AWS CLI configured with admin access
- Terraform >= 1.5.0
- kubectl
- Docker
- GitHub repository

### Bootstrap (Day 1)
```bash
# 1. Initialize bootstrap
cd bootstrap
terraform init
terraform plan
terraform apply

# 2. Initialize main infrastructure
cd ..
terraform init
terraform plan
terraform apply
```

## Project Structure

```
├── bootstrap/           # Bootstrap infrastructure (S3, DynamoDB)
├── modules/            # Reusable Terraform modules
├── environments/       # Environment-specific configurations
├── ci-cd/             # Jenkins and pipeline configurations
├── security/           # Security policies and scanning
├── monitoring/         # Observability configurations
└── docs/              # Documentation and runbooks
```

## Security Features

- Zero-trust networking with network policies
- IRSA for pod IAM permissions
- OPA Gatekeeper for policy enforcement
- Comprehensive security scanning pipeline
- Encrypted storage with KMS
- Public dashboards protected by CloudFront + WAF

## Compliance

- SOC2/FedRAMP-inspired security controls
- Automated compliance scanning and reporting
- Centralized security findings dashboard
- Audit logging and monitoring

## Support

For questions or issues, please refer to the documentation in the `docs/` directory or create an issue in the repository.

#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="core-services-infra"
AWS_REGION=${1:-us-west-2}

echo -e "${GREEN}🔧 Setting up bootstrap infrastructure...${NC}"
echo -e "${YELLOW}Region: ${AWS_REGION}${NC}"

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}❌ Terraform is not installed. Please install Terraform >= 1.5.0${NC}"
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}❌ AWS CLI is not installed. Please install AWS CLI${NC}"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure'${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

# Bootstrap infrastructure
bootstrap() {
    echo -e "${YELLOW}🔧 Setting up bootstrap infrastructure...${NC}"
    
    cd bootstrap
    
    # Initialize Terraform
    terraform init
    
    # Plan bootstrap
    terraform plan -var="aws_region=${AWS_REGION}" -var="project_name=${PROJECT_NAME}"
    
    # Apply bootstrap
    echo -e "${YELLOW}Applying bootstrap infrastructure...${NC}"
    terraform apply -var="aws_region=${AWS_REGION}" -var="project_name=${PROJECT_NAME}" -auto-approve
    
    # Get outputs
    export TF_STATE_BUCKET=$(terraform output -raw terraform_state_bucket)
    export TF_LOCKS_TABLE=$(terraform output -raw terraform_locks_table)
    
    echo -e "${GREEN}✅ Bootstrap infrastructure created${NC}"
    echo -e "${YELLOW}State bucket: ${TF_STATE_BUCKET}${NC}"
    echo -e "${YELLOW}Locks table: ${TF_LOCKS_TABLE}${NC}"
    
    cd ..
}

# Update backend configuration
update_backend() {
    echo -e "${YELLOW}🔄 Updating backend configuration...${NC}"
    
    # Create backend config file
    cat > backend.tf << EOF
terraform {
  backend "s3" {
    bucket         = "${TF_STATE_BUCKET}"
    key            = "terraform.tfstate"
    region         = "${AWS_REGION}"
    dynamodb_table = "${TF_LOCKS_TABLE}"
    encrypt        = true
  }
}
EOF
    
    echo -e "${GREEN}✅ Backend configuration updated${NC}"
}

# Main function
main() {
    check_prerequisites
    bootstrap
    update_backend
    
    echo -e "${GREEN}🎉 Bootstrap deployment completed successfully!${NC}"
    echo -e "${YELLOW}Next step: Run deploy-infrastructure.sh${NC}"
}

# Run main function
main "$@"

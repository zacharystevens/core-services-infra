#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-dev}

echo -e "${GREEN}🏗️  Deploying main infrastructure...${NC}"
echo -e "${YELLOW}Environment: ${ENVIRONMENT}${NC}"

# Check if backend.tf exists
check_backend() {
    if [ ! -f "backend.tf" ]; then
        echo -e "${RED}❌ Backend configuration not found. Run deploy-bootstrap.sh first.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Backend configuration found${NC}"
}

# Deploy main infrastructure
deploy_main() {
    echo -e "${YELLOW}🏗️  Deploying main infrastructure...${NC}"
    
    # Initialize with new backend
    terraform init -reconfigure
    
    # Plan deployment
    terraform plan -var="environment=${ENVIRONMENT}"
    
    # Apply deployment
    echo -e "${YELLOW}Applying main infrastructure...${NC}"
    terraform apply -var="environment=${ENVIRONMENT}" -auto-approve
    
    echo -e "${GREEN}✅ Main infrastructure deployed${NC}"
}

# Main function
main() {
    check_backend
    deploy_main
    
    echo -e "${GREEN}🎉 Infrastructure deployment completed successfully!${NC}"
    echo -e "${YELLOW}Next step: Run deploy-kubernetes.sh${NC}"
}

# Run main function
main "$@"

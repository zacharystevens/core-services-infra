#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-dev}
AWS_REGION=${2:-us-west-2}

echo -e "${GREEN}🚀 Starting complete deployment of core-services-infra${NC}"
echo -e "${YELLOW}Environment: ${ENVIRONMENT}${NC}"
echo -e "${YELLOW}Region: ${AWS_REGION}${NC}"

# Function to run a deployment phase
run_phase() {
    local script=$1
    local description=$2
    local param1=$3
    local param2=$4
    
    echo -e "${YELLOW}📋 Running: ${description}${NC}"
    
    if [ -f "scripts/${script}" ]; then
        chmod +x "scripts/${script}"
        if [ -n "$param2" ]; then
            "./scripts/${script}" "$param1" "$param2"
        elif [ -n "$param1" ]; then
            "./scripts/${script}" "$param1"
        else
            "./scripts/${script}"
        fi
        echo -e "${GREEN}✅ ${description} completed${NC}"
    else
        echo -e "${RED}❌ Script not found: scripts/${script}${NC}"
        exit 1
    fi
}

# Main deployment flow
main() {
    echo -e "${GREEN}🎯 Starting deployment phases...${NC}"
    
    # Phase 1: Bootstrap
    run_phase "deploy-bootstrap.sh" "Bootstrap Infrastructure" "${AWS_REGION}"
    
    # Phase 2: Main Infrastructure
    run_phase "deploy-infrastructure.sh" "Main Infrastructure" "${ENVIRONMENT}"
    
    # Phase 3: Kubernetes
    run_phase "deploy-kubernetes.sh" "Kubernetes Resources" "${AWS_REGION}"
    
    # Phase 4: Monitoring
    run_phase "deploy-monitoring.sh" "Monitoring Stack"
    
    # Phase 5: Security Scan
    run_phase "deploy-security-scan.sh" "Security Scans"
    
    echo -e "${GREEN}🎉 All deployment phases completed successfully!${NC}"
    echo -e "${YELLOW}🎯 Deployment Summary:${NC}"
    echo -e "✅ Bootstrap Infrastructure"
    echo -e "✅ Main Infrastructure"
    echo -e "✅ Kubernetes Resources"
    echo -e "✅ Monitoring Stack"
    echo -e "✅ Security Scans"
    echo -e ""
    echo -e "${YELLOW}🌐 Access URLs:${NC}"
    echo -e "• Jenkins: https://jenkins.taiyakicode.click"
    echo -e "• OpenSearch: https://core-services-infra-os.taiyakicode.click"
    echo -e ""
    echo -e "${YELLOW}📝 Note: Grafana is disabled (requires AWS SSO configuration)${NC}"
}

# Run main function
main "$@"

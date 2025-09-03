#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}📊 Deploying monitoring stack...${NC}"

# Check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}❌ kubectl is not installed. Please install kubectl${NC}"
        exit 1
    fi
    
    if ! command -v helm &> /dev/null; then
        echo -e "${RED}❌ Helm is not installed. Please install Helm${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

# Deploy Prometheus Operator
deploy_prometheus() {
    echo -e "${YELLOW}Deploying Prometheus Operator...${NC}"
    
    # Add Prometheus Helm repo
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    
    # Create monitoring namespace
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy Prometheus stack
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=efs-sc
    
    echo -e "${GREEN}✅ Prometheus deployed${NC}"
}

# Deploy Grafana dashboards
deploy_dashboards() {
    if [ -d "monitoring/dashboards/" ]; then
        echo -e "${YELLOW}Deploying Grafana dashboards...${NC}"
        kubectl apply -f monitoring/dashboards/
        echo -e "${GREEN}✅ Dashboards deployed${NC}"
    else
        echo -e "${YELLOW}⚠️  Dashboards directory not found, skipping...${NC}"
    fi
}

# Main function
main() {
    check_kubectl
    deploy_prometheus
    deploy_dashboards
    
    echo -e "${GREEN}🎉 Monitoring deployment completed successfully!${NC}"
    echo -e "${YELLOW}Next step: Run deploy-security-scan.sh${NC}"
}

# Run main function
main "$@"

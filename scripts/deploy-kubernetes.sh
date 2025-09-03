#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION=${1:-us-west-2}
DOMAIN_NAME="taiyakicode.click"

echo -e "${GREEN}☸️  Deploying Kubernetes resources...${NC}"
echo -e "${YELLOW}Region: ${AWS_REGION}${NC}"

# Check if infrastructure is deployed
check_infrastructure() {
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

# Get EKS cluster info
get_cluster_info() {
    echo -e "${YELLOW}Getting EKS cluster information...${NC}"
    
    export CLUSTER_NAME=$(terraform output -raw cluster_name)
    export CLUSTER_ENDPOINT=$(terraform output -raw cluster_endpoint)
    export CLUSTER_CA=$(terraform output -raw cluster_certificate_authority_data)
    
    echo -e "${GREEN}✅ Cluster info retrieved${NC}"
}

# Update kubeconfig
update_kubeconfig() {
    echo -e "${YELLOW}Updating kubeconfig...${NC}"
    aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME}
    echo -e "${GREEN}✅ Kubeconfig updated${NC}"
}

# Wait for cluster readiness
wait_for_cluster() {
    echo -e "${YELLOW}Waiting for EKS cluster to be ready...${NC}"
    kubectl wait --for=condition=ready nodes --all --timeout=300s
    echo -e "${GREEN}✅ Cluster is ready${NC}"
}

# Deploy OPA Gatekeeper
deploy_gatekeeper() {
    echo -e "${YELLOW}Deploying OPA Gatekeeper...${NC}"
    kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml
    
    echo -e "${YELLOW}Waiting for Gatekeeper to be ready...${NC}"
    kubectl wait --for=condition=ready pod -l control-plane=controller-manager -n gatekeeper-system --timeout=300s
    echo -e "${GREEN}✅ Gatekeeper deployed${NC}"
}

# Deploy network policies
deploy_network_policies() {
    if [ -d "k8s/network-policies/" ]; then
        echo -e "${YELLOW}Deploying network policies...${NC}"
        kubectl apply -f k8s/network-policies/
        echo -e "${GREEN}✅ Network policies deployed${NC}"
    else
        echo -e "${YELLOW}⚠️  Network policies directory not found, skipping...${NC}"
    fi
}

# Deploy Jenkins
deploy_jenkins() {
    echo -e "${YELLOW}Deploying Jenkins...${NC}"
    
    # Add Jenkins Helm repo
    helm repo add jenkins https://charts.jenkins.io
    helm repo update
    
    # Create namespace
    kubectl create namespace jenkins --dry-run=client -o yaml | kubectl apply -f -
    
    # Check if Jenkins values file exists
    if [ -f "ci-cd/jenkins/values.yaml" ]; then
        # Create temporary Jenkins values file with domain substitution
        sed "s/\${DOMAIN_NAME}/${DOMAIN_NAME}/g" ci-cd/jenkins/values.yaml > ci-cd/jenkins/values-temp.yaml
        
        # Deploy Jenkins with values
        helm upgrade --install jenkins jenkins/jenkins \
            --namespace jenkins \
            --values ci-cd/jenkins/values-temp.yaml \
            --set controller.adminPassword=${JENKINS_ADMIN_PASSWORD} \
            --set controller.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=${JENKINS_ROLE_ARN}
        
        # Clean up temporary file
        rm ci-cd/jenkins/values-temp.yaml
    else
        echo -e "${RED}❌ Jenkins values file not found at ci-cd/jenkins/values.yaml${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Jenkins deployed${NC}"
}

# Main function
main() {
    check_infrastructure
    get_cluster_info
    update_kubeconfig
    wait_for_cluster
    deploy_gatekeeper
    deploy_network_policies
    deploy_jenkins
    
    echo -e "${GREEN}🎉 Kubernetes deployment completed successfully!${NC}"
    echo -e "${YELLOW}Next step: Run deploy-monitoring.sh${NC}"
}

# Run main function
main "$@"

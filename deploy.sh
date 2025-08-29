#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="core-services-infra"
ENVIRONMENT=${1:-dev}
AWS_REGION=${2:-us-west-2}
DOMAIN_NAME="taiyakicode.click"

echo -e "${GREEN}🚀 Starting deployment of ${PROJECT_NAME} in ${ENVIRONMENT} environment${NC}"
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

# Deploy Kubernetes resources
deploy_k8s() {
    echo -e "${YELLOW}☸️  Deploying Kubernetes resources...${NC}"
    
    # Get EKS cluster info
    export CLUSTER_NAME=$(terraform output -raw cluster_name)
    export CLUSTER_ENDPOINT=$(terraform output -raw cluster_endpoint)
    export CLUSTER_CA=$(terraform output -raw cluster_certificate_authority_data)
    
    # Update kubeconfig
    aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME}
    
    # Wait for cluster to be ready
    echo -e "${YELLOW}Waiting for EKS cluster to be ready...${NC}"
    kubectl wait --for=condition=ready nodes --all --timeout=300s
    
    # Deploy OPA Gatekeeper
    echo -e "${YELLOW}Deploying OPA Gatekeeper...${NC}"
    kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml
    
    # Wait for Gatekeeper to be ready
    kubectl wait --for=condition=ready pod -l control-plane=controller-manager -n gatekeeper-system --timeout=300s
    
    # Deploy network policies
    echo -e "${YELLOW}Deploying network policies...${NC}"
    kubectl apply -f k8s/network-policies/
    
    # Deploy Jenkins
    echo -e "${YELLOW}Deploying Jenkins...${NC}"
    helm repo add jenkins https://charts.jenkins.io
    helm repo update
    
    # Create namespace
    kubectl create namespace jenkins --dry-run=client -o yaml | kubectl apply -f -
    
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
    
    echo -e "${GREEN}✅ Kubernetes resources deployed${NC}"
}

# Deploy monitoring
deploy_monitoring() {
    echo -e "${YELLOW}📊 Deploying monitoring stack...${NC}"
    
    # Deploy Prometheus Operator
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=efs-sc
    
    # Deploy Grafana dashboards
    kubectl apply -f monitoring/dashboards/
    
    echo -e "${GREEN}✅ Monitoring stack deployed${NC}"
}

# Run security scans
security_scan() {
    echo -e "${YELLOW}🔒 Running security scans...${NC}"
    
    # Run kube-bench
    echo -e "${YELLOW}Running kube-bench...${NC}"
    kubectl run --rm -i -t kube-bench --image=aquasec/kube-bench:latest --restart=Never --overrides='{"spec":{"hostPID": true, "volumes":[{"name":"var-lib","hostPath":{"path":"/var/lib"}},{"name":"var-lib-etcd","hostPath":{"path":"/var/lib/etcd"}},{"name":"var-lib-kubelet","hostPath":{"path":"/var/lib/kubelet"}},{"name":"var-lib-cni","hostPath":{"path":"/var/lib/cni"}},{"name":"etc-systemd","hostPath":{"path":"/etc/systemd"}},{"name":"etc-kubernetes","hostPath":{"path":"/etc/kubernetes"}},{"name":"usr-bin","hostPath":{"path":"/usr/bin"}}],"containers":[{"name":"kube-bench","image":"aquasec/kube-bench:latest","command":["kube-bench","--benchmark","eks-1.0"],"volumeMounts":[{"name":"var-lib","mountPath":"/var/lib"},{"name":"var-lib-etcd","mountPath":"/var/lib/etcd"},{"name":"var-lib-kubelet","mountPath":"/var/lib/kubelet"},{"name":"var-lib-cni","mountPath":"/var/lib/cni"},{"name":"etc-systemd","mountPath":"/etc/systemd"},{"name":"etc-kubernetes","mountPath":"/etc/kubernetes"},{"name":"usr-bin","mountPath":"/usr/bin"}]}]}}' || true
    
    # Run Trivy on cluster
    echo -e "${YELLOW}Running Trivy cluster scan...${NC}"
    kubectl run --rm -i -t trivy --image=aquasec/trivy:latest --restart=Never -- trivy k8s cluster || true
    
    echo -e "${GREEN}✅ Security scans completed${NC}"
}

# Main deployment flow
main() {
    check_prerequisites
    bootstrap
    update_backend
    deploy_main
    deploy_k8s
    deploy_monitoring
    security_scan
    
    echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "1. Access Jenkins: https://jenkins.${DOMAIN_NAME}"
    echo -e "2. Access OpenSearch: https://core-services-infra-os.${DOMAIN_NAME}"
    echo -e "3. Note: Grafana is disabled (requires AWS SSO configuration)"
}

# Run main function
main "$@"

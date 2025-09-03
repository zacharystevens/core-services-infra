#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔒 Running security scans...${NC}"

# Check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}❌ kubectl is not installed. Please install kubectl${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

# Run kube-bench security scan
run_kube_bench() {
    echo -e "${YELLOW}Running kube-bench security scan...${NC}"
    
    # Create a simple kube-bench job
    cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: kube-bench
  namespace: default
spec:
  template:
    spec:
      hostPID: true
      containers:
      - name: kube-bench
        image: aquasec/kube-bench:latest
        command: ["kube-bench", "--benchmark", "eks-1.0"]
        volumeMounts:
        - name: var-lib
          mountPath: /var/lib
        - name: var-lib-etcd
          mountPath: /var/lib/etcd
        - name: var-lib-kubelet
          mountPath: /var/lib/kubelet
        - name: var-lib-cni
          mountPath: /var/lib/cni
        - name: etc-systemd
          mountPath: /etc/systemd
        - name: etc-kubernetes
          mountPath: /etc/kubernetes
        - name: usr-bin
          mountPath: /usr/bin
      volumes:
      - name: var-lib
        hostPath:
          path: /var/lib
      - name: var-lib-etcd
        hostPath:
          path: /var/lib/etcd
      - name: var-lib-kubelet
        hostPath:
          path: /var/lib/kubelet
      - name: var-lib-cni
        hostPath:
          path: /var/lib/cni
      - name: etc-systemd
        hostPath:
          path: /etc/systemd
      - name: etc-kubernetes
        hostPath:
          path: /etc/kubernetes
      - name: usr-bin
        hostPath:
          path: /usr/bin
      restartPolicy: Never
EOF

    # Wait for job to complete
    echo -e "${YELLOW}Waiting for kube-bench to complete...${NC}"
    kubectl wait --for=condition=complete job/kube-bench --timeout=600s
    
    # Get logs
    echo -e "${YELLOW}Kube-bench results:${NC}"
    kubectl logs job/kube-bench
    
    # Clean up
    kubectl delete job kube-bench
    
    echo -e "${GREEN}✅ Kube-bench scan completed${NC}"
}

# Run Trivy cluster scan
run_trivy_scan() {
    echo -e "${YELLOW}Running Trivy cluster scan...${NC}"
    
    # Create a simple Trivy job
    cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: trivy-cluster
  namespace: default
spec:
  template:
    spec:
      containers:
      - name: trivy
        image: aquasec/trivy:latest
        command: ["trivy", "k8s", "cluster"]
      restartPolicy: Never
EOF

    # Wait for job to complete
    echo -e "${YELLOW}Waiting for Trivy scan to complete...${NC}"
    kubectl wait --for=condition=complete job/trivy-cluster --timeout=600s
    
    # Get logs
    echo -e "${YELLOW}Trivy scan results:${NC}"
    kubectl logs job/trivy-cluster
    
    # Clean up
    kubectl delete job trivy-cluster
    
    echo -e "${GREEN}✅ Trivy scan completed${NC}"
}

# Main function
main() {
    check_kubectl
    run_kube_bench
    run_trivy_scan
    
    echo -e "${GREEN}🎉 Security scans completed successfully!${NC}"
    echo -e "${GREEN}🎉 All deployment phases completed!${NC}"
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "1. Access Jenkins: https://jenkins.taiyakicode.click"
    echo -e "2. Access OpenSearch: https://core-services-infra-os.taiyakicode.click"
    echo -e "3. Note: Grafana is disabled (requires AWS SSO configuration)"
}

# Run main function
main "$@"

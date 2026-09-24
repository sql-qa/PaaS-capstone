#!/bin/bash
set -euo pipefail

# Get the directory where the script is located
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "===== STARTING DEPLOYMENT ====="
date

echo "Checking Kubernetes cluster..."
kubectl get nodes

echo "Deploying Jenkins..."
# Use the absolute project root path
kubectl apply -f "$PROJECT_ROOT/k8s/jenkins/"

echo "Deploying NGINX..."
kubectl apply -f "$PROJECT_ROOT/k8s/nginx/"

echo "Waiting for Jenkins rollout..."

kubectl rollout status deployment/jenkins -n devops-tools --timeout=120s

echo "Verifying resources..."
kubectl get pods -n devops-tools

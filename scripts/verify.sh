#!/bin/bash
set -euo pipefail

echo "===== VERIFYING RESOURCES ====="
date

kubectl get pods -n devops-tools
kubectl get svc -n devops-tools
kubectl get ingress -n devops-tools

echo "Describing Jenkins deployment..."
kubectl describe deployment jenkins -n devops-tools | tail -20

echo "===== VERIFICATION COMPLETE ====="

#!/bin/bash
set -euo pipefail

echo "===== CLUSTER CHECK ====="
date
kubectl get nodes
kubectl get pods -A
echo "===== CLUSTER OK ====="

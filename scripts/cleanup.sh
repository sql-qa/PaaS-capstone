#!/bin/bash
set -euo pipefail

echo "===== CLEANUP STARTED ====="
date

kubectl delete -f k8s/nginx/ --ignore-not-found
kubectl delete -f k8s/jenkins/ --ignore-not-found

echo "===== CLEANUP COMPLETE ====="

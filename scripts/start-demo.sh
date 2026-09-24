#!/bin/bash
set -euo pipefail

# =========================
# CONFIG
# =========================
PROJECT_ROOT="$HOME/paas-project"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
LOCAL_K8S_DIR="$PROJECT_ROOT/k8s"
PROJECT_ID="paas-hybrid-project"
REGION="us-central1"
ZONE="us-central1-a"
GKE_CLUSTER="paas-gke-cluster"
LOCAL_NAMESPACE="devops-tools"
GKE_APP_NAME="nginx-test"

# =========================
# HELPERS
# =========================
log() {
  echo
  echo "=================================================="
  echo "$1"
  echo "=================================================="
}

wait_for_k8s() {
  local retries=30
  local delay=5

  for ((i=1; i<=retries; i++)); do
    if kubectl get nodes >/dev/null 2>&1; then
      echo "Kubernetes API is up."
      return 0
    fi
    echo "Waiting for Kubernetes API... attempt $i/$retries"
    sleep "$delay"
  done

  echo "ERROR: Kubernetes API did not come up in time."
  return 1
}

wait_for_gke_lb() {
  local namespace="${1:-default}"
  local svc_name="${2:-nginx-test}"
  local retries=36
  local delay=10

  for ((i=1; i<=retries; i++)); do
    LB_IP="$(kubectl get svc "$svc_name" -n "$namespace" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
    if [[ -n "${LB_IP:-}" ]]; then
      echo "$LB_IP"
      return 0
    fi
    echo "Waiting for external IP for service/$svc_name... attempt $i/$retries"
    sleep "$delay"
  done

  echo "ERROR: External IP not assigned in time."
  return 1
}

# =========================
# LOCAL CLUSTER
# =========================
log "1. Starting local Kubernetes services"

sudo systemctl restart containerd
sudo systemctl restart kubelet

wait_for_k8s

log "2. Verifying local cluster"
kubectl get nodes
kubectl get pods -A || true

log "3. Deploying local project manifests"
cd "$PROJECT_ROOT"

if [[ -d "$LOCAL_K8S_DIR/jenkins" ]]; then
  kubectl apply -f "$LOCAL_K8S_DIR/jenkins/" || true
fi

if [[ -d "$LOCAL_K8S_DIR/nginx" ]]; then
  kubectl apply -f "$LOCAL_K8S_DIR/nginx/" || true
fi

echo
echo "Local cluster resources:"
kubectl get pods -n "$LOCAL_NAMESPACE" || true
kubectl get svc -n "$LOCAL_NAMESPACE" || true
kubectl get ingress -n "$LOCAL_NAMESPACE" || true

# =========================
# GCP / TERRAFORM
# =========================
log "4. Checking gcloud auth"

gcloud config set project "$PROJECT_ID" >/dev/null
gcloud auth list
gcloud config list

log "5. Applying Terraform for GCP infrastructure"
cd "$TERRAFORM_DIR"
terraform init -input=false
terraform apply -auto-approve

echo
echo "Terraform outputs:"
terraform output || true

# =========================
# GKE
# =========================
log "6. Connecting kubectl to GKE"

gcloud container clusters get-credentials "$GKE_CLUSTER" \
  --region "$REGION" \
  --project "$PROJECT_ID"

log "7. Verifying GKE cluster"
kubectl get nodes

log "8. Deploying demo app to GKE"

if kubectl get deployment "$GKE_APP_NAME" >/dev/null 2>&1; then
  kubectl set image deployment/"$GKE_APP_NAME" nginx=nginx
else
  kubectl create deployment "$GKE_APP_NAME" --image=nginx
fi

kubectl scale deployment "$GKE_APP_NAME" --replicas=3

if kubectl get svc "$GKE_APP_NAME" >/dev/null 2>&1; then
  echo "Service $GKE_APP_NAME already exists."
else
  kubectl expose deployment "$GKE_APP_NAME" --type=LoadBalancer --port=80
fi

kubectl rollout status deployment/"$GKE_APP_NAME" --timeout=180s
kubectl get pods
kubectl get svc

log "9. Waiting for GKE external IP"
GKE_LB_IP="$(wait_for_gke_lb default "$GKE_APP_NAME")"

# =========================
# FINAL OUTPUT
# =========================
log "10. Demo summary"

echo "LOCAL CLUSTER:"
echo "- Nodes:"
kubectl config current-context || true
kubectl get nodes || true

echo
echo "LOCAL JENKINS / NGINX:"
echo "- Jenkins ingress host: http://jenkins.10.1.1.100.nip.io:31207"
echo "- Local namespace: $LOCAL_NAMESPACE"

echo
echo "GKE CLUSTER:"
kubectl get nodes
echo "- GKE app URL: http://$GKE_LB_IP"

echo
echo "Demo startup complete."

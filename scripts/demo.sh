#!/bin/bash
set -euo pipefail

kubectl config use-context kubernetes-admin@kubernetes

sudo systemctl restart containerd
sudo systemctl restart kubelet
sleep 10

kubectl get nodes

kubectl delete deployment nginx-test --ignore-not-found
kubectl delete service nginx-test --ignore-not-found

kubectl create deployment nginx-test --image=nginx
kubectl expose deployment nginx-test --type=NodePort --port=80

sleep 5

kubectl scale deployment nginx-test --replicas=3

sleep 5

kubectl get pods
kubectl get svc

PORT=$(kubectl get svc nginx-test -o jsonpath='{.spec.ports[0].nodePort}')
echo http://10.1.1.100:$PORT
